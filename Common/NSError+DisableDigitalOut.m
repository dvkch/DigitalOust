//
//  NSError+DisableDigitalOut.m
//  DisableDigitalOut
//
//  Created by Stanislas Chevallier on 18/05/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import "NSError+DisableDigitalOut.h"

NSString * const SYErrorDomain    = @"SYErrorDomain_DisableDigitalOut";
NSString * const SYErrorAuthInfo  = @"SYErrorAuthInfo_DisableDigitalOut";
NSString * const SYErrorIOKitInfo = @"SYErrorIOKitInfo_DisableDigitalOut";

@implementation NSError (DisableDigitalOut)

- (NSString *)localizedDescriptionSY
{
    if([self isSYError])
    {
        NSString *m;
        switch ((SYErrorCode)self.code)
        {
            case SYErrorCodeNoInput:
                m = NSLocalizedString(@"Internal error", nil);
                return nil;
            case SYErrorCodeNotAuthorized:
                m = NSLocalizedString(@"Access denied", nil);
                break;
            case SYErrorCodeBackupFileAbsent:
                m = NSLocalizedString(@"Backup file missing", nil);
                break;
            case SYErrorCodeBackupFilePresent:
                m = NSLocalizedString(@"AppleHDA already patched, restore first", nil);
                break;
            case SYErrorCodeNoLayout:
                m = NSLocalizedString(@"Layout file missing", nil);
                break;
            case SYErrorCodeLayoutNotSupported:
                m = NSLocalizedString(@"Unsupported layout file", nil);
                break;
            case SYErrorCodeSoundCardNotSupported:
                m = NSLocalizedString(@"Unsupported sound card", nil);
                break;
            case SYErrorCodeNoDigitalOutInLayout:
                m = NSLocalizedString(@"Digital output not found in layout file", nil);
                break;
            case SYErrorCodeAuthCanceled:
                m = NSLocalizedString(@"Authorization request canceled", nil);
                break;
            case SYErrorCodeAuthDenied:
                m = NSLocalizedString(@"Access denied", nil);
                break;
            case SYErrorCodeAuthNoTool:
                m = NSLocalizedString(@"Path to the blessed tool is invalid", nil);
                break;
            case SYErrorCodeAuthToolError:
                m = NSLocalizedString(@"Tool returned an unknown error", nil);
                break;
            case SYErrorCodeIOKitError:
                m = self.userInfo[SYErrorIOKitInfo] ?: NSLocalizedString(@"Unknown IOKit error", nil);
                break;
            case SYErrorCodeAuthOther:
                m = [NSString stringWithFormat:NSLocalizedString(@"Cannot run blessed tool: %@", nil), self.userInfo[SYErrorAuthInfo]];
                break;
        }
        return m ?: [NSString stringWithFormat:NSLocalizedString(@"Unknown internal error: %d", nil), (int)self.code];
    }
    
    return [self localizedDescription];
}

- (BOOL)isSYError
{
    return [self.domain isEqualToString:SYErrorDomain];
}

- (BOOL)isSYError:(SYErrorCode)code
{
    return [self isSYError] && self.code == code;
}

- (NSError *)errorWithNewLocalizedDescription:(NSString *)newLocalizedDescription
{
    NSMutableDictionary *dic = self.userInfo ? [self.userInfo mutableCopy] : [NSMutableDictionary dictionary];
    [dic setObject:newLocalizedDescription forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:self.domain code:self.code userInfo:[dic copy]];
}

+ (NSError*)SYErrorWithCode:(SYErrorCode)code userInfo:(NSDictionary *)userInfo
{
    NSError *error = [self errorWithDomain:SYErrorDomain code:code userInfo:userInfo];
    return [error errorWithNewLocalizedDescription:[error localizedDescriptionSY]];
}

+ (NSError*)SYErrorAuthWithCode:(OSStatus)code
{
    NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Unknown error %d", nil), code];
    SYErrorCode errorCode = SYErrorCodeAuthOther;
    if(code == errAuthorizationInvalidSet) {
        errorString = NSLocalizedString(@"The authorization rights are invalid", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInvalidRef) {
        errorString = NSLocalizedString(@"The authorization reference is invalid", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInvalidTag) {
        errorString = NSLocalizedString(@"The authorization tag is invalid", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInvalidPointer) {
        errorString = NSLocalizedString(@"The returned authorization is invalid", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationDenied) {
        errorString = NSLocalizedString(@"The authorization was denied", nil);
        errorCode   = SYErrorCodeAuthDenied;
    }
    if(code == errAuthorizationCanceled) {
        errorString = NSLocalizedString(@"The authorization was cancelled by the user", nil);
        errorCode   = SYErrorCodeAuthCanceled;
    }
    if(code == errAuthorizationInteractionNotAllowed) {
        errorString = NSLocalizedString(@"The authorization was denied since no user interaction was possible", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInternal) {
        errorString = NSLocalizedString(@"Unable to obtain authorization for this operation", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationExternalizeNotAllowed) {
        errorString = NSLocalizedString(@"The authorization is not allowed to be converted to an external format", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInternalizeNotAllowed) {
        errorString = NSLocalizedString(@"The authorization is not allowed to be created from an external format", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationToolExecuteFailure) {
        errorString = NSLocalizedString(@"The specified program could not be executed", nil);
        errorCode   = SYErrorCodeAuthNoTool;
    }
    if(code == errAuthorizationToolEnvironmentError) {
        errorString = NSLocalizedString(@"An invalid status was returned during execution of a privileged tool", nil);
        errorCode   = SYErrorCodeAuthToolError;
    }
    if(code == errAuthorizationBadAddress) {
        errorString = NSLocalizedString(@"The requested socket address is invalid (must be 0-1023 inclusive)", nil);
        errorCode   = SYErrorCodeAuthOther;
    }
    
    return [self SYErrorWithCode:errorCode userInfo:@{SYErrorAuthInfo:errorString}];
}

+ (NSError *)SYErrorIOKitWithMessage:(NSString *)message
{
    return [self SYErrorWithCode:SYErrorCodeIOKitError userInfo:(message ? @{SYErrorIOKitInfo:message} : nil)];
}

- (BOOL)userShouldntSeeRealErrorMessage
{
    return ([self isSYError]) ? NO : YES;
}

@end
