//
//  SYComms.h
//  DigitalOust
//
//  Created by Stanislas Chevallier on 11/06/15.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SYCommsCommandLog                   = 0,
    SYCommsCommandSetKextDevMode        = 1,
    SYCommsCommandSetRootless           = 2,
    SYCommsCommandPatchAppleHDA         = 3,
    SYCommsCommandRestoreAppleHDA       = 4,
    SYCommsCommandUpdateParentProcessID = 5,
} SYCommsCommand;

@class SYComms;

@protocol SYCommsDelegate <NSObject>
- (void)comms:(SYComms *)comms receivedCommand:(SYCommsCommand)command arguments:(NSDictionary *)arguments;
- (void)comms:(SYComms *)comms receivedSuccessForCommand:(SYCommsCommand)command;
- (void)comms:(SYComms *)comms receivedErrorForCommand:(SYCommsCommand)command error:(NSError *)error;
@end

@interface SYComms : NSObject

+ (SYComms *)shared;
- (void)setIdentifier:(NSString *)identifier delegate:(id<SYCommsDelegate>)delegate;

- (void)sendCommand:(SYCommsCommand)command args:(NSDictionary *)args;
- (void)sendSuccessForCommand:(SYCommsCommand)command;
- (void)sendError:(NSError *)error forCommand:(SYCommsCommand)command;

@end
