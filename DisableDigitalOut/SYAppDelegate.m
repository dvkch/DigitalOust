//
//  SYAppDelegate.m
//  DisableDigitalOut
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import "SYAppDelegate.h"
#import "SYIOKitHelper.h"
#import "SYAppleHDAHelper.h"
#import "SYViewController.h"
#import "STPrivilegedTask.h"
#import "NSError+DisableDigitalOut.h"

@interface SYAppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (strong) SYViewController *viewController;
@property (assign) AuthorizationRef authRef;
@end

@implementation SYAppDelegate

+ (SYAppDelegate *)obtain
{
    return (SYAppDelegate *)[NSApp delegate];
}

+ (void)log:(NSString *)format, ...
{
    va_list list;
    va_start(list, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:list];
    va_end(list);
    [[self obtain].viewController addLogMessage:message];
}

- (BOOL)appRunningAsRoot
{
    return geteuid() == 0;
}

- (NSError *)restartAsRoot
{
    STPrivilegedTask *task = [[STPrivilegedTask alloc] initWithLaunchPath:[[NSBundle mainBundle] executablePath]];
    OSStatus oserror = [task launch];
    
    if(oserror != errAuthorizationSuccess)
        return [NSError SYErrorAuthWithCode:oserror];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName:NSApplicationWillTerminateNotification
                                 object:NSApp];
    
    exit(0);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp activateIgnoringOtherApps:YES];
    
    NSError *runAsRootError;
    if(![self appRunningAsRoot])
        runAsRootError = [self restartAsRoot];
    
    self.viewController = [[SYViewController alloc] initWithNibName:@"SYViewController" bundle:nil];
    [self.viewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [self.window.contentView addSubview:self.viewController.view];
    self.viewController.view.frame = ((NSView*)self.window.contentView).bounds;
    
    if(runAsRootError)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Couldn't restart app with admin priviledges"];
            [alert setInformativeText:[runAsRootError localizedDescriptionSY]];
            [alert addButtonWithTitle:@"OK"];
            [alert beginSheetModalForWindow:self.window completionHandler:nil];
        });
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
