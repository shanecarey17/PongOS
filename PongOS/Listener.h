//
//  Listener.h
//  PongOS
//
//  Created by Shane Carey on 6/27/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <Accelerate/Accelerate.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@protocol ListenerDelegate <NSObject>

- (void)didRecieveFrequencyArray:(float *)freqArray length:(int)length;

- (void)didRecieveRawSamples:(float *)samples length:(int)frames;

- (void)didHypothesizeTableHit;

@end


@interface Listener : NSObject

@property AudioComponentInstance ioAudioUnit;

@property (weak, nonatomic) id<ListenerDelegate> delegate;

@property float threshold;

- (void)processAudio:(AudioBufferList *)buffer frames:(UInt32)numFrames;

@end
