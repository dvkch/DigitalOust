//
//  SYStepRestore1.m
//  DigitalOust
//
//  Created by Stan Chevallier on 20/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepRestore1.h"
#import "SYAppleHDAHelper.h"
#import "SYComms.h"
#import "SYIOKitHelper.h"
#import "NSAlert+DigitalOust.h"
#import "NSError+DigitalOust.h"
#import "SYNVRAMHelper.h"

@implementation SYStepRestore1

- (NSString *)statusString
{
    return [SYAppleHDAHelper hasBackupFile] ? @"patched" : @"not patched";
}

- (NSString *)titleText
{
    if ([[self statusString] isEqualToString:@"patched"])
        return @"AppleHDA: patch is still present";
    if ([[self statusString] isEqualToString:@"not patched"])
        return @"AppleHDA: restored";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self statusString] isEqualToString:@"patched"])
        return @"Restore";
    return nil;
}

- (NSString *)descrText
{
    return @"This will remove the modified AppleHDA configuration file and replace it with the backup that was made by this tool. After restoring you need to restart your computer; it may take a bit more time than usual";
}

- (SYStepImage)image
{
    if ([[self statusString] isEqualToString:@"patched"])      return SYStepImageNotOK;
    if ([[self statusString] isEqualToString:@"not patched"])  return SYStepImageOK;
    return SYStepImageNotOK;
}

- (void)buttonTap:(NSView *)sender
{
    // need to reboot after patch only if the user won't reboot after disabling rootless
    BOOL reboot = ([SYNVRAMHelper rootlessStatus] == SYNVRAMBootArgStatusNotRequired);
    
    SYCommsCompletionBlock block = ^(NSError *error) {
        if (error)
            [NSAlert displayAlertWithTitle:@"Error while patching AppleHDA"
                           informativeText:[error localizedDescriptionSY]
                            onWindowOrView:sender.window];
        else
            [NSAlert displayAlertWithTitle:@"AppleHDA patched with success"
                              askForReboot:reboot
                            onWindowOrView:sender.window];
    };
    
    if ([[self statusString] isEqualToString:@"patched"])
    {
        [[SYComms shared] sendCommand:SYCommsCommandRestoreAppleHDA args:nil completion:block];
    }
}

@end
