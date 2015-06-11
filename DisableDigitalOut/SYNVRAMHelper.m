/*
 * Copyright (c) 2000-2005 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.1 (the
 * "License").  You may not use this file except in compliance with the
 * License.  Please obtain a copy of the License at
 * http://www.apple.com/publicsource and read it before using this file.
 *
 * This Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */
/*
 cc -o nvram nvram.c -framework CoreFoundation -framework IOKit -Wall
 */

#include <stdio.h>
#include <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOKitKeys.h>
#include <CoreFoundation/CoreFoundation.h>
#include <err.h>
#include <mach/mach_error.h>
#include "SYNVRAMHelper.h"
#import "STPrivilegedTask.h"
#import "NSError+DisableDigitalOut.h"

NSString * const SYNVRAMHelper_bootArgs_kextDevMode = @"kext-dev-mode=1";

@implementation SYNVRAMHelper

#pragma mark - General purpose methods

+ (NSError *)getNvramKitEntry:(NSError *(^)(io_registry_entry_t gOptionsRef))block
{
    kern_return_t       result;
    io_registry_entry_t gOptionsRef;
    mach_port_t         masterPort;
    
    result = IOMasterPort(bootstrap_port, &masterPort);
    if (result != KERN_SUCCESS) {
        return [NSError SYErrorIOKitWithMessage:[NSString stringWithFormat:@"Error getting the IOMaster port: %s", mach_error_string(result)]];
    }
    
    gOptionsRef = IORegistryEntryFromPath(masterPort, "IODeviceTree:/options");
    if (gOptionsRef == 0) {
        return [NSError SYErrorIOKitWithMessage:@"NVRAM is not supported on this system"];
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

+ (void)setNVRAMProperty:(NSString *)name withValue:(id)value
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
}

#pragma mark - Boot args & Kext dev mode

+ (NSString *)bootArgs
{
    return [self getNVRAMPropertyValue:@"boot-args"];
}

+ (BOOL)kextDevModeEnabled
{
    NSString *bootArgs = [self bootArgs];
    if(!bootArgs)
        return NO;

    return [bootArgs rangeOfString:SYNVRAMHelper_bootArgs_kextDevMode].location != NSNotFound;
}

+ (void)setKextDevModeEnabled:(BOOL)enabled error:(NSString *__autoreleasing *)error
{
    if(enabled == [self kextDevModeEnabled])
        return;
    
    NSString *bootArgs = [self bootArgs] ?: @"";
    NSString *newBootArgs;
    if(enabled)
    {
        newBootArgs = [bootArgs stringByAppendingFormat:@" %@", SYNVRAMHelper_bootArgs_kextDevMode];
    }
    else
    {
        newBootArgs = [bootArgs stringByReplacingOccurrencesOfString:SYNVRAMHelper_bootArgs_kextDevMode withString:@""];
    }
    
    while([newBootArgs rangeOfString:@" " options:(NSAnchoredSearch)].location == 0)
        newBootArgs = [newBootArgs substringFromIndex:1];
    
    while([newBootArgs rangeOfString:@" " options:(NSAnchoredSearch | NSBackwardsSearch)].location == newBootArgs.length - 1)
        newBootArgs = [newBootArgs substringToIndex:newBootArgs.length-1];
    
    [self setNVRAMProperty:@"boot-args" withValue:(newBootArgs.length ? newBootArgs : nil)];
}

@end
