//
//  SYStepPatch1.m
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepPatch1.h"
#import "SYNVRAMHelper.h"
#import "SYComms.h"
#import "NSAlert+DigitalOust.h"
#import "NSError+DigitalOust.h"

@implementation SYStepPatch1

- (NSString *)statusString
{
    // both not required
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusNotRequired)
        return @"hide";
    
    // rootless not required
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusON)
        return @"ok kext";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusOFF)
        return @"need kextdevmode";
    
    // both required
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusOFF &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusON)
        return @"ok both";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusOFF &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusOFF)
        return @"need kextdevmode";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusON &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusON)
        return @"need rootless";
    
    return @"need both";
}

- (NSString *)titleText
{
    if ([[self statusString] isEqualToString:@"ok kext"])
        return @"Boot configuration: everything is good!";
    if ([[self statusString] isEqualToString:@"ok both"])
        return @"Boot configuration: everything is good!";
    if ([[self statusString] isEqualToString:@"need kextdevmode"])
        return @"Boot configuration: kext-dev-mode needs to be enabled";
    if ([[self statusString] isEqualToString:@"need rootless"])
        return @"Boot configuration: rootless needs to be disabled";
    if ([[self statusString] isEqualToString:@"need both"])
        return @"Boot configuration: kext-dev-mode needs to be enabled and rootless disabled";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self statusString] isEqualToString:@"need kextdevmode"]) return @"Enable";
    if ([[self statusString] isEqualToString:@"need rootless"])    return @"Disable";
    if ([[self statusString] isEqualToString:@"need both"])        return @"Apply";
    return nil;
}

- (NSString *)descrText
{
#warning texts
    if ([[self statusString] isEqualToString:@"ok kext"])
        return @"";
    if ([[self statusString] isEqualToString:@"ok both"])
        return @"";
    if ([[self statusString] isEqualToString:@"need kextdevmode"])
        return @"";
    if ([[self statusString] isEqualToString:@"need rootless"])
        return @"";
    if ([[self statusString] isEqualToString:@"need both"])
        return @"";
    return nil;
}

- (SYStepImage)image
{
    if ([[self statusString] isEqualToString:@"ok kext"])          return SYStepImageOK;
    if ([[self statusString] isEqualToString:@"ok both"])          return SYStepImageOK;
    if ([[self statusString] isEqualToString:@"need kextdevmode"]) return SYStepImageNotOK;
    if ([[self statusString] isEqualToString:@"need rootless"])    return SYStepImageNotOK;
    if ([[self statusString] isEqualToString:@"need both"])        return SYStepImageNotOK;
    return SYStepImageNotOK;
}

- (BOOL)show
{
    return ![[self statusString] isEqualToString:@"hide"];
}

- (void)buttonTap:(NSView *)sender
{
    BOOL needsReboot = [SYNVRAMHelper rootlessStatus] == SYNVRAMBootArgStatusON;
    
    SYCommsCompletionBlock block = ^(NSError *error) {
        if (error)
            [NSAlert displayAlertWithTitle:@"Error while updating boot configuration"
                           informativeText:[error localizedDescriptionSY]
                            onWindowOrView:sender.window];
        else
            [NSAlert displayAlertWithTitle:@"Boot configuration updated with success"
                              askForReboot:needsReboot
                            onWindowOrView:sender.window];
    };
    
    if ([[self statusString] isEqualToString:@"need kextdevmode"])
        [[SYComms shared] sendCommand:SYCommsCommandEnableKextDevMode args:nil completion:block];
    if ([[self statusString] isEqualToString:@"need rootless"])
        [[SYComms shared] sendCommand:SYCommsCommandDisableRootless   args:nil completion:block];
    if ([[self statusString] isEqualToString:@"need both"])
        [[SYComms shared] sendCommand:SYCommsCommandEnableKextDevModeAndDisableRootless args:nil completion:block];
}

@end
