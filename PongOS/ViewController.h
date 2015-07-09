//
//  ViewController.h
//  PongOS
//
//  Created by Shane Carey on 6/27/15.
//  Copyright © 2015 Shane Carey. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Listener.h"
#import "SpectrumView.h"
#import "WaveFormView.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet SpectrumView *spectrumView;

@property (weak, nonatomic) IBOutlet WaveFormView *waveFormView;

@property (weak, nonatomic) IBOutlet UILabel *rallyLabel;

@property (strong, nonatomic) Listener *listener;

@end

