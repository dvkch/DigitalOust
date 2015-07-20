//
//  SYTrafficView.h
//  DigitalOust
//
//  Created by Stan Chevallier on 20/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    SYTrafficButtonClose    = 1 << 0,
    SYTrafficButtonMinimize = 1 << 1,
    SYTrafficButtonZoom     = 1 << 2,
} SYTrafficButton;

@interface SYTrafficView : NSView

- (void)setEnabledButtons:(SYTrafficButton)buttons;

@end
