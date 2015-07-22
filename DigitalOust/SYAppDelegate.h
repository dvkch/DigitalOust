//
//  SYAppDelegate.h
//  DigitalOust
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SYAppDelegate : NSObject <NSApplicationDelegate>

+ (instancetype)obtain;

@property (atomic, copy) void(^windowFocusChanged)(void);

@end

