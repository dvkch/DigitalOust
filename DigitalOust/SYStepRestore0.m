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
#import "NSWindow+Tools.h"
#import "NSError+DigitalOust.h"

@implementation SYStepRestore0

- (NSString *)state
{
    if ([SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired)
        return @"hide";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusON)
        return @"ok kext";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusON)
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
    if ([[self state] isEqualToString:@"ok kext"])
        return @"Boot configuration: everything is good!";
    if ([[self state] isEqualToString:@"ok both"])
        return @"Boot configuration: everything is good!";
    if ([[self state] isEqualToString:@"need kextdevmode"])
        return @"Boot configuration: kext-dev-mode needs to be enabled";
    if ([[self state] isEqualToString:@"need rootless"])
        return @"Boot configuration: rootless needs to be disabled";
    if ([[self state] isEqualToString:@"need both"])
        return @"Boot configuration: kext-dev-mode needs to be enabled and rootless disabled";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self state] isEqualToString:@"need kextdevmode"]) return @"Enable";
    if ([[self state] isEqualToString:@"need rootless"])    return @"Disable";
    if ([[self state] isEqualToString:@"need both"])        return @"Apply";
    return nil;
}

- (NSString *)descrText
{
#warning texts
    if ([[self state] isEqualToString:@"ok kext"])
        return @"";
    if ([[self state] isEqualToString:@"ok both"])
        return @"";
    if ([[self state] isEqualToString:@"need kextdevmode"])
        return @"";
    if ([[self state] isEqualToString:@"need rootless"])
        return @"";
    if ([[self state] isEqualToString:@"need both"])
        return @"";
    return nil;
}

- (SYStepImage)image
{
    if ([[self state] isEqualToString:@"ok kext"])          return SYStepImageOK;
    if ([[self state] isEqualToString:@"ok both"])          return SYStepImageOK;
    if ([[self state] isEqualToString:@"need kextdevmode"]) return SYStepImageNotOK;
    if ([[self state] isEqualToString:@"need rootless"])    return SYStepImageNotOK;
    if ([[self state] isEqualToString:@"need both"])        return SYStepImageNotOK;
    return SYStepImageNotOK;
}

- (BOOL)show
{
    return ![[self state] isEqualToString:@"hide"];
}

- (void)buttonTap:(NSWindow *)window
{
    BOOL needsReboot = [SYNVRAMHelper rootlessStatus] == SYNVRAMBootArgStatusON;
    
    SYCommsCompletionBlock block = ^(NSError *error) {
        if (error)
            [window displayAlertWithTitle:@"Error while updating boot configuration"
                          informativeText:[error localizedDescriptionSY]];
        else
            [window displayAlertWithTitle:@"Boot configuration updated with success"
                             askForReboot:needsReboot];
    };
    
    if ([[self state] isEqualToString:@"need kextdevmode"])
        [[SYComms shared] sendCommand:SYCommsCommandEnableKextDevMode args:nil completion:block];
    if ([[self state] isEqualToString:@"need rootless"])
        [[SYComms shared] sendCommand:SYCommsCommandDisableRootless   args:nil completion:block];
    if ([[self state] isEqualToString:@"need both"])
        [[SYComms shared] sendCommand:SYCommsCommandEnableKextDevModeAndDisableRootless args:nil completion:block];
}

@end
