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
@property (atomic, copy)    NSString            *identifier;
@property (atomic, weak)    id<SYCommsDelegate> delegate;
@property (atomic, strong)  NSMutableDictionary *completionBlocks;
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
        self.completionBlocks = [NSMutableDictionary dictionary];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                        NULL,
                                        SYCommsCallback,
                                        CFSTR("me.syan.DigitalOust"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}

- (void)callCompletionBlockForCommanID:(NSString *)commandID withError:(NSError *)error
{
    SYCommsCompletionBlock block = self.completionBlocks[commandID];
    if (block)
        block(error);
    [self.completionBlocks removeObjectForKey:commandID];
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
            [self.delegate comms:self receivedCommand:command commandID:content[@"cmdid"] arguments:content[@"args"]];
            break;
        }
        case SYCommsTypeError:
        {
            NSError *error = [NSKeyedUnarchiver unarchiveObjectWithData:content[@"error"]];
            [self callCompletionBlockForCommanID:content[@"cmdid"] withError:error];
            break;
        }
        case SYCommsTypeSuccess:
        {
            [self callCompletionBlockForCommanID:content[@"cmdid"] withError:nil];
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

- (void)sendCommand:(SYCommsCommand)command args:(NSDictionary *)args completion:(void (^)(NSError *))completion
{
    NSString *commandID = [[NSUUID UUID] UUIDString];
    if (completion)
        [self.completionBlocks setObject:[completion copy] forKey:commandID];
    
    [self sendMessage:@{@"type":@(SYCommsTypeCommand),
                        @"command":@(command),
                        @"cmdid":commandID,
                        @"args":(args ?: @{})}];
}

- (void)sendCompletionForCommandID:(NSString *)commandID error:(NSError *)error
{
    if (error)
        [self sendMessage:@{@"type":@(SYCommsTypeError),
                            @"cmdid":commandID,
                            @"error":[NSKeyedArchiver archivedDataWithRootObject:error]}];
    else
        [self sendMessage:@{@"type":@(SYCommsTypeSuccess),
                            @"cmdid":commandID}];
}

@end

