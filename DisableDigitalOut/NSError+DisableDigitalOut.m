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
                m = @"Problèmes interne";
                return nil;
            case SYErrorCodeNotAuthorized:
                m = @"Accès refusé";
                break;
            case SYErrorCodeBackupFileAbsent:
                m = @"Fichier de sauvegarde absent";
                break;
            case SYErrorCodeBackupFilePresent:
                m = @"AppleHDA déjà modifié, restaurer d'abord";
                break;
            case SYErrorCodeNoLayout:
                m = @"Fichier layout introuvable";
                break;
            case SYErrorCodeLayoutNotSupported:
                m = @"Fichier layout non supporté";
                break;
            case SYErrorCodeSoundCardNotSupported:
                m = @"Carte son non supportée";
                break;
            case SYErrorCodeNoDigitalOutInLayout:
                m = @"Sortie audio digitale absente to fichier layout";
                break;
            case SYErrorCodeAuthCanceled:
                m = @"Authorization canceled";
                break;
            case SYErrorCodeAuthDenied:
                m = @"Authorization denied";
                break;
            case SYErrorCodeAuthNoTool:
                m = @"Path to the blessed tool is invalid";
                break;
            case SYErrorCodeAuthToolError:
                m = @"Tool returned an unknown error";
                break;
            case SYErrorCodeIOKitError:
                m = self.userInfo[SYErrorIOKitInfo] ?: @"Unknown IOKit error";
                break;
            case SYErrorCodeAuthOther:
                m = [NSString stringWithFormat:@"Cannot run blessed tool: %@", self.userInfo[SYErrorAuthInfo]];
                break;
        }
        return m ?: [NSString stringWithFormat:@"Erreur DisableDigitalOut inconnue: %d", (int)self.code];
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
    NSString *errorString = [NSString stringWithFormat:@"Unknown error %d", code];
    SYErrorCode errorCode = SYErrorCodeAuthOther;
    if(code == errAuthorizationInvalidSet) {
        errorString = @"The authorization rights are invalid";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInvalidRef) {
        errorString = @"The authorization reference is invalid";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInvalidTag) {
        errorString = @"The authorization tag is invalid";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInvalidPointer) {
        errorString = @"The returned authorization is invalid";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationDenied) {
        errorString = @"The authorization was denied";
        errorCode   = SYErrorCodeAuthDenied;
    }
    if(code == errAuthorizationCanceled) {
        errorString = @"The authorization was cancelled by the user";
        errorCode   = SYErrorCodeAuthCanceled;
    }
    if(code == errAuthorizationInteractionNotAllowed) {
        errorString = @"The authorization was denied since no user interaction was possible";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInternal) {
        errorString = @"Unable to obtain authorization for this operation";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationExternalizeNotAllowed) {
        errorString = @"The authorization is not allowed to be converted to an external format";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationInternalizeNotAllowed) {
        errorString = @"The authorization is not allowed to be created from an external format";
        errorCode   = SYErrorCodeAuthOther;
    }
    if(code == errAuthorizationToolExecuteFailure) {
        errorString = @"The specified program could not be executed";
        errorCode   = SYErrorCodeAuthNoTool;
    }
    if(code == errAuthorizationToolEnvironmentError) {
        errorString = @"An invalid status was returned during execution of a privileged tool";
        errorCode   = SYErrorCodeAuthToolError;
    }
    if(code == errAuthorizationBadAddress) {
        errorString = @"The requested socket address is invalid (must be 0-1023 inclusive)";
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
