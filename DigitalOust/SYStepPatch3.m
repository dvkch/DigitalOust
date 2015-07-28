//
//  SYStepPatch3.m
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepPatch3.h"
#import "SYNVRAMHelper.h"
#import "SYComms.h"
#import "NSAlert+DigitalOust.h"
#import "NSError+DigitalOust.h"

@implementation SYStepPatch3

- (NSString *)statusString
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
    if ([[self statusString] isEqualToString:@"ok"])
        return @"Boot configuration: everything is good!";
    if ([[self statusString] isEqualToString:@"enable"])
        return @"Boot configuration: rootless can be re-enabled";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self statusString] isEqualToString:@"enable"])
        return @"Disable";
    return nil;
}

- (NSString *)descrText
{
    if ([[self statusString] isEqualToString:@"enable"])
        return @"Rootless mode has been disabled to apply this patch, and can be re-enabled. This step is optional as you may want to keep rootless mode disabled for other reasons";
    return nil;
}

- (SYStepImage)image
{
    if ([[self statusString] isEqualToString:@"enable"])  return SYStepImageNotOKOptional;
    return SYStepImageOK;
}

- (BOOL)show
{
    return ![[self statusString] isEqualToString:@"hide"];
}

- (void)buttonTap:(NSView *)sender
{
    BOOL needsReboot = [SYNVRAMHelper rootlessStatus] == SYNVRAMBootArgStatusOFF;
    
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
    
    if ([[self statusString] isEqualToString:@"enable"])
        [[SYComms shared] sendCommand:SYCommsCommandEnableRootless args:nil completion:block];
}

@end
