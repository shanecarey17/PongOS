//
//  SpectrumView.m
//  PongOS
//
//  Created by Shane Carey on 6/28/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import "SpectrumView.h"
#import "FrequencyView.h"

@implementation SpectrumView

- (void)drawRect:(CGRect)rect {
    
    // Begin drawing
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.5);
    
    // Define bounds
    float minFreq = 20;
    float maxFreq = 44100.0 / 2;
    float mindB = -96;
    float maxdB = 0;
    
    // Draw grid
    CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
    CGFloat length = 1.0;
    CGContextSetLineDash(context, 0.0f, &length, 1);
    
    // Draw dB lines
    float numdBLines = (maxdB - mindB) / 6;
    for (int i = 0; i < numdBLines; i++) {
        // Calculate y
        float y = i * rect.size.height / numdBLines;
        
        //Stroke path
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, rect.size.width, y);
        CGContextStrokePath(context);
    }
    
    // Draw frequency lines
    for (int i = 1; i < 5; i++) {
        // Solid line
        CGContextSetLineDash(context, 0.0f, NULL, 0);

        // Get the base
        float base = pow(10, i);
        
        // Draw solid baseline
        float baseX = (log10f(base) - log10f(minFreq)) * rect.size.width / (log10f(maxFreq) - log10f(minFreq));
        CGContextMoveToPoint(context, baseX, 0);
        CGContextAddLineToPoint(context, baseX, rect.size.height);
        CGContextStrokePath(context);
        
        // Draw dashed lines between bases (2K, 3K, ..., 9K)
        CGContextSetLineDash(context, 0.0f, &length, 1);
        for (int i = 2; i < 10; i++) {
            float div = i * base;
            float x = (log10f(div) - log10f(minFreq)) * rect.size.width / (log10f(maxFreq) - log10f(minFreq));
            CGContextMoveToPoint(context, x, 0);
            CGContextAddLineToPoint(context, x, rect.size.height);
            CGContextStrokePath(context);
        }
    }
}

- (void)updateFreqArray:(float *)freqArray count:(int)bins {
    [self.frequencyView updateFreqArray:freqArray count:bins];
}

@end
