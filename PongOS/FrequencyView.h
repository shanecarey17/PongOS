//
//  FrequencyView.h
//  PongOS
//
//  Created by Shane Carey on 6/30/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FrequencyView : UIView

- (void)updateFreqArray:(float *)freqArray count:(int)bins;

@end
