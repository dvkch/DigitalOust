//
//  SYNVRAMHelper.h
//  DisableDigitalOut
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SYNVRAMHelper : NSObject

+ (BOOL)kextDevModeEnabled;
+ (void)setKextDevModeEnabled:(BOOL)enabled error:(NSString **)error;

@end
