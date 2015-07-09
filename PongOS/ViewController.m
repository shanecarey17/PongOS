//
//  ViewController.m
//  PongOS
//
//  Created by Shane Carey on 6/27/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ListenerDelegate>

@property NSInteger count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _listener = [[Listener alloc] init];
    _listener.delegate = self;
    
    [_rallyLabel setText:[NSString stringWithFormat:@"%ld", _count]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRecieveFrequencyArray:(float *)freqArray length:(int)length {
    [self.spectrumView updateFreqArray:freqArray count:length];
}

- (void)didRecieveRawSamples:(float *)samples length:(int)frames {
    [self.waveFormView drawSamples:samples length:frames];
}

- (void)didHypothesizeTableHit {
    _count++;
    [self.rallyLabel setText:[NSString stringWithFormat:@"%ld", _count]];
}

@end
