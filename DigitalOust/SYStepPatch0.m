//
//  SYStepPatch0.m
//  DigitalOust
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepPatch0.h"
#import "SYIOKitHelper.h"
#import "SYAppleHDAHelper.h"
#import "NSWindow+Tools.h"

@implementation SYStepPatch0

- (NSString *)state
{
    NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
    if([modelIDs count] == 0) return @"empty";
    if([modelIDs count] >= 2) return @"multiple";
    NSString *modelID = [modelIDs[0] stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
    NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
    BOOL supported = [SYAppleHDAHelper layoutIDSeemsSupported:layoutID useBackupFileIfPresent:YES details:NULL];
    return supported ? @"supported" : @"not supported";
}

- (NSString *)titleText
{
    if ([[self state] isEqualToString:@"supported"])        return @"Sound card: seems fully supported";
    if ([[self state] isEqualToString:@"not supported"])    return @"Sound card: not supported";
    if ([[self state] isEqualToString:@"empty"])            return @"No sound card detected, driver may not be loaded";
    if ([[self state] isEqualToString:@"multiple"])         return @"Multiple sound cards detected, unplug any external screen or audio device";
    return nil;
}

- (NSString *)buttonText
{
    return @"Details";
}

- (NSString *)descrText
{
    return @"To be supported the sound card configuration stored in the AppleHDA sound card driver must respect a few conditions. Click Details to know why you card is or is not supported";
}

- (SYStepImage)image
{
    if ([[self state] isEqualToString:@"supported"])        return SYStepImageOK;
    if ([[self state] isEqualToString:@"not supported"])    return SYStepImageNotOK;
    if ([[self state] isEqualToString:@"empty"])            return SYStepImageNotOK;
    if ([[self state] isEqualToString:@"multiple"])         return SYStepImageNotOK;
    return SYStepImageNotOK;
}

- (BOOL)requiresRoot
{
    return NO;
}

- (void)buttonTap:(NSWindow *)window
{
    NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
    NSString *details;
    if([modelIDs count] == 0)
        details = @"No sound card detected, driver may not be loaded";
    else if([modelIDs count] > 1)
        details = @"Multiple sound cards detected, unplug any external screen or audio device";
    else
    {
        NSString *modelID = modelIDs[0];
        modelID = [modelID stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
        NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
        [SYAppleHDAHelper layoutIDSeemsSupported:layoutID useBackupFileIfPresent:YES details:&details];
    }
    
    [window displayAlertWithTitle:@"Supported sound card detection" informativeText:details block:^(NSUInteger tappedIndex) {
        if (self.updatedBlock)
            self.updatedBlock();
    }];
}

@end
