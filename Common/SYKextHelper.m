//
//  SYKextHelper.m
//  DigitalOust
//
//  Created by Stan Chevallier on 21/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYKextHelper.h"

@interface SYKextHelper ()
@property (nonatomic, assign) BOOL canceled;
@property (nonatomic, strong) NSArray *lastInvalidKexts;
@property (nonatomic, strong) NSDictionary *lastCheckedKexts;
@end

@implementation SYKextHelper

- (void)listInvalidKextsWithProgress:(void (^)(CGFloat))progressBlock
                          completion:(void (^)(NSArray *))completionBlock
{
    if ([[NSThread currentThread] isMainThread])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self listInvalidKextsWithProgress:progressBlock completion:completionBlock];
        });
        return;
    }
    
    self.canceled = NO;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:@"/System/Library/Extensions"];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:url
                                          includingPropertiesForKeys:@[NSURLNameKey,
                                                                       NSURLIsDirectoryKey,
                                                                       NSURLContentModificationDateKey]
                                                             options:0
                                                        errorHandler:^BOOL(NSURL *url, NSError *error)
    {
        if (error) {
            NSLog(@"[Error] %@ (%@)", error, url);
            return NO;
        }
        
        return YES;
    }];
    
    NSUInteger kextCount = 0;
    NSMutableDictionary *listing = [NSMutableDictionary dictionary];
    
    for (NSURL *fileURL in enumerator)
    {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];
        
        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        NSDate *modifDate;
        [fileURL getResourceValue:&modifDate forKey:NSURLContentModificationDateKey error:nil];
        
        if (![filename hasSuffix:@".kext"] || ![isDirectory boolValue])
            continue;
        
        ++kextCount;

        NSDate *lastModifDate = self.lastCheckedKexts[[fileURL path]];
        if (modifDate.timeIntervalSince1970 > lastModifDate.timeIntervalSince1970)
            [listing setObject:modifDate forKey:[fileURL path]];
    }
    
    NSMutableArray *invalidKexts = [NSMutableArray arrayWithArray:self.lastInvalidKexts];
    NSMutableDictionary *checkedKexts = [NSMutableDictionary dictionaryWithDictionary:self.lastCheckedKexts];
    
    for(NSUInteger i = 0; i < [listing allKeys].count; ++i)
    {
        if (self.canceled)
            break;
        
        NSString *kextPath = [listing allKeys][i];
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/codesign";
        task.arguments = @[@"--verify", @"--no-strict", kextPath];
        [task launch];
        [task waitUntilExit];
        
        [checkedKexts setObject:listing[kextPath] forKey:kextPath];
        if ([task terminationStatus] != 0)
            [invalidKexts addObject:kextPath];
        if (progressBlock)
            progressBlock((CGFloat)(self.lastCheckedKexts.count + i + 1) / (CGFloat)kextCount);
    }
    
    self.lastCheckedKexts = [checkedKexts copy];
    self.lastInvalidKexts = [invalidKexts copy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completionBlock)
            completionBlock([invalidKexts copy]);
    });
}

- (void)stopListingInvalidKexts
{
    self.canceled = YES;
}

@end
