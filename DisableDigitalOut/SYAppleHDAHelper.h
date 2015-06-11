//
//  SYAppleHDAHelper.h
//  DisableDigitalOut
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SYAppleHDAHelper : NSObject

+ (void)applyPatchForLayout:(NSNumber *)layout block:(void(^)(NSString *output, NSError *error, BOOL completed))block;
+ (void)restoreOriginalFile:(void(^)(NSString *output, NSError *error, BOOL completed))block;
+ (BOOL)layoutIDSeemsSupported:(NSNumber *)layout details:(NSString **)details;
+ (BOOL)hasBackupFile;

// DEBUG
+ (void)inflateAllAndSaveToPath:(NSString *)path;
+ (void)listAllLayoutIDToPathRef;
+ (void)test;

@end
