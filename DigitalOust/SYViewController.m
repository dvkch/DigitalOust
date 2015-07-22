//
//  SYViewController.m
//  DigitalOust
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import "SYViewController.h"
#import "SYAppDelegate.h"
#import "STPrivilegedTask.h"
#import "SYComms.h"
#import "SYStepView.h"
#import "SYStepPatch0.h"
#import "SYStepPatch1.h"
#import "SYStepPatch2.h"
#import "SYStepPatch3.h"
#import "Masonry.h"
#import "SYTitleView.h"
#import "SYAppDelegate.h"
#import "NSError+DigitalOust.h"
#import "NSWindow+Alerts.h"

@interface SYViewController () <SYCommsDelegate>
@property (nonatomic, strong) SYTitleView           *titleView;
@property (nonatomic, strong) NSSegmentedControl    *segmentedControl;
@property (nonatomic, strong) NSArray               *stepViewsPatch;
@property (nonatomic, strong) NSArray               *stepViewsRestore;

@property (nonatomic, strong) STPrivilegedTask  *task;
@property (nonatomic, strong) NSMutableString   *log;
@property (nonatomic, assign) BOOL              taskReceivedThisPID;
@end

@implementation SYViewController

- (void)loadView
{
    __weak SYViewController *wSelf = self;
    self.view = [[NSView alloc] init];
    [self.view setWantsLayer:YES];
    [self.view.layer setCornerRadius:4.];
    
    [[SYAppDelegate obtain] setWindowFocusChanged:^{
        [wSelf updateBackgroundColor];
    }];
    
    self.titleView = [[SYTitleView alloc] init];
    [self.view addSubview:self.titleView];
    
    NSMutableArray *stepViewsPatch = [NSMutableArray array];
    for (int i = 0; i < 4; ++i)
    {
        Class stepClass = NSClassFromString([NSString stringWithFormat:@"SYStepPatch%d", i]);
        SYStep *step = [[stepClass alloc] init];
        if (![step show])
            continue;
        [step setStepNumber:i];
        SYStepView *stepView = [[SYStepView alloc] init];
        [stepView setStep:step];
        [stepViewsPatch addObject:stepView];
    }
    self.stepViewsPatch = [stepViewsPatch copy];
    
    self.segmentedControl = [[NSSegmentedControl alloc] init];
    [self.segmentedControl setSegmentCount:2];
    [self.segmentedControl setSegmentStyle:NSSegmentStyleRoundRect];
    [self.segmentedControl setLabel:@"Patch"    forSegment:0];
    [self.segmentedControl setLabel:@"Restore"  forSegment:1];
    [self.segmentedControl setSelectedSegment:0];
    [self.segmentedControl setTarget:self];
    [self.segmentedControl setAction:@selector(segmentedControlTap:)];
    [self.view addSubview:self.segmentedControl];
    
    [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@600);
    }];
    
    [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.top.equalTo(@0);
    }];
    
    [self.segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleView.mas_bottom).offset(20);
        make.centerX.equalTo(@0);
    }];
    
    [self openTab:0];
    [[SYComms shared] setIdentifier:@"app" delegate:self];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self updateItems];
    [self updateBackgroundColor];
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
        [self.view.window displayAlertWithTitle:@"Couldn't start agent"
                                informativeText:[[NSError SYErrorAuthWithCode:oserror] localizedDescriptionSY]
                                        button0:@"Close"
                                        button1:@"Try again"
                                          block:^(NSUInteger tappedIndex) {
                                              if (tappedIndex == 1)
                                                  [self startAgentAndComms];
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
    
    __weak SYViewController *wSelf = self;
    
    [[SYComms shared] sendCommand:SYCommsCommandUpdateParentProcessID args:@{@"pid":@(getpid())} completion:^(NSError *error) {
        [wSelf setTaskReceivedThisPID:(error ? NO : YES)];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wSelf sendPIDToTask];
    });
}

- (void)openTab:(NSUInteger)tab
{
    [self.stepViewsPatch   makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.stepViewsRestore makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSArray *stepViews = (tab == 0) ? self.stepViewsPatch : self.stepViewsRestore;
    
    for (NSUInteger i = 0; i < [stepViews count]; ++i)
    {
        NSView *view = stepViews[i];
        [self.view addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            if (i == 0)
                make.top.equalTo(self.segmentedControl.mas_bottom).offset(20);
            else
                make.top.equalTo(((NSView *)stepViews[i-1]).mas_bottom).offset(20);
            make.left.equalTo(@18);
            make.right.equalTo(@(-18));
            if (i == stepViews.count - 1)
                make.bottom.equalTo(@(-20));
        }];
    }
    
    [self.view setNeedsLayout:YES];
}

#pragma mark - Log

- (void)addLogMessage:(NSString *)logMessage
{
    if(self.log)
        [self.log appendFormat:@"\n%@", logMessage];
    else
        self.log = [logMessage mutableCopy];
    NSLog(@"-> %@", logMessage);
}

#pragma mark - View

- (void)updateBackgroundColor
{
    BOOL active = (!self.view.window || self.view.window.isKeyWindow);
    [self.view.layer setBackgroundColor:[NSColor colorWithCalibratedWhite:(active ? 232. : 246.)/255. alpha:1.].CGColor];
}

- (void)updateItems
{
    BOOL agentStart = (self.task ? YES : NO);
    
    for (SYStepView *stepView in self.stepViewsPatch)
        [stepView setButtonEnabled:([stepView.step requiresRoot] ? agentStart : YES)];
    
    for (SYStepView *stepView in self.stepViewsRestore)
        [stepView setButtonEnabled:([stepView.step requiresRoot] ? agentStart : YES)];
}

#pragma mark - Actions

- (void)segmentedControlTap:(id)sender
{
    [self openTab:self.segmentedControl.selectedSegment];
}

#pragma mark - SYCommsDelegate

- (void)comms:(SYComms *)comms
receivedCommand:(SYCommsCommand)command
    commandID:(NSString *)commandID
    arguments:(NSDictionary *)arguments
{
    [self updateItems];
    if(command == SYCommsCommandLog)
    {
        [self addLogMessage:arguments[@"log"]];
    }
}

@end
