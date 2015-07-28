//
//  NSWindow+Tools.h
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAlert (DigitalOust)

+ (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
               onWindowOrView:(id)windowOrView;

+ (void)displayAlertWithTitle:(NSString *)title
                 askForReboot:(BOOL)reboot
               onWindowOrView:(id)windowOrView;

+ (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
               onWindowOrView:(id)windowOrView
                        block:(void(^)(NSUInteger tappedIndex))block;

+ (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
                      button0:(NSString *)button0
                      button1:(NSString *)button1
               onWindowOrView:(id)windowOrView
                        block:(void(^)(NSUInteger tappedIndex))block;

@end
