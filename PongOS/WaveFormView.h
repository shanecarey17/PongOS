//
//  WaveFormView.h
//  PongOS
//
//  Created by Shane Carey on 7/3/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WaveFormView : UIView

- (void)drawSamples:(float *)samples length:(int)length;

@end
