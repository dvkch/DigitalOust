//
//  SYViewController.m
//  DisableDigitalOut
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import "SYViewController.h"
#import "SYAppleHDAHelper.h"
#import "SYAppleHDAHelper.h"
#import "SYIOKitHelper.h"
#import "SYNVRAMHelper.h"
#import "STPrivilegedTask.h"
#import "SYAppDelegate.h"
#import "NSError+DisableDigitalOut.h"

@interface SYViewController ()
@property (nonatomic, weak)     IBOutlet NSImageView *imageViewSupportedSoundCard;
@property (nonatomic, weak)     IBOutlet NSImageView *imageViewAppleHDAPatch;
@property (nonatomic, weak)     IBOutlet NSImageView *imageViewKextDevModePatch;
@property (nonatomic, weak)     IBOutlet NSButton *buttonSupportedSoundCard;
@property (nonatomic, weak)     IBOutlet NSButton *buttonAppleHDAPatch;
@property (nonatomic, weak)     IBOutlet NSButton *buttonKextDevModePatch;
@property (nonatomic, weak)     IBOutlet NSTextField *labelSupportedSoundCard;
@property (nonatomic, weak)     IBOutlet NSTextField *labelAppleHDAPatch;
@property (nonatomic, weak)     IBOutlet NSTextField *labelKextDevModePatch;
@property (nonatomic, strong)   IBOutlet NSTextView *consoleView;
@property (nonatomic, strong)   IBOutlet NSScrollView *consoleScrollView;
@property (nonatomic, strong)   NSMutableString *log;
@end

@implementation SYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    /*
#if DEBUG
    if(geteuid() == 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"Tap OK when attached to LLDB. PID is %d", getpid()]];
        [alert addButtonWithTitle:@"Done"];
        [alert runModal];
    }
#endif
    */
    [self updateItems];
}

- (void)addLogMessage:(NSString *)logMessage
{
    if(self.log)
        [self.log appendFormat:@"\n%@", logMessage];
    else
        self.log = [logMessage mutableCopy];
    
    self.consoleView.string = self.log;
    [self.consoleView scrollRangeToVisible:NSMakeRange(self.log.length, 0)];
}

- (void)updateItems
{
    BOOL cardSupported = NO;
    {
        NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
        if([modelIDs count] == 1)
        {
            NSString *modelID = modelIDs[0];
            modelID = [modelID stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
            NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
            NSString *details;
            cardSupported = [SYAppleHDAHelper layoutIDSeemsSupported:layoutID details:&details];
            NSArray *detailsLines = [details componentsSeparatedByString:@"\n"];
            NSString *title = [NSString stringWithFormat:@"Supported card: %@", [detailsLines lastObject]];
            [self.labelSupportedSoundCard setStringValue:title];
        }
        else if([modelIDs count] > 1)
        {
            [self.labelSupportedSoundCard setStringValue:@"Multiple sound cards detected, unplug any external screen or audio device"];
        }
        else
        {
            [self.labelSupportedSoundCard setStringValue:@"No sound card detected"];
        }
    }
    
    NSImage *check = [NSImage imageNamed:@"check"];
    NSImage *cross = [NSImage imageNamed:@"cross"];
    
    [self.imageViewAppleHDAPatch      setImage:([SYAppleHDAHelper hasBackupFile]   ? check : cross)];
    [self.imageViewKextDevModePatch   setImage:([SYNVRAMHelper kextDevModeEnabled] ? check : cross)];
    [self.imageViewSupportedSoundCard setImage:(cardSupported ? check : cross)];
    
    [self.labelKextDevModePatch setStringValue:[NSString stringWithFormat:@"OSX Dev mode: %@",
                                                [SYNVRAMHelper kextDevModeEnabled] ? @"enabled" : @"disabled"]];
    
    BOOL runningAsRoot = [(SYAppDelegate *)[NSApp delegate] appRunningAsRoot];
    
    [self.buttonAppleHDAPatch       setEnabled:runningAsRoot];
    [self.buttonAppleHDAPatch       setTitle:[SYAppleHDAHelper hasBackupFile]   ? @"Restore" : @"Patch"];
    [self.buttonKextDevModePatch    setEnabled:runningAsRoot];
    [self.buttonKextDevModePatch    setTitle:[SYNVRAMHelper kextDevModeEnabled] ? @"Disable" : @"Enable"];
    [self.buttonSupportedSoundCard  setEnabled:runningAsRoot];
}

- (IBAction)buttonSupportedSoundCardTap:(id)sender
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
        [SYAppleHDAHelper layoutIDSeemsSupported:layoutID details:&details];
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Supported sound card detection"];
    [alert addButtonWithTitle:@"Close"];
    [alert addButtonWithTitle:@"Contact me"];
    [alert setInformativeText:details];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        [self updateItems];
        if(returnCode == NSModalResponseAbort)
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:contact@stanislaschevallier.fr"]];
        }
    }];
}

- (IBAction)buttonKextDevModePatchTap:(id)sender
{
    NSString *error;
    [SYNVRAMHelper setKextDevModeEnabled:![SYNVRAMHelper kextDevModeEnabled] error:&error];
    
    if(error)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Couldn't update boot configuration"];
        [alert addButtonWithTitle:@"Close"];
        [alert setInformativeText:error];
        [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Boot configuration updated!"];
        [alert addButtonWithTitle:@"Close"];
        [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
    }

    [self updateItems];
}

- (IBAction)buttonAppleHDAPatchTap:(id)sender
{
    void(^block)(NSString *output, NSError *error, BOOL ended) = ^(NSString *output, NSError *error, BOOL ended)
    {
        [self updateItems];
        if(error)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Couldn't patch AppleHDA"];
            [alert addButtonWithTitle:@"Close"];
            [alert setInformativeText:[error localizedDescriptionSY]];
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                [self updateItems];
            }];
        }
        else if(ended)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"AppleHDA patched!"];
            [alert addButtonWithTitle:@"Close"];
            [alert setInformativeText:(output ?: @"")];
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                [self updateItems];
            }];
        }
        else
        {
            NSLog(@"BLABLABLA");
        }
    };
    
    if([SYAppleHDAHelper hasBackupFile])
    {
        [SYAppleHDAHelper restoreOriginalFile:block];
    }
    else
    {
        NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
        if([modelIDs count] != 1)
        {
            block(nil, [NSError SYErrorWithCode:SYErrorCodeSoundCardNotSupported userInfo:nil], YES);
            return;
        }
        NSString *modelID = modelIDs[0];
        modelID = [modelID stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
        NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
        [SYAppleHDAHelper applyPatchForLayout:layoutID block:block];
    }
}

@end
