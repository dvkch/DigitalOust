//
//  SYNVRAMHelper.m
//  DigitalOust
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#include <stdio.h>
#include <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOKitKeys.h>
#include <CoreFoundation/CoreFoundation.h>
#include <err.h>
#include <mach/mach_error.h>
#include "SYNVRAMHelper.h"
#import "STPrivilegedTask.h"
#import "NSError+DigitalOust.h"

#ifndef NSAppKitVersionNumber10_8
#define NSAppKitVersionNumber10_8 1187
#endif

#ifndef NSAppKitVersionNumber10_9
#define NSAppKitVersionNumber10_9 1265
#endif

#ifndef NSAppKitVersionNumber10_10
#define NSAppKitVersionNumber10_10 1343
#endif


NSString * const SYNVRAMHelper_bootArgs_kextDevModeON  = @"kext-dev-mode=1";
NSString * const SYNVRAMHelper_bootArgs_kextDevModeOFF = @"kext-dev-mode=0";
NSString * const SYNVRAMHelper_bootArgs_rootlessON     = @"rootless=1";
NSString * const SYNVRAMHelper_bootArgs_rootlessOFF    = @"rootless=0";

@implementation SYNVRAMHelper

#pragma mark - General purpose methods

+ (NSError *)getNvramKitEntry:(NSError *(^)(io_registry_entry_t gOptionsRef))block
{
    kern_return_t       result;
    io_registry_entry_t gOptionsRef;
    mach_port_t         masterPort;
    
    result = IOMasterPort(bootstrap_port, &masterPort);
    if (result != KERN_SUCCESS) {
        return [NSError SYErrorIOKitWithMessage:
                [NSString stringWithFormat:NSLocalizedString(@"Error getting the IOMaster port: %s", nil),
                 mach_error_string(result)]];
    }
    
    gOptionsRef = IORegistryEntryFromPath(masterPort, "IODeviceTree:/options");
    if (gOptionsRef == 0) {
        return [NSError SYErrorIOKitWithMessage:NSLocalizedString(@"NVRAM is not supported on this system", nil)];
    }
    
    NSError *blockError = block(gOptionsRef);
    IOObjectRelease(gOptionsRef);
    
    return blockError;
}

+ (id)getNVRAMPropertyValue:(NSString *)name
{
    __block id value;
    NSError *error = [self getNvramKitEntry:^NSError *(io_registry_entry_t gOptionsRef)
    {
        CFTypeRef valueRef = IORegistryEntryCreateCFProperty(gOptionsRef, (__bridge CFStringRef)name, kCFAllocatorDefault, 0);
        if (valueRef == 0)
        {
            // everything went well, but the proprty doesnt exist
            return nil;
        }
        
        if(CFGetTypeID(valueRef) == CFDataGetTypeID())
        {
            value = [(__bridge NSData *)(valueRef) copy];
        }
        else if(CFGetTypeID(valueRef) == CFStringGetTypeID())
        {
            value = [(__bridge NSString *)(valueRef) copy];
        }
        else if(CFGetTypeID(valueRef) == CFNumberGetTypeID())
        {
            value = [(__bridge NSNumber *)(valueRef) copy];
        }
        else
        {
            value = [(__bridge id)(valueRef) copy];
        }
        
        CFRelease(valueRef);
        return nil;
    }];
    
    if(error)
        NSLog(@"Error while getting value for NVRAM: %@", [error localizedDescriptionSY]);
    
    return value;
}

+ (NSError *)setNVRAMProperty:(NSString *)name withValue:(id)value
{
    NSError *error = [self getNvramKitEntry:^NSError *(io_registry_entry_t gOptionsRef)
    {
        NSString *syncNowProperty = [NSString stringWithUTF8String:kIONVRAMSyncNowPropertyKey];
        NSString *deleteProperty = [NSString stringWithUTF8String:kIONVRAMDeletePropertyKey];
        
        kern_return_t result;
        if(value) // update value
            result = IORegistryEntrySetCFProperty(gOptionsRef, (__bridge CFStringRef)(name), (__bridge CFTypeRef)(value));
        else // delete property
            result = IORegistryEntrySetCFProperty(gOptionsRef, (__bridge CFStringRef)(deleteProperty), (__bridge CFStringRef)(name));
        
        if (result != KERN_SUCCESS)
            return [NSError SYErrorIOKitWithMessage:[NSString stringWithFormat:@"Error setting %@: %s", name, mach_error_string(result)]];
        
        result = IORegistryEntrySetCFProperty(gOptionsRef, (__bridge CFStringRef)(syncNowProperty), (__bridge CFStringRef)(name));
        if (result != KERN_SUCCESS)
            return [NSError SYErrorIOKitWithMessage:[NSString stringWithFormat:@"Error syncing %@: %s", name, mach_error_string(result)]];
        
        return nil;
    }];
    
    if(error)
        NSLog(@"Error while setting value for NVRAM: %@", [error localizedDescriptionSY]);
    
    return error;
}

#pragma mark - Boot args & Kext dev mode

+ (NSString *)bootArgs
{
    return [self getNVRAMPropertyValue:@"boot-args"];
}

+ (SYNVRAMBootArgStatus)bootArgStatusWithOnString:(NSString *)onString
                                        offString:(NSString *)offString
                                    systemDefault:(BOOL)systemDefault
                           ignoreIfAppKitLessThan:(double)appKitVersion
{
    if(NSAppKitVersionNumber < appKitVersion)
        return SYNVRAMBootArgStatusNotRequired;
    
    NSString *bootArgs = [self bootArgs];
    if(!bootArgs)
        return (systemDefault ? SYNVRAMBootArgStatusON : SYNVRAMBootArgStatusOFF);
    
    if([bootArgs rangeOfString:onString].location != NSNotFound)
        return SYNVRAMBootArgStatusON;
    
    if([bootArgs rangeOfString:offString].location != NSNotFound)
        return SYNVRAMBootArgStatusOFF;
    
    return (systemDefault ? SYNVRAMBootArgStatusON : SYNVRAMBootArgStatusOFF);
}

+ (SYNVRAMBootArgStatus)kextDevModeStatus
{
    return [self bootArgStatusWithOnString:SYNVRAMHelper_bootArgs_kextDevModeON
                                 offString:SYNVRAMHelper_bootArgs_kextDevModeOFF
                             systemDefault:NO
                    ignoreIfAppKitLessThan:NSAppKitVersionNumber10_10];
}

+ (SYNVRAMBootArgStatus)rootlessStatus
{
    return [self bootArgStatusWithOnString:SYNVRAMHelper_bootArgs_rootlessON
                                 offString:SYNVRAMHelper_bootArgs_rootlessOFF
                             systemDefault:YES
                    ignoreIfAppKitLessThan:1382];
}

+ (void)setBootArgEnabled:(BOOL)enabled
            systemDefault:(BOOL)systemDefault
                 onString:(NSString *)onString
                offString:(NSString *)offString
   ignoreIfAppKitLessThan:(double)appKitVersion
                    error:(NSError *__autoreleasing *)error
{
    SYNVRAMBootArgStatus status = [self bootArgStatusWithOnString:onString
                                                        offString:offString
                                                    systemDefault:systemDefault
                                           ignoreIfAppKitLessThan:appKitVersion];
    
    if (status == SYNVRAMBootArgStatusNotRequired)
        return;
    
    if ((status == SYNVRAMBootArgStatusOFF && !enabled) ||
        (status == SYNVRAMBootArgStatusON  &&  enabled))
        return;
    
    NSString *newBootArgs = [self bootArgs] ?: @"";
    
    newBootArgs = [newBootArgs stringByReplacingOccurrencesOfString:offString withString:@""];
    newBootArgs = [newBootArgs stringByReplacingOccurrencesOfString:onString  withString:@""];
    newBootArgs = [newBootArgs stringByAppendingFormat:@" %@", systemDefault == enabled ? @"" : (enabled ? onString : offString)];
    
    while([newBootArgs rangeOfString:@" " options:(NSAnchoredSearch)].location == 0)
        newBootArgs = [newBootArgs substringFromIndex:1];
    
    while([newBootArgs rangeOfString:@" " options:(NSAnchoredSearch | NSBackwardsSearch)].location == newBootArgs.length - 1)
        newBootArgs = [newBootArgs substringToIndex:newBootArgs.length-1];
    
    NSError *err = [self setNVRAMProperty:@"boot-args" withValue:(newBootArgs.length ? newBootArgs : nil)];
    
    if(error) *error = err;
}

+ (void)setKextDevModeEnabled:(BOOL)enabled error:(NSError *__autoreleasing *)error
{
    [self setBootArgEnabled:enabled
              systemDefault:NO
                   onString:SYNVRAMHelper_bootArgs_kextDevModeON
                  offString:SYNVRAMHelper_bootArgs_kextDevModeOFF
     ignoreIfAppKitLessThan:NSAppKitVersionNumber10_10
                      error:error];
}

+ (void)setRootlessEnabled:(BOOL)enabled error:(NSError *__autoreleasing *)error
{
    [self setBootArgEnabled:enabled
              systemDefault:YES
                   onString:SYNVRAMHelper_bootArgs_rootlessON
                  offString:SYNVRAMHelper_bootArgs_rootlessOFF
     ignoreIfAppKitLessThan:1382
                      error:error];
}

@end

