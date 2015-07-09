//
//  SpectrumView.h
//  PongOS
//
//  Created by Shane Carey on 6/28/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FrequencyView;

@interface SpectrumView : UIView

@property (weak, nonatomic) IBOutlet FrequencyView *frequencyView;

- (void)updateFreqArray:(float *)freqArray count:(int)bins;

@end
