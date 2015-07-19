//
//  NSError+DigitalOust.h
//  DigitalOust
//
//  Created by Stanislas Chevallier on 18/05/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSInteger {
    SYErrorCodeNoInput,
    SYErrorCodeNotAuthorized,
    SYErrorCodeBackupFilePresent,
    SYErrorCodeBackupFileAbsent,
    SYErrorCodeNoLayout,
    SYErrorCodeLayoutNotSupported,
    SYErrorCodeNoDigitalOutInLayout,
    SYErrorCodeSoundCardNotSupported,
    SYErrorCodeIOKitError,

    SYErrorCodeAuthDenied,
    SYErrorCodeAuthCanceled,
    SYErrorCodeAuthToolError,
    SYErrorCodeAuthNoTool,
    SYErrorCodeAuthOther,
} SYErrorCode;

extern NSString * const SYErrorDomain;
extern NSString * const SYErrorAuthInfo;
extern NSString * const SYErrorIOKitInfo;

@interface NSError (DigitalOust)

- (NSString *)localizedDescriptionSY;
- (BOOL)isSYError;
- (BOOL)isSYError:(SYErrorCode)code;

+ (NSError *)SYErrorWithCode:(SYErrorCode)code userInfo:(NSDictionary*)userInfo;
+ (NSError *)SYErrorAuthWithCode:(OSStatus)code;
+ (NSError *)SYErrorIOKitWithMessage:(NSString *)message;
@end
