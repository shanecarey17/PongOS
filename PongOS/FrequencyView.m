//
//  FrequencyView.m
//  PongOS
//
//  Created by Shane Carey on 6/30/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import "FrequencyView.h"

@interface FrequencyView ()

@property float *freqArray;

@property int bins;

@end

@implementation FrequencyView

- (void)drawRect:(CGRect)rect {
    // Get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set bounds
    float minFreq = 20;
    float maxFreq = 44100.0 / 2;
    
    // Freq array will be null at launch
    if (_freqArray) {
        // Draw the frequencies
        CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
        CGContextSetLineDash(context, 0.0f, NULL, 0);
        
        // Skip the DC Offset (index 0)
        for (int i = 1; i < _bins; i++) {
            // Check for -inf
            if (isinf(_freqArray[i])) {
                continue;
            }
            
            // Get frequency from bin
            float binFreq = i * 44100.0 / (_bins * 2);
            
            // Map to rect coordinate space
            float x = (log10f(binFreq) - log10f(minFreq)) * rect.size.width / (log10f(maxFreq) - log10f(minFreq));
            float y = _freqArray[i] * rect.size.height / -96.0;
            
            // Draw line
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, x, rect.size.height);
            CGContextAddLineToPoint(context, x, y);
            CGContextStrokePath(context);
        }
        
        // free the array
        free(_freqArray);
    }
}

- (void)updateFreqArray:(float *)freqArray count:(int)bins {
    _freqArray = freqArray;
    _bins = bins;
    [self setNeedsDisplay];
}

@end
