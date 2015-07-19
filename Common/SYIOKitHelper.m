//
//  SYIOKitHelper.m
//  DigitalOust
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import "SYIOKitHelper.h"
#import "SYAppDelegate.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/audio/IOAudioDefines.h>
#include <IOKit/audio/IOAudioLib.h>
#include <IOKit/audio/IOAudioTypes.h>


@implementation SYIOKitHelper

+ (NSArray *)listAudioModelIDs
{
    NSMutableSet *modelIDs = [NSMutableSet set];
    
    // List audio devices
    io_iterator_t intfIterator;
    {
        CFMutableDictionaryRef matchingDict;
        CFMutableDictionaryRef propertyMatchDict;
        
        matchingDict = IOServiceMatching(kIOAudioDeviceClassName);
        if (NULL == matchingDict) {
            printf("IOServiceMatching returned a NULL dictionary.\n");
            return nil;
        }
        
        propertyMatchDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                      &kCFTypeDictionaryKeyCallBacks,
                                                      &kCFTypeDictionaryValueCallBacks);
        
        if (NULL == propertyMatchDict) {
            printf("CFDictionaryCreateMutable returned a NULL dictionary.\n");
            return nil;
        }
        
        CFDictionarySetValue(propertyMatchDict, CFSTR(kIOClassKey), CFSTR("AppleHDADriver"));
        CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
        CFRelease(propertyMatchDict);
        
        // IOServiceGetMatchingServices retains the returned iterator, so release the iterator when we're done with it.
        // IOServiceGetMatchingServices also consumes a reference on the matching dictionary so we don't need to release
        // the dictionary explicitly.
        kern_return_t kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &intfIterator);
        if (KERN_SUCCESS != kernResult) {
            printf("IOServiceGetMatchingServices returned 0x%08x\n", kernResult);
            return nil;
        }
    }
    
    // For each device find the modelID which contains the layout it uses
    io_object_t intfService;
    while ((intfService = IOIteratorNext(intfIterator)))
    {
        CFStringRef	ModelIDString;
        ModelIDString = IORegistryEntryCreateCFProperty(intfService,
                                                        CFSTR(kIOAudioDeviceModelIDKey),
                                                        kCFAllocatorDefault,
                                                        0);
        
        if (ModelIDString) {
            [modelIDs addObject:(__bridge NSString *)ModelIDString];
            CFRelease(ModelIDString);
        }
        
        IOObjectRelease(intfService);
    }
    IOObjectRelease(intfIterator);
    
    // return unique model IDs
    return [modelIDs allObjects];
}

@end

