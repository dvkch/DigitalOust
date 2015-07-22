//
//  SYStepPatch2.m
//  DigitalOust
//
//  Created by Stan Chevallier on 20/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepPatch2.h"
#import "SYAppleHDAHelper.h"
#import "SYComms.h"
#import "SYIOKitHelper.h"
#import "NSWindow+Alerts.h"
#import "NSError+DigitalOust.h"
#import "SYNVRAMHelper.h"

@implementation SYStepPatch2

- (NSString *)state
{
    NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
    if([modelIDs count] == 0) return @"not supported";
    if([modelIDs count] >= 2) return @"not supported";
    NSString *modelID = [modelIDs[0] stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
    NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
    BOOL supported = [SYAppleHDAHelper layoutIDSeemsSupported:layoutID useBackupFileIfPresent:YES details:NULL];
    if (!supported) return @"not supported";
    return [SYAppleHDAHelper hasBackupFile] ? @"patched" : @"not patched";
}

- (NSString *)titleText
{
    if ([[self state] isEqualToString:@"patched"])
        return @"AppleHDA: patched!";
    if ([[self state] isEqualToString:@"not patched"])
        return @"AppleHDA: patch needed";
    if ([[self state] isEqualToString:@"not supported"])
        return @"AppleHDA: audio card not recognized or not supported";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self state] isEqualToString:@"not patched"])
        return @"Patch";
    return nil;
}

- (NSString *)descrText
{
    return @"This is the main step. It will modify AppleHDA (sound driver) configuration to remove Digitial Out from the list of possible outputs. After applying this patch or restoring to default settings you need to restart your computer; it may take a bit more time than usual";
}

- (SYStepImage)image
{
    if ([[self state] isEqualToString:@"patched"])      return SYStepImageOK;
    if ([[self state] isEqualToString:@"not patched"])  return SYStepImageNotOK;
    return SYStepImageNotOK;
}

- (void)buttonTap:(NSWindow *)window
{
    // need to reboot after patch only if rootless is to be disabled
    BOOL reboot = [SYNVRAMHelper rootlessStatus] != SYNVRAMBootArgStatusNotRequired;
    
    SYCommsCompletionBlock block = ^(NSError *error) {
        if (error)
            [window displayAlertWithTitle:@"Error while patching AppleHDA"
                          informativeText:[error localizedDescriptionSY]];
        else
            [window displayAlertWithTitle:@"AppleHDA patched with success"
                          askForReboot:reboot];
    };
    
    if ([[self state] isEqualToString:@"not patched"])
    {
        NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
        if([modelIDs count] != 1)
            return;
        NSString *modelID = modelIDs[0];
        modelID = [modelID stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
        NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
        [[SYComms shared] sendCommand:SYCommsCommandPatchAppleHDA args:@{@"layoutid":layoutID} completion:block];
    }
}

@end
