//
//  SYStepView.h
//  DigitalOust
//
//  Created by Stan Chevallier on 28/06/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SYStep;

@interface SYStepView : NSView

@property (nonatomic, assign) BOOL      buttonEnabled;
@property (nonatomic, strong) SYStep    *step;

- (void)startUpdate;
- (void)stopUpdate;

@end
