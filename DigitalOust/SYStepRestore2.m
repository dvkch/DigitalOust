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
#import "NSError+DigitalOust.h"
#import "NSAlert+DigitalOust.h"
#import "SYKextHelper.h"

@interface SYStepRestore2 ()
@property (nonatomic, strong) NSArray *invalidKexts;
@property (nonatomic, strong) SYKextHelper *kextHelper;
@end

@implementation SYStepRestore2

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.kextHelper = [[SYKextHelper alloc] init];
    }
    return self;
}

- (NSString *)statusString
{
    if (!self.invalidKexts)
        return @"loading";
    
    // both not required
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusNotRequired)
        return @"hide";
    
    // rootless not required
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusOFF)
        return @"ok kext";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusNotRequired &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusON)
        return @"need kextdevmode";
    
    // both required
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusON &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusOFF)
        return @"ok both";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusON &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusON)
        return @"need kextdevmode";
    
    if ([SYNVRAMHelper rootlessStatus]    == SYNVRAMBootArgStatusOFF &&
        [SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusOFF)
        return @"need rootless";
    
    return @"need both";
}

- (NSString *)titleText
{
    if ([[self statusString] isEqualToString:@"loading"])
        return @"Boot configuration: loading...";
    if ([[self statusString] isEqualToString:@"ok kext"])
        return @"Boot configuration: everything is good!";
    if ([[self statusString] isEqualToString:@"ok both"])
        return @"Boot configuration: everything is good!";
    if ([[self statusString] isEqualToString:@"need kextdevmode"])
        return @"Boot configuration: kext-dev-mode may be disabled";
    if ([[self statusString] isEqualToString:@"need rootless"])
        return @"Boot configuration: rootless may be re-enabled";
    if ([[self statusString] isEqualToString:@"need both"])
        return @"Boot configuration: kext-dev-mode may be disabled and rootless re-enabled";
    return nil;
}

- (NSString *)buttonText
{
    if ([[self statusString] isEqualToString:@"need kextdevmode"]) return @"Disable";
    if ([[self statusString] isEqualToString:@"need rootless"])    return @"Enable";
    if ([[self statusString] isEqualToString:@"need both"])        return @"Apply";
    return nil;
}

- (NSString *)descrText
{
    NSString *kextDesc = @"Kext dev mode is no longer required to load the patched AppleHDA and you may re-enable it if no other similar patches are enabled on your system (e.g. TrimEnabled).";
    NSString *rootDesc = @"Rootless mode needs to be disabled to restore AppleHDA, once this is done it can be re-enabled.";
    
    BOOL kext = [SYNVRAMHelper kextDevModeStatus] != SYNVRAMBootArgStatusNotRequired;
    BOOL root = [SYNVRAMHelper rootlessStatus]    != SYNVRAMBootArgStatusNotRequired;
    
    return [NSString stringWithFormat:@"%@%@%@",
            root ? rootDesc : @"",
            root && kext ? @"\n" : @"",
            kext ? kextDesc : @""];
}

- (SYStepImage)image
{
    if ([[self statusString] isEqualToString:@"loading"])          return SYStepImageProgressDetermined;
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

- (void)startUpdating
{
    if ([SYNVRAMHelper kextDevModeStatus] == SYNVRAMBootArgStatusNotRequired)
        return;
    
    self.invalidKexts = nil;
    
    if (self.updatedBlock)
        self.updatedBlock();
    
    __weak SYStepRestore2 *wSelf = self;
    [self.kextHelper listInvalidKextsWithProgress:self.progressBlock
                                       completion:^(NSArray *invalidKexts)
    {
        wSelf.invalidKexts = invalidKexts;
        if (wSelf.updatedBlock)
            wSelf.updatedBlock();
    }];
}

- (void)stopUpdating
{
    [self.kextHelper stopListingInvalidKexts];
}

@end
