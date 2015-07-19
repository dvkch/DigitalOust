//
//  SYViewController.m
//  DigitalOust
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
#import "NSError+DigitalOust.h"
#import "SYComms.h"
#import "SYPatchItemView.h"
#import "Masonry.h"

@interface SYViewController () <SYCommsDelegate>
@property (nonatomic, strong) NSTextField *labelTitle;
@property (nonatomic, strong) NSTextField *labelMaker;
@property (nonatomic, strong) SYPatchItemView *patchSupportedSoundCard;
@property (nonatomic, strong) SYPatchItemView *patchAppleHDAPatch;
@property (nonatomic, strong) SYPatchItemView *patchKextDevModePatch;
@property (nonatomic, strong) SYPatchItemView *patchRootlessPatch;
@property (nonatomic, strong) NSMutableArray *patchViews;
@property (nonatomic, strong) NSTextField *labelDonate;
@property (nonatomic, strong) NSTextField *labelWebsite;

@property (nonatomic, strong) STPrivilegedTask *task;
@property (nonatomic, strong) NSMutableString *log;
@property (nonatomic, assign) BOOL taskReceivedThisPID;
@end

@implementation SYViewController

- (void)loadView
{
    self.view = [[NSView alloc] init];
    [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@600);
        //make.height.greaterThanOrEqualTo(@330);
    }];
    
    __weak SYViewController *wSelf = self;
    
    self.labelTitle = [[NSTextField alloc] init];
    [self.view addSubview:self.labelTitle];
    [self.labelTitle setBordered:NO];
    [self.labelTitle setEditable:NO];
    [self.labelTitle setFont:[NSFont fontWithName:@"HelveticaNeue-UltraLight" size:42]];
    [self.labelTitle setDrawsBackground:NO];
    [self.labelTitle setStringValue:@"Digital Oust"];

    
    self.labelMaker = [[NSTextField alloc] init];
    [self.view addSubview:self.labelMaker];
    [self.labelMaker setBordered:NO];
    [self.labelMaker setEditable:NO];
    [self.labelMaker setFont:[NSFont fontWithName:@"HelveticaNeue-LightItalic" size:[NSFont systemFontSize]]];
    [self.labelMaker setDrawsBackground:NO];
    [self.labelMaker setStringValue:@"by @Syan_me"];
    
    
    self.labelDonate = [[NSTextField alloc] init];
    [self.view addSubview:self.labelDonate];
    [self.labelDonate setBordered:NO];
    [self.labelDonate setEditable:NO];
    //[self.labelDonate setFont:[NSFont fontWithName:@"HelveticaNeue-Light" size:[NSFont systemFontSize]]];
    [self.labelDonate setDrawsBackground:NO];
    [self.labelDonate setStringValue:@"Donate"];
    
    
    self.labelWebsite = [[NSTextField alloc] init];
    [self.view addSubview:self.labelWebsite];
    [self.labelWebsite setBordered:NO];
    [self.labelWebsite setEditable:NO];
    //[self.labelWebsite setFont:[NSFont fontWithName:@"HelveticaNeue-Light" size:[NSFont systemFontSize]]];
    [self.labelWebsite setDrawsBackground:NO];
    [self.labelWebsite setStringValue:@"Website"];
    
    
    self.patchViews = [NSMutableArray array];
    
    
    self.patchSupportedSoundCard = [[SYPatchItemView alloc] init];
    [self.view addSubview:self.patchSupportedSoundCard];
    [self.patchViews addObject:self.patchSupportedSoundCard];
    [self.patchSupportedSoundCard setTitleText:@"Sound card: seems fully supported" forState:@"supported"];
    [self.patchSupportedSoundCard setTitleText:@"Sound card: not supported" forState:@"not supported"];
    [self.patchSupportedSoundCard setTitleText:@"No sound card detected, driver may not be loaded" forState:@"empty"];
    [self.patchSupportedSoundCard setTitleText:@"Multiple sound cards detected, unplug any external screen or audio device" forState:@"multiple"];
    [self.patchSupportedSoundCard setDescrText:@"To be supported the sound card configuration stored in the AppleHDA sound card driver must respect a few conditions. Click Details to know why you card is or is not supported."];
    [self.patchSupportedSoundCard setButtonText:@"Details" forState:@"all"];
    [self.patchSupportedSoundCard setDetermineStateBlock:^NSString *{
        NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
        if([modelIDs count] == 0) return @"empty";
        if([modelIDs count] >= 2) return @"multiple";
        NSString *modelID = [modelIDs[0] stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
        NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
        BOOL supported = [SYAppleHDAHelper layoutIDSeemsSupported:layoutID useBackupFileIfPresent:YES details:NULL];
        return supported ? @"supported" : @"not supported";
    }];
    [self.patchSupportedSoundCard setUseSuccessImageForStateBlock:^BOOL(NSString *state) {
        return [state isEqualToString:@"supported"];
    }];
    [self.patchSupportedSoundCard setButtonTappedBlock:^{
        [wSelf buttonSupportedSoundCardTap];
    }];
    
    
    self.patchAppleHDAPatch = [[SYPatchItemView alloc] init];
    [self.view addSubview:self.patchAppleHDAPatch];
    [self.patchViews addObject:self.patchAppleHDAPatch];
    [self.patchAppleHDAPatch setTitleText:@"AppleHDA: patched" forState:@"patched"];
    [self.patchAppleHDAPatch setTitleText:@"AppleHDA: not patched" forState:@"not patched"];
    [self.patchAppleHDAPatch setDescrText:@"This patch edits AppleHDA configuration file to remove the Digital Out from the list of possible outputs. After applying this patch or restoring to default settings you need to restart your computer; it may take a bit more time than usual."];
    [self.patchAppleHDAPatch setButtonText:@"Restore" forState:@"patched"];
    [self.patchAppleHDAPatch setButtonText:@"Patch" forState:@"not patched"];
    [self.patchAppleHDAPatch setDetermineStateBlock:^NSString *{
        return [SYAppleHDAHelper hasBackupFile] ? @"patched" : @"not patched";
    }];
    [self.patchAppleHDAPatch setUseSuccessImageForStateBlock:^BOOL(NSString *state) {
        return [state isEqualToString:@"patched"];
    }];
    [self.patchAppleHDAPatch setButtonTappedBlock:^{
        [wSelf buttonAppleHDAPatchTap];
    }];
    
    if ([SYNVRAMHelper kextDevModeStatus] != SYNVRAMBootArgStatusNotRequired)
    {
        self.patchKextDevModePatch = [[SYPatchItemView alloc] init];
        [self.view addSubview:self.patchKextDevModePatch];
        [self.patchViews addObject:self.patchKextDevModePatch];
        [self.patchKextDevModePatch setTitleText:@"Kext dev mode: not needed" forState:@"not needed"];
        [self.patchKextDevModePatch setTitleText:@"Kext dev mode: enabled" forState:@"enabled"];
        [self.patchKextDevModePatch setTitleText:@"Kext dev mode: disabled" forState:@"disabled"];
        [self.patchKextDevModePatch setDescrText:@"Starting with OSX Yosemite 10.10"];
        [self.patchKextDevModePatch setButtonText:@"Enable" forState:@"enabled"];
        [self.patchKextDevModePatch setButtonText:@"Disabled" forState:@"disabled"];
        [self.patchKextDevModePatch setButtonText:@"" forState:@"not needed"];
        [self.patchKextDevModePatch setDetermineStateBlock:^NSString *{
            switch ([SYNVRAMHelper kextDevModeStatus]) {
                case SYNVRAMBootArgStatusNotRequired: return @"not required"; break;
                case SYNVRAMBootArgStatusOFF:         return @"disabled";     break;
                case SYNVRAMBootArgStatusON:          return @"enabled";      break;
            }
        }];
        [self.patchKextDevModePatch setUseSuccessImageForStateBlock:^BOOL(NSString *state) {
            return ![state isEqualToString:@"disabled"];
        }];
        [self.patchKextDevModePatch setButtonTappedBlock:^{
            [wSelf buttonKextDevModePatchTap];
        }];
    }
    
    if ([SYNVRAMHelper rootlessStatus] != SYNVRAMBootArgStatusNotRequired)
    {
        self.patchRootlessPatch = [[SYPatchItemView alloc] init];
        [self.view addSubview:self.patchRootlessPatch];
        [self.patchViews addObject:self.patchRootlessPatch];
        [self.patchRootlessPatch setTitleText:@"Rootless mode: not needed" forState:@"not needed"];
        [self.patchRootlessPatch setTitleText:@"Rootless mode: enabled" forState:@"enabled"];
        [self.patchRootlessPatch setTitleText:@"Rootless mode: disabled" forState:@"disabled"];
        [self.patchRootlessPatch setDescrText:@"Starting with OSX El Capitan 10.11"];
        [self.patchRootlessPatch setButtonText:@"Enable" forState:@"enabled"];
        [self.patchRootlessPatch setButtonText:@"Disabled" forState:@"disabled"];
        [self.patchRootlessPatch setButtonText:@"" forState:@"not needed"];
        [self.patchRootlessPatch setDetermineStateBlock:^NSString *{
            switch ([SYNVRAMHelper kextDevModeStatus]) {
                case SYNVRAMBootArgStatusNotRequired: return @"not required"; break;
                case SYNVRAMBootArgStatusOFF:         return @"disabled";     break;
                case SYNVRAMBootArgStatusON:          return @"enabled";      break;
            }
        }];
        [self.patchRootlessPatch setUseSuccessImageForStateBlock:^BOOL(NSString *state) {
            return ![state isEqualToString:@"enabled"];
        }];
        [self.patchRootlessPatch setButtonTappedBlock:^{
            [wSelf buttonRootlessPatchTap];
        }];
    }
    
    [self.labelTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@18);
        make.top.equalTo(@18);
        make.width.equalTo(@330);
        make.height.equalTo(@50);
    }];
    
    [self.labelMaker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-18));
        make.bottom.equalTo(self.labelTitle);
        make.width.equalTo(@80);
        make.height.equalTo(@21);
    }];
    
    [self.labelDonate mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.labelTitle);
        make.right.equalTo(self.labelMaker);
        make.bottom.equalTo(@(-10));
    }];
    
    for (NSUInteger i = 0; i < self.patchViews.count; ++i)
    {
        NSView *view = self.patchViews[i];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            if (i == 0)
                make.top.equalTo(self.labelTitle.mas_bottom).offset(40);
            else
                make.top.equalTo(((NSView *)self.patchViews[i-1]).mas_bottom).offset(20);
            make.left.equalTo(self.labelTitle);
            make.right.equalTo(self.labelMaker);
            if (i == self.patchViews.count - 1)
                make.bottom.equalTo(@(-20));
        }];
    }
    
    [[SYComms shared] setIdentifier:@"app" delegate:self];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self updateItems];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    [self startAgentAndComms];
}

- (void)startAgentAndComms
{
    return;
    
    if(self.task)
        return;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DigitalOustHelper" ofType:@""];
    STPrivilegedTask *task = [[STPrivilegedTask alloc] initWithLaunchPath:path];
    OSStatus oserror = [task launch];
    
    if(oserror != errAuthorizationSuccess)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Couldn't start agent"];
        [alert setInformativeText:[[NSError SYErrorAuthWithCode:oserror] localizedDescriptionSY]];
        [alert addButtonWithTitle:@"Close"];
        [alert addButtonWithTitle:@"Try again"];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == abs(NSModalResponseAbort))
            {
                [self startAgentAndComms];
            }
        }];
        return;
    }
    
    self.task = task;
    [self sendPIDToTask];
    [self updateItems];
}

- (void)sendPIDToTask
{
    if(!self.task || !self.task.isRunning || self.taskReceivedThisPID)
        return;
    
    [[SYComms shared] sendCommand:SYCommsCommandUpdateParentProcessID args:@{@"pid":@(getpid())}];
    
    __weak SYViewController *wSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wSelf sendPIDToTask];
    });
}

#pragma mark -

- (void)addLogMessage:(NSString *)logMessage
{
    if(self.log)
        [self.log appendFormat:@"\n%@", logMessage];
    else
        self.log = [logMessage mutableCopy];
    NSLog(@"-> %@", logMessage);
}

- (void)displayAlertWithTitle:(NSString *)title informativeText:(NSString *)informativeText
{
    [self displayAlertWithTitle:title informativeText:informativeText button0:nil button1:nil block:nil];
}

- (void)displayAlertWithTitle:(NSString *)title
              informativeText:(NSString *)informativeText
                      button0:(NSString *)button0
                      button1:(NSString *)button1
                        block:(void(^)(NSUInteger tappedIndex))block
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert addButtonWithTitle:(button0 ?: @"Close")];
    if(button1)
        [alert addButtonWithTitle:button1];
    [alert setInformativeText:informativeText ?: @""];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if(block)
            block(labs(returnCode) == labs(NSModalResponseAbort));
        [self updateItems];
    }];
}

#pragma mark - View

- (void)updateItems
{
    [self.patchSupportedSoundCard   setButtonEnabled:YES];
    [self.patchAppleHDAPatch        setButtonEnabled:self.task ? YES : NO];
    [self.patchKextDevModePatch     setButtonEnabled:self.task ? YES : NO];
    [self.patchRootlessPatch        setButtonEnabled:self.task ? YES : NO];
    [self.patchSupportedSoundCard   updateState];
    [self.patchAppleHDAPatch        updateState];
    [self.patchKextDevModePatch     updateState];
    [self.patchRootlessPatch        updateState];
}

// empty, multiple, supported, not supported
- (IBAction)buttonSupportedSoundCardTap
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
    
    [self displayAlertWithTitle:@"Supported sound card detection" informativeText:details];
}

// patched, not patched
- (IBAction)buttonAppleHDAPatchTap
{
    if([SYAppleHDAHelper hasBackupFile])
    {
        [[SYComms shared] sendCommand:SYCommsCommandRestoreAppleHDA args:nil];
    }
    else
    {
        NSArray *modelIDs = [SYIOKitHelper listAudioModelIDs];
        if([modelIDs count] != 1)
        {
            [self displayAlertWithTitle:NSLocalizedString(@"Patch aborted", @"Patch aborted")
                        informativeText:[[NSError SYErrorWithCode:SYErrorCodeSoundCardNotSupported userInfo:nil] localizedDescriptionSY]];
            return;
        }
        
        NSString *modelID = modelIDs[0];
        modelID = [modelID stringByReplacingOccurrencesOfString:@"AppleHDA:" withString:@""];
        NSNumber *layoutID = [NSNumber numberWithInt:[modelID intValue]];
        [[SYComms shared] sendCommand:SYCommsCommandPatchAppleHDA args:@{@"layoutid":layoutID}];
    }
}

// enabled, disabled, not required
- (IBAction)buttonKextDevModePatchTap
{
    switch ([SYNVRAMHelper kextDevModeStatus]) {
        case SYNVRAMBootArgStatusNotRequired:
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Kext dev mode"];
            [alert setInformativeText:@"This security has been added by Apple in OSX Yosemite (10.10) to prevent editing device drivers (KEXT) that are not signed by Apple or a valid developper"];
            [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        }
            break;
        case SYNVRAMBootArgStatusOFF:
            [[SYComms shared] sendCommand:SYCommsCommandSetKextDevMode args:@{@"enabled":@(YES)}];
            break;
        case SYNVRAMBootArgStatusON:
            [[SYComms shared] sendCommand:SYCommsCommandSetKextDevMode args:@{@"enabled":@(NO)}];
            break;
    }
    [self updateItems];
}

// enabled, disabled, not required
- (IBAction)buttonRootlessPatchTap
{
    switch ([SYNVRAMHelper rootlessStatus]) {
        case SYNVRAMBootArgStatusNotRequired:
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Rootless"];
            [alert setInformativeText:@"This security has been added by Apple in OSX El Capitain (10.11) to prevent editing system files"];
            [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        }
            break;
        case SYNVRAMBootArgStatusOFF:
            [[SYComms shared] sendCommand:SYCommsCommandSetRootless args:@{@"enabled":@(YES)}];
            break;
        case SYNVRAMBootArgStatusON:
            [[SYComms shared] sendCommand:SYCommsCommandSetRootless args:@{@"enabled":@(NO)}];
            break;
    }
}

- (IBAction)buttonHelpTap:(id)sender
{
    [self displayAlertWithTitle:@"Help"
                informativeText:@"This tool was made after crying too much over my dead internal speakers.\n\nYou can learn more on how it works or contact me by visiting my website. If you enjoyed using it you can also by me a beer ;)"
                        button0:@"Close"
                        button1:@"Open website"
                          block:^(NSUInteger tappedIndex)
    {
        if (tappedIndex == 1)
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://syan.me/"]];
    }];
}

#pragma mark - SYCommsDelegate

- (void)comms:(SYComms *)comms receivedCommand:(SYCommsCommand)command arguments:(NSDictionary *)arguments
{
    [self updateItems];
    if(command == SYCommsCommandLog)
    {
        [self addLogMessage:arguments[@"log"]];
    }
}

- (void)comms:(SYComms *)comms receivedSuccessForCommand:(SYCommsCommand)command
{
    [self updateItems];
    NSString *title = nil;
    switch (command) {
        case SYCommsCommandSetRootless:           title = @"Updating boot configuration"; break;
        case SYCommsCommandSetKextDevMode:        title = @"Updating boot configuration"; break;
        case SYCommsCommandPatchAppleHDA:         title = @"Patching AppleHDA";           break;
        case SYCommsCommandRestoreAppleHDA:       title = @"Restoring AppleHDA";          break;
        case SYCommsCommandUpdateParentProcessID: self.taskReceivedThisPID = YES;         break;
        default: break;
    }
    
    if(title)
        [self displayAlertWithTitle:title informativeText:nil];
}

- (void)comms:(SYComms *)comms receivedErrorForCommand:(SYCommsCommand)command error:(NSError *)error
{
    [self updateItems];
    NSString *title = nil;
    switch (command) {
        case SYCommsCommandSetRootless:    title = @"Couldn't update boot configuration";   break;
        case SYCommsCommandSetKextDevMode: title = @"Couldn't update boot configuration";   break;
        case SYCommsCommandPatchAppleHDA:  title = @"Couldn't patch AppleHDA";              break;
        case SYCommsCommandRestoreAppleHDA:title = @"Couldn't restore AppleHDA";            break;
        default: break;
    }
    
    if(title)
        [self displayAlertWithTitle:title informativeText:[error localizedDescriptionSY]];
}

@end
