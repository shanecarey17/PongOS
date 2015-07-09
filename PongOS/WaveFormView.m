//
//  WaveFormView.m
//  PongOS
//
//  Created by Shane Carey on 7/3/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import "WaveFormView.h"

@interface WaveFormView ()

@property float *samples;

@property int length;

@end

@implementation WaveFormView

- (void)drawRect:(CGRect)rect {
    // Get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
    
    if (_samples) {
        // Loop over samples and draw for each absolute magnitude
        int samplesPerPixel = _length / rect.size.width;
        for (int i = 0; i < rect.size.width; i++) {
            
            // Average audio buffer
            float avg = 0;
            for (int j = 0; j < samplesPerPixel; j++) {
                avg += _samples[i * samplesPerPixel + j];
            }
            avg = avg / samplesPerPixel;
            
            // Stroke
            CGContextMoveToPoint(context, i, rect.size.height / 2);
            CGContextAddLineToPoint(context, i, (avg * rect.size.height / 2) + (rect.size.height / 2));
            CGContextStrokePath(context);
        }
        
        free(_samples);
    }
}

- (void)drawSamples:(float *)samples length:(int)length {
    _samples = samples;
    _length = length;
    [self setNeedsDisplay];
}

@end
