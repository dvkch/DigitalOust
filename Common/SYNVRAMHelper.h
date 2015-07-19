//
//  SYNVRAMHelper.h
//  DisableDigitalOut
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SYNVRAMBootArgStatusON,
    SYNVRAMBootArgStatusOFF,
    SYNVRAMBootArgStatusNotRequired,
} SYNVRAMBootArgStatus;

@interface SYNVRAMHelper : NSObject

+ (SYNVRAMBootArgStatus)kextDevModeStatus;
+ (SYNVRAMBootArgStatus)rootlessStatus;

+ (void)setKextDevModeEnabled:(BOOL)enabled error:(NSError **)error;
+ (void)setRootlessEnabled:(BOOL)enabled error:(NSError **)error;

@end
