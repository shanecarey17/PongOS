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
    _listener.threshold = 100;
    
    // UI changes based on observation of count
    [self addObserver:self forKeyPath:@"count" options:0 context:nil];
    
    // Reset rally counter with tap of the screen
    UIGestureRecognizer *tapToReset = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetRallyCounter)];
    [self.rallyLabel addGestureRecognizer:tapToReset];
}

- (void)didRecieveFrequencyArray:(float *)freqArray length:(int)length {
    [self.spectrumView updateFreqArray:freqArray count:length];
}

- (void)didRecieveRawSamples:(float *)samples length:(int)frames {
    [self.waveFormView drawSamples:samples length:frames];
}

- (IBAction)threholdSliderValueChanged:(UISlider *)sender {
    // Set listener threshold
    _listener.threshold = sender.value;
    
    // Show value on slider
    self.thresholdLabel.text = [NSString stringWithFormat:@"%d", (int)sender.value];
}

- (void)didHypothesizeTableHit {
    self.count++;
}
     
- (void)resetRallyCounter {
    self.count = 0;
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary *)change context:(nullable void *)context {
    if ([keyPath isEqualToString:@"count"]) {
        [self.rallyLabel setText:[NSString stringWithFormat:@"%ld", _count]];
    }
}

@end
