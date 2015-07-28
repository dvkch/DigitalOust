//
//  NSWindow+Tools.m
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "NSAlert+DigitalOust.h"
#import "NSAlert+Popover.h"
#import "SYReboot.h"

@implementation NSAlert (DigitalOust)

+ (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
               onWindowOrView:(id)windowOrView
{
    [self displayAlertWithTitle:title informativeText:informativeText onWindowOrView:windowOrView block:nil];
}

+ (void)displayAlertWithTitle:(NSString *)title
                 askForReboot:(BOOL)reboot
               onWindowOrView:(id)windowOrView
{
    return [self displayAlertWithTitle:title
                       informativeText:@"You need to reboot your computer for changes to take effect"
                               button0:@"Restart now"
                               button1:@"Later"
                        onWindowOrView:windowOrView block:^(NSUInteger tappedIndex) {
                                  if (tappedIndex == 0)
                                      [SYReboot askForRebootNow];
                              }];
}

+ (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
               onWindowOrView:(id)windowOrView
                        block:(void(^)(NSUInteger tappedIndex))block
{
    [self displayAlertWithTitle:title informativeText:informativeText
                        button0:nil button1:nil
                 onWindowOrView:windowOrView block:block];
}

+ (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
                      button0:(NSString *)button0
                      button1:(NSString *)button1
               onWindowOrView:(id)windowOrView
                        block:(void(^)(NSUInteger tappedIndex))block;
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert addButtonWithTitle:(button0 ?: @"Close")];
    if(button1)
        [alert addButtonWithTitle:button1];
    [alert setInformativeText:informativeText ?: @""];
    
    if ([windowOrView isKindOfClass:[NSWindow class]])
    {
        [alert beginSheetModalForWindow:windowOrView completionHandler:^(NSModalResponse returnCode)
         {
             if(block) block(labs(returnCode) == labs(NSModalResponseAbort));
         }];
    }
    if ([windowOrView isKindOfClass:[NSView class]])
    {
        [alert runAsPopoverForView:windowOrView withCompletionBlock:^(NSInteger result) {
            if(block) block(result);
        }];
    }
}

@end

