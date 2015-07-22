//
//  main.m
//  DigitalOustHelper
//
//  Created by Stanislas Chevallier on 11/06/15.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYComms.h"
#import "SYAppleHDAHelper.h"
#import "SYIOKitHelper.h"
#import "SYNVRAMHelper.h"
#import "NSError+DigitalOust.h"

@interface SYAgentCommsReceiver : NSObject <SYCommsDelegate>
@end

static NSNumber *appPID = nil;
static SYAgentCommsReceiver *receiver = nil;

void exitIfMainAppReturned()
{
    BOOL canExit = false;
    if([appPID intValue])
    {
        int res = kill([appPID intValue], 0);
        canExit = (res != 0);
    }
    
    if(!canExit)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exitIfMainAppReturned();
        });
    }
    else
    {
        exit(0);
    }
}

int main(int argc, const char * argv[])
{
    // tell the main process our PID, cuz you know, like why not
    printf("%d\n", getpid());
    
    @autoreleasepool
    {
        receiver = [[SYAgentCommsReceiver alloc] init];
        [[SYComms shared] setIdentifier:@"agent" delegate:receiver];
        exitIfMainAppReturned();
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}

@implementation SYAgentCommsReceiver

- (void)comms:(SYComms *)comms
receivedCommand:(SYCommsCommand)command
    commandID:(NSString *)commandID
    arguments:(NSDictionary *)arguments
{
    if(command == SYCommsCommandEnableKextDevModeAndDisableRootless)
    {
        NSError *error;
        [SYNVRAMHelper setKextDevModeEnabled:YES error:&error];
        if (!error)
            [SYNVRAMHelper setRootlessEnabled:NO error:&error];
        
        [[SYComms shared] sendCompletionForCommandID:commandID error:error];
    }
    else if(command == SYCommsCommandEnableKextDevMode || command == SYCommsCommandDisableKextDevMode)
    {
        NSError *error;
        [SYNVRAMHelper setKextDevModeEnabled:(command == SYCommsCommandEnableKextDevMode) error:&error];
        [[SYComms shared] sendCompletionForCommandID:commandID error:error];
    }
    else if(command == SYCommsCommandEnableRootless || command == SYCommsCommandDisableRootless)
    {
        NSError *error;
        [SYNVRAMHelper setRootlessEnabled:(command == SYCommsCommandEnableRootless) error:&error];
        [[SYComms shared] sendCompletionForCommandID:commandID error:error];
    }
    else if(command == SYCommsCommandRestoreAppleHDA)
    {
        [SYAppleHDAHelper restoreOriginalFile:^(NSString *output, NSError *error, BOOL completed) {
            if(!completed)
                [[SYComms shared] sendCommand:SYCommsCommandLog args:@{@"log":output} completion:nil];
            else
                [[SYComms shared] sendCompletionForCommandID:commandID error:error];
        }];
    }
    else if (command == SYCommsCommandPatchAppleHDA)
    {
        NSNumber *layoutID = arguments[@"layoutid"];
        [SYAppleHDAHelper applyPatchForLayout:layoutID block:^(NSString *output, NSError *error, BOOL completed) {
            if(!completed)
                [[SYComms shared] sendCommand:SYCommsCommandLog args:@{@"log":output} completion:nil];
            else
                [[SYComms shared] sendCompletionForCommandID:commandID error:error];
        }];
    }
    else if (command == SYCommsCommandUpdateParentProcessID)
    {
        appPID = arguments[@"pid"];
        [[SYComms shared] sendCompletionForCommandID:commandID error:nil];
    }
}

@end

