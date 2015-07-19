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

- (void)comms:(SYComms *)comms receivedCommand:(SYCommsCommand)command arguments:(NSDictionary *)arguments
{
    if(command == SYCommsCommandSetKextDevMode)
    {
        NSError *error;
        [SYNVRAMHelper setKextDevModeEnabled:[arguments[@"enabled"] boolValue] error:&error];
        if(error)
            [[SYComms shared] sendError:error forCommand:command];
        else
            [[SYComms shared] sendSuccessForCommand:command];
    }
    else if(command == SYCommsCommandSetRootless)
    {
        NSError *error;
        [SYNVRAMHelper setRootlessEnabled:[arguments[@"enabled"] boolValue] error:&error];
        if(error)
            [[SYComms shared] sendError:error forCommand:command];
        else
            [[SYComms shared] sendSuccessForCommand:command];
    }
    else if(command == SYCommsCommandRestoreAppleHDA)
    {
        [SYAppleHDAHelper restoreOriginalFile:^(NSString *output, NSError *error, BOOL completed) {
            if(!completed)
                [[SYComms shared] sendCommand:SYCommsCommandLog args:@{@"log":output}];
            else if(error)
                [[SYComms shared] sendError:error forCommand:command];
            else
                [[SYComms shared] sendSuccessForCommand:command];
        }];
    }
    else if (command == SYCommsCommandPatchAppleHDA)
    {
        NSNumber *layoutID = arguments[@"layoutid"];
        [SYAppleHDAHelper applyPatchForLayout:layoutID block:^(NSString *output, NSError *error, BOOL completed) {
            if(!completed)
                [[SYComms shared] sendCommand:SYCommsCommandLog args:@{@"log":output}];
            else if(error)
                [[SYComms shared] sendError:error forCommand:command];
            else
                [[SYComms shared] sendSuccessForCommand:command];
        }];
    }
    else if (command == SYCommsCommandUpdateParentProcessID)
    {
        appPID = arguments[@"pid"];
        [[SYComms shared] sendSuccessForCommand:SYCommsCommandUpdateParentProcessID];
    }
}

- (void)comms:(SYComms *)comms receivedSuccessForCommand:(SYCommsCommand)command
{
    
}

- (void)comms:(SYComms *)comms receivedErrorForCommand:(SYCommsCommand)command error:(NSError *)error
{
    
}

@end

