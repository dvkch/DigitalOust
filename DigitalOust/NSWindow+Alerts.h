//
//  NSWindow+Alerts.h
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow (Alerts)

- (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText;

- (void)displayAlertWithTitle:(NSString *)title
                 askForReboot:(BOOL)reboot;

- (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
                        block:(void(^)(NSUInteger tappedIndex))block;

- (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
                      button0:(NSString *)button0
                      button1:(NSString *)button1
                        block:(void(^)(NSUInteger tappedIndex))block;

@end
