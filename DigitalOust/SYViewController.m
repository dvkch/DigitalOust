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
#import "SYStepRestore0.h"
#import "SYStepRestore1.h"
#import "SYStepRestore2.h"
#import "Masonry.h"
#import "SYTitleView.h"
#import "SYAppDelegate.h"
#import "NSError+DigitalOust.h"
#import "NSAlert+DigitalOust.h"
#import "NSColor+Tools.h"

@interface SYViewController () <SYCommsDelegate>
@property (nonatomic, strong) SYTitleView           *titleView;
@property (nonatomic, strong) NSSegmentedControl    *segmentedControl;
@property (nonatomic, strong) NSView                *contentViewPatch;
@property (nonatomic, strong) NSView                *contentViewRestore;
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
    
    NSMutableArray *stepViewsRestore = [NSMutableArray array];
    for (int i = 0; i < 3; ++i)
    {
        Class stepClass = NSClassFromString([NSString stringWithFormat:@"SYStepRestore%d", i]);
        SYStep *step = [[stepClass alloc] init];
        if (![step show])
            continue;
        [step setStepNumber:i];
        SYStepView *stepView = [[SYStepView alloc] init];
        [stepView setStep:step];
        [stepViewsRestore addObject:stepView];
    }
    self.stepViewsRestore = [stepViewsRestore copy];
    
    self.segmentedControl = [[NSSegmentedControl alloc] init];
    [self.segmentedControl setSegmentCount:2];
    [self.segmentedControl setSegmentStyle:NSSegmentStyleRounded];
    [self.segmentedControl setLabel:@"Patch"    forSegment:0];
    [self.segmentedControl setLabel:@"Restore"  forSegment:1];
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
    
    [self test];
}

- (void)test
{
    NSLog(@"%@", NSStringFromSize([self.view fittingSize]));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self test];
    });
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
        [NSAlert displayAlertWithTitle:@"Couldn't start agent"
                       informativeText:[[NSError SYErrorAuthWithCode:oserror] localizedDescriptionSY]
                               button0:@"Close"
                               button1:@"Try again"
                        onWindowOrView:self.view.window
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
    [self.segmentedControl setSelectedSegment:tab];
    
    [self.stepViewsPatch   makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.stepViewsRestore makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSArray *newStepViews = (tab == 0) ? self.stepViewsPatch : self.stepViewsRestore;
    NSArray *oldStepViews = (tab == 0) ? self.stepViewsRestore : self.stepViewsPatch;
    
    for (NSUInteger i = 0; i < [newStepViews count]; ++i)
    {
        SYStepView *view = newStepViews[i];
        [self.view addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            if (i == 0)
                make.top.equalTo(self.segmentedControl.mas_bottom).offset(20);
            else
                make.top.equalTo(((NSView *)newStepViews[i-1]).mas_bottom).offset(20);
            make.left.equalTo(@18);
            make.right.equalTo(@(-18));
            if (i == newStepViews.count - 1)
                make.bottom.equalTo(@(-20));
        }];
    }
    
    [oldStepViews makeObjectsPerformSelector:@selector(stopUpdate)];
    [newStepViews makeObjectsPerformSelector:@selector(startUpdate)];
    
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
    [self.view.layer setBackgroundColor:[NSColor windowBackgroundColor:active].CGColor];
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
