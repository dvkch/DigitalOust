//
//  SYStepRestore0.m
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepRestore0.h"
#import "SYNVRAMHelper.h"
#import "SYComms.h"
#import "NSAlert+DigitalOust.h"
#import "NSError+DigitalOust.h"

@implementation SYStepRestore0

- (NSString *)statusString
{
    switch ([SYNVRAMHelper rootlessStatus]) {
        case SYNVRAMBootArgStatusNotRequired:   return @"hide";
        case SYNVRAMBootArgStatusOFF:           return @"ok";
        case SYNVRAMBootArgStatusON:            return @"disable";
    }
    return nil;
}

- (NSString *)titleText
{
    if ([[self statusString] isEqualToString:@"ok"])
        return @"Boot configuration: everything is good!";
    if ([[self statusString] isEqualToString:@"disable"])
        return @"Boot configuration: rootless needs to be disabled";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self statusString] isEqualToString:@"disable"])   return @"Disable";
    return nil;
}

- (NSString *)descrText
{
#warning texts
    if ([[self statusString] isEqualToString:@"disable"])
        return @"Rootless mode has been added in OSX 10.11 El Capitan to prevent modifications of system files. To restore AppleHDA you need to disable it. You may re-enable it later.";
    return nil;
}

- (SYStepImage)image
{
    if ([[self statusString] isEqualToString:@"disable"])   return SYStepImageNotOK;
    if ([[self statusString] isEqualToString:@"ok"])        return SYStepImageOK;
    return SYStepImageNotOK;
}

- (BOOL)show
{
    return ![[self statusString] isEqualToString:@"hide"];
}

- (void)buttonTap:(NSView *)sender
{
    SYCommsCompletionBlock block = ^(NSError *error) {
        if (error)
            [NSAlert displayAlertWithTitle:@"Error while updating boot configuration"
                           informativeText:[error localizedDescriptionSY]
                            onWindowOrView:sender.window];
        else
            [NSAlert displayAlertWithTitle:@"Boot configuration updated with success"
                              askForReboot:YES
                            onWindowOrView:sender.window];
    };
    
    if ([[self statusString] isEqualToString:@"disable"])
        [[SYComms shared] sendCommand:SYCommsCommandDisableRootless args:nil completion:block];
}

@end
