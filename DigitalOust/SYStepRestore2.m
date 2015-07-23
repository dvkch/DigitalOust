//
//  SYStepRestore2.m
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepRestore2.h"
#import "SYNVRAMHelper.h"
#import "SYComms.h"
#import "NSWindow+Tools.h"
#import "NSError+DigitalOust.h"

@implementation SYStepRestore2

- (NSString *)state
{
    switch ([SYNVRAMHelper rootlessStatus]) {
        case SYNVRAMBootArgStatusNotRequired:   return @"hide";
        case SYNVRAMBootArgStatusOFF:           return @"enable";
        case SYNVRAMBootArgStatusON:            return @"ok";
    }
    return nil;
}

- (NSString *)titleText
{
    if ([[self state] isEqualToString:@"ok"])
        return @"Boot configuration: everything is good!";
    if ([[self state] isEqualToString:@"enable"])
        return @"Boot configuration: rootless can be re-enabled";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self state] isEqualToString:@"enable"])
        return @"Disable";
    return nil;
}

- (NSString *)descrText
{
    if ([[self state] isEqualToString:@"enable"])
        return @"Rootless mode has been disabled to apply this patch, and can be re-enabled. This step is optional as you may want to keep rootless mode disabled for other reasons";
    return nil;
}

- (SYStepImage)image
{
    if ([[self state] isEqualToString:@"enable"])  return SYStepImageNotOKOptional;
    return SYStepImageOK;
}

- (BOOL)show
{
    return ![[self state] isEqualToString:@"hide"];
}

- (void)buttonTap:(NSWindow *)window
{
    BOOL needsReboot = [SYNVRAMHelper rootlessStatus] == SYNVRAMBootArgStatusOFF;
    
    SYCommsCompletionBlock block = ^(NSError *error) {
        if (error)
            [window displayAlertWithTitle:@"Error while updating boot configuration"
                          informativeText:[error localizedDescriptionSY]];
        else
            [window displayAlertWithTitle:@"Boot configuration updated with success"
                             askForReboot:needsReboot];
    };
    
    if ([[self state] isEqualToString:@"enable"])
        [[SYComms shared] sendCommand:SYCommsCommandEnableRootless args:nil completion:block];
}

@end
