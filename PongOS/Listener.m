//
//  Listener.m
//  PongOS
//
//  Created by Shane Carey on 6/27/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#define SAMPLE_RATE 44100.0
#define MAX_FRAMES 4096
#define INPUT_BUS 1

#import "Listener.h"

static OSStatus recordingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    
    // Reference to the listener
    Listener *listener = (__bridge Listener *)inRefCon;
    
    // Audio buffer list
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    
    // Render into buffer list
    AudioUnitRender([listener ioAudioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    
    // Process audio within listener class
    [listener processAudio:&bufferList frames:inNumberFrames];

    return noErr;
}

@interface Listener ()

// FFT
@property FFTSetup fftSetup;
@property COMPLEX_SPLIT A;
@property float *hammingWindow;

// Matched filter
@property AudioBufferList *tableFilterBufferList;
@property SInt64 tableFrames;
@property AudioBufferList *paddleFilterBufferList;
@property SInt64 paddleFrames;
@property UInt32 bufferListIndex; // current index in bufferList

@end

@implementation Listener

- (instancetype)init {
    self = [super init];
    if (self) {
        // FFT
        _fftSetup = vDSP_create_fftsetup(log2(MAX_FRAMES), FFT_RADIX2);
        _A.realp = malloc(MAX_FRAMES / 2 * sizeof(float));
        _A.imagp = malloc(MAX_FRAMES / 2 * sizeof(float));
        _hammingWindow = malloc(MAX_FRAMES * sizeof(float));
        
        // Initialize audio session and set hardware buffer size
        [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:0.088 error:nil];
        
        // Filter
        [self setUpMatchedFilters];
        
        // Audio
        [self setupAudio];
    }
    return self;
}

- (void)setUpMatchedFilters {
    
    // Get URLS for samples
    NSURL *tableURL = [[NSBundle mainBundle] URLForResource:@"table_hit" withExtension:@"aif"];
    NSURL *paddleURL = [[NSBundle mainBundle] URLForResource:@"paddle_hit" withExtension:@"aif"];
    
    // Get ext audio files
    OSStatus error;
    ExtAudioFileRef tableAudioFileRef;
    error = ExtAudioFileOpenURL((__bridge CFURLRef)tableURL, &tableAudioFileRef);
    ExtAudioFileRef paddleAudioFileRef;
    error = ExtAudioFileOpenURL((__bridge CFURLRef)paddleURL, &paddleAudioFileRef);
    
    // float stream description
    AudioStreamBasicDescription readFormat;
    readFormat.mSampleRate			= 44100.0;
    readFormat.mFormatID			= kAudioFormatLinearPCM;
    readFormat.mFormatFlags         = kAudioFormatFlagsNativeFloatPacked;
    readFormat.mFramesPerPacket     = 1;
    readFormat.mChannelsPerFrame	= 1;
    readFormat.mBitsPerChannel		= sizeof(float) * 8;
    readFormat.mBytesPerPacket		= sizeof(float);
    readFormat.mBytesPerFrame		= sizeof(float);
    
    // Set format
    error = ExtAudioFileSetProperty(tableAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &readFormat);
    error = ExtAudioFileSetProperty(paddleAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &readFormat);
    
    // Number of frames to read
    UInt32 tableNumFramesSize = sizeof(SInt64);
    UInt32 paddleNumFramesSize = sizeof(SInt64);
    error = ExtAudioFileGetProperty(tableAudioFileRef, kExtAudioFileProperty_FileLengthFrames, &tableNumFramesSize, &_tableFrames);
    error = ExtAudioFileGetProperty(paddleAudioFileRef, kExtAudioFileProperty_FileLengthFrames, &paddleNumFramesSize, &_paddleFrames);
    
    // Setup audio buffers
    _tableFilterBufferList = malloc(sizeof(AudioBufferList));
    _tableFilterBufferList->mNumberBuffers = 1;
    _tableFilterBufferList->mBuffers[0].mNumberChannels = 1;
    _tableFilterBufferList->mBuffers[0].mDataByteSize = sizeof(float) * (UInt32)_tableFrames;
    _tableFilterBufferList->mBuffers[0].mData = malloc(sizeof(float) * _tableFrames);
    
    _paddleFilterBufferList = malloc(sizeof(AudioBufferList));
    _paddleFilterBufferList->mNumberBuffers = 1;
    _paddleFilterBufferList->mBuffers[0].mNumberChannels = 1;
    _paddleFilterBufferList->mBuffers[0].mDataByteSize = sizeof(float) * (UInt32)_paddleFrames;
    _paddleFilterBufferList->mBuffers[0].mData = malloc(sizeof(float) * _paddleFrames);
    
    // Read into buffers
    _tableFrames = 500;
    error = ExtAudioFileRead(tableAudioFileRef, (UInt32 *)&_tableFrames, _tableFilterBufferList);
    error = ExtAudioFileRead(paddleAudioFileRef, (UInt32 *)&_paddleFrames, _paddleFilterBufferList);

}

- (void)setupAudio {
    
    // Create io audio unit description
    AudioComponentDescription ioDescription;
    ioDescription.componentType = kAudioUnitType_Output;
    ioDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioDescription.componentFlags = 0;
    ioDescription.componentFlagsMask = 0;
    
    // Find the installed audio unit with description
    AudioComponent audioComponent = AudioComponentFindNext(nil, &ioDescription);
    
    // Create instance of the audio component
    AudioComponentInstanceNew(audioComponent, &_ioAudioUnit);
    
    // Record on input bus (1)
    UInt32 enable = 1;
    AudioUnitSetProperty(_ioAudioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, INPUT_BUS, &enable, sizeof(UInt32));
    
    // Audio stream basic description for recieving input
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= 44100.0;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagsNativeFloatPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= sizeof(float) * 8;
    audioFormat.mBytesPerPacket		= sizeof(float);
    audioFormat.mBytesPerFrame		= sizeof(float);
    
    // Set audio format on output scope of input from mic
    AudioUnitSetProperty(_ioAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, INPUT_BUS, &audioFormat, sizeof(AudioStreamBasicDescription));
    
    // Set maximum frames per slice (in case over 4096)
    UInt32 maxFrames = MAX_FRAMES;
    AudioUnitSetProperty(_ioAudioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Output, INPUT_BUS, &maxFrames, sizeof(UInt32));
    
    // Input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void*)self;
    
    // Set input callback property
    AudioUnitSetProperty(_ioAudioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, INPUT_BUS, &callbackStruct, sizeof(AURenderCallbackStruct));
    
    // Initialize audio unit
    AudioUnitInitialize(_ioAudioUnit);
    AudioOutputUnitStart(_ioAudioUnit);
}

- (void)processAudio:(AudioBufferList *)bufferList frames:(UInt32)numFrames {
    
    // Send buffer to delegate for waveform processing
    float *waveFormSamples = malloc(sizeof(float) * numFrames);
    memcpy(waveFormSamples, bufferList->mBuffers[0].mData, sizeof(float) * numFrames);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didRecieveRawSamples:waveFormSamples length:numFrames];
    });
    
    // Perform match filtering
    [self performMatchedFilter:bufferList->mBuffers[0].mData frames:numFrames];
    
    // Perform FFT
    //[self performFFT:bufferList->mBuffers[0].mData frames:numFrames];
}

- (void)performMatchedFilter:(float *)audioBuffer frames:(UInt32)numFrames {
    
    // Determine a threshold for recognition
    _threshold = 7;
    
    // Reference the sample buffers
    float *tableBuffer = _tableFilterBufferList->mBuffers[0].mData;
    
    // Convolute signal vector with filter
    float *convSig = malloc(sizeof(float) * (numFrames - _tableFrames));
    vDSP_conv(audioBuffer, 1, tableBuffer, 1, convSig, 1, numFrames - _tableFrames, _tableFrames);
    float convPeak;
    vDSP_maxv(convSig, 1, &convPeak, numFrames - _tableFrames);
    free(convSig);
    
    NSLog(@"%f", convPeak);

    // Inform user
    if (convPeak > _threshold) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didHypothesizeTableHit];
        });
    }
}

- (void)performFFT:(float *)floatBuffer frames:(UInt32)numFrames {
    // Reset window (becomes obscured)
    vDSP_hann_window(_hammingWindow, numFrames, 0);
    
    // Window samples
    vDSP_vmul(floatBuffer, 1, _hammingWindow, 1, floatBuffer, 1, numFrames);
    
    // Store split complex
    vDSP_ctoz((COMPLEX *)floatBuffer, 2, &_A, 1, numFrames / 2);
    
    // FFT
    vDSP_fft_zrip(_fftSetup, &_A, 1, log2(numFrames), FFT_FORWARD);
    
    // Scale result
    float scale = 1 / (numFrames * 2.0);
    vDSP_vsmul(_A.realp, 1, &scale, _A.realp, 1, numFrames / 2);
    vDSP_vsmul(_A.imagp, 1, &scale, _A.imagp, 1, numFrames / 2);
    
    // Unpack
    float *rawFreqs = malloc(sizeof(float) * numFrames / 2);
    
    // Squared vector magitudes
    vDSP_zvmags(&_A, 1, rawFreqs, 1, numFrames / 2);
    
    // Convert power to decibels
    float one = 1;
    vDSP_vdbcon(rawFreqs, 1, &one, rawFreqs, 1, numFrames / 2, 0);
    
    // Send to delegate
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didRecieveFrequencyArray:rawFreqs length:numFrames / 2];
    });
}

@end