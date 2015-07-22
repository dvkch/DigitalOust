//
//  SYKextHelper.m
//  DigitalOust
//
//  Created by Stan Chevallier on 21/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYKextHelper.h"

@implementation SYKextHelper

+ (void)listInvalidKextsWithProgress:(void (^)(CGFloat))progressBlock
                          completion:(void (^)(NSArray *))completionBlock
{
    if ([[NSThread currentThread] isMainThread])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self listInvalidKextsWithProgress:progressBlock completion:completionBlock];
        });
        return;
    }
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:@"/System/Library/Extensions"];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:url
                                          includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error)
    {
        if (error) {
            NSLog(@"[Error] %@ (%@)", error, url);
            return NO;
        }
        
        return YES;
    }];
    
    NSMutableArray *kextsURLs = [NSMutableArray array];
    for (NSURL *fileURL in enumerator)
    {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];
        
        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        if ([filename hasSuffix:@".kext"] && [isDirectory boolValue])
            [kextsURLs addObject:fileURL];
    }
    
    NSMutableArray *invalidKexts = [NSMutableArray array];
    for(NSUInteger i = 0; i < kextsURLs.count; ++i)
    {
        NSURL *kextURL = kextsURLs[i];
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/codesign";
        task.arguments = @[@"--verify", @"--no-strict", [kextURL path]];
        [task launch];
        [task waitUntilExit];
        if ([task terminationStatus] != 0)
            [invalidKexts addObject:[kextURL path]];
        if (progressBlock)
            progressBlock((CGFloat)([kextsURLs indexOfObject:kextURL] + 1) / (CGFloat)[kextsURLs count]);
    }
    if (completionBlock)
        completionBlock([invalidKexts copy]);
}

@end
