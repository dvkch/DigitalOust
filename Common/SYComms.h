//
//  SYComms.h
//  DigitalOust
//
//  Created by Stanislas Chevallier on 11/06/15.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SYCommsCommandLog                                   = 0,
    SYCommsCommandEnableKextDevMode                     = 1,
    SYCommsCommandDisableKextDevMode                    = 2,
    SYCommsCommandEnableRootless                        = 3,
    SYCommsCommandDisableRootless                       = 4,
    SYCommsCommandEnableKextDevModeAndDisableRootless   = 5,
    SYCommsCommandPatchAppleHDA                         = 6,
    SYCommsCommandRestoreAppleHDA                       = 7,
    SYCommsCommandUpdateParentProcessID                 = 8,
} SYCommsCommand;

@class SYComms;

@protocol SYCommsDelegate <NSObject>
- (void)comms:(SYComms *)comms
receivedCommand:(SYCommsCommand)command
    commandID:(NSString *)commandID
    arguments:(NSDictionary *)arguments;
@end

typedef void(^SYCommsCompletionBlock)(NSError *error);

@interface SYComms : NSObject

+ (SYComms *)shared;
- (void)setIdentifier:(NSString *)identifier delegate:(id<SYCommsDelegate>)delegate;

- (void)sendCommand:(SYCommsCommand)command args:(NSDictionary *)args completion:(SYCommsCompletionBlock)completion;
- (void)sendCompletionForCommandID:(NSString *)commandID error:(NSError *)error;

@end
