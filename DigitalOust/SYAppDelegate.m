//
//  SYAppDelegate.m
//  DigitalOust
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import "SYAppDelegate.h"
#import "SYViewController.h"

@interface SYAppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (strong) SYViewController *viewController;
@end

@implementation SYAppDelegate

+ (instancetype)obtain
{
    return (SYAppDelegate *)[NSApp delegate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSApp activateIgnoringOtherApps:YES];
    self.viewController = [[SYViewController alloc] init];
    [self.window setContentViewController:self.viewController];
    [self.window.contentView layoutSubtreeIfNeeded];
    [self.window setFrame:(NSRect){{0, 0}, self.window.contentView.frame.size} display:YES];
    [self.window setMovableByWindowBackground:YES];
    [self.window center];
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[NSColor clearColor]];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(windowDidChangeFocus:) name:NSWindowDidBecomeKeyNotification object:self.window];
    [nc addObserver:self selector:@selector(windowDidChangeFocus:) name:NSWindowDidResignKeyNotification object:self.window];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)windowDidChangeFocus:(NSNotification *)notification
{
    if (self.windowFocusChanged)
        self.windowFocusChanged();
}

@end
