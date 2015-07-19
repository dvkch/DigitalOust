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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSApp activateIgnoringOtherApps:YES];
    self.viewController = [[SYViewController alloc] init];
    [self.window setContentViewController:self.viewController];
    [self.window.contentView layoutSubtreeIfNeeded];
    [self.window setFrame:(NSRect){{0, 0}, self.window.contentView.frame.size} display:YES];
    [self.window center];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
