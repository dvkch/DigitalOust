//
//  SYComms.m
//  DigitalOust
//
//  Created by Stanislas Chevallier on 11/06/15.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYComms.h"

typedef enum : NSUInteger {
    SYCommsTypeCommand,
    SYCommsTypeSuccess,
    SYCommsTypeError,
} SYCommsType;

@interface SYComms ()
@property (atomic, copy) NSString *identifier;
@property (atomic, weak) id<SYCommsDelegate> delegate;
- (void)receivedMessage:(NSDictionary *)message;
@end

static void SYCommsCallback(CFNotificationCenterRef center,
                            void *observer,
                            CFStringRef name,
                            const void *object,
                            CFDictionaryRef userInfo)
{
    [[SYComms shared] receivedMessage:[(__bridge NSDictionary *)(userInfo) copy]];
}

@implementation SYComms

+ (instancetype)shared
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                        NULL,
                                        SYCommsCallback,
                                        CFSTR("me.syan.DigitalOust"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}

- (void)receivedMessage:(NSDictionary *)message
{
    if(!self.identifier) {
        NSLog(@"No identifier registered!");
        return;
    }
    
    NSString *messageSourceIdentifier = message[@"identifier"];
    if([self.identifier isEqualToString:messageSourceIdentifier])
        return;
    
    NSDictionary *content = message[@"content"];
    
    switch ((SYCommsType)[content[@"type"] integerValue]) {
        case SYCommsTypeCommand:
        {
            SYCommsCommand command = [content[@"command"] integerValue];
            [self.delegate comms:self receivedCommand:command arguments:content[@"args"]];
            break;
        }
        case SYCommsTypeError:
        {
            NSError *error = [NSKeyedUnarchiver unarchiveObjectWithData:content[@"error"]];
            SYCommsCommand command = [content[@"command"] integerValue];
            [self.delegate comms:self receivedErrorForCommand:command error:error];
            break;
        }
        case SYCommsTypeSuccess:
        {
            SYCommsCommand command = [content[@"command"] integerValue];
            [self.delegate comms:self receivedSuccessForCommand:command];
            break;
        }
    }
}

- (void)sendMessage:(NSDictionary *)message
{
    if(!self.identifier) {
        NSLog(@"No identifier registered!");
        return;
    }
    
    if(!message) {
        NSLog(@"No content");
        return;
    }
    
    NSDictionary *dic = @{@"identifier":self.identifier,@"content":message};
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
                                         CFSTR("me.syan.DigitalOust"),
                                         NULL,
                                         (CFDictionaryRef)dic,
                                         true);
}

#pragma mark - Public methods

- (void)setIdentifier:(NSString *)identifier delegate:(id<SYCommsDelegate>)delegate
{
    self.identifier = identifier;
    self.delegate   = delegate;
}

- (void)sendCommand:(SYCommsCommand)command args:(NSDictionary *)args
{
    [self sendMessage:@{@"type":@(SYCommsTypeCommand), @"command":@(command), @"args":(args ?: @{})}];
}

- (void)sendSuccessForCommand:(SYCommsCommand)command
{
    [self sendMessage:@{@"type":@(SYCommsTypeSuccess), @"command":@(command)}];
}

- (void)sendError:(NSError *)error forCommand:(SYCommsCommand)command
{
    [self sendMessage:@{@"type":@(SYCommsTypeError), @"command":@(command), @"error":[NSKeyedArchiver archivedDataWithRootObject:error]}];
}

@end

