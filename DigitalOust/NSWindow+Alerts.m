//
//  NSWindow+Alerts.m
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "NSWindow+Alerts.h"
#import "SYReboot.h"

@implementation NSWindow (Alerts)

- (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
{
    [self displayAlertWithTitle:title informativeText:informativeText button0:nil button1:nil block:nil];
}

- (void)displayAlertWithTitle:(NSString *)title
                 askForReboot:(BOOL)reboot
{
    [self displayAlertWithTitle:title
                informativeText:@"You need to reboot your computer for changes to take effect"
                        button0:@"Restart now"
                        button1:@"Later"
                          block:^(NSUInteger tappedIndex)
     {
         [SYReboot askForRebootNow];
     }];
}

- (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
                        block:(void (^)(NSUInteger))block
{
    [self displayAlertWithTitle:title informativeText:informativeText button0:nil button1:nil block:block];
}

- (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
                      button0:(NSString *)button0
                      button1:(NSString *)button1
                        block:(void(^)(NSUInteger tappedIndex))block
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert addButtonWithTitle:(button0 ?: @"Close")];
    if(button1)
        [alert addButtonWithTitle:button1];
    [alert setInformativeText:informativeText ?: @""];
    [alert beginSheetModalForWindow:self completionHandler:^(NSModalResponse returnCode) {
        if(block)
            block(labs(returnCode) == labs(NSModalResponseAbort));
    }];
}

@end
