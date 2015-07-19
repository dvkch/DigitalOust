//
//  SYAppleHDAHelper.m
//  DigitalOust
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import "SYAppleHDAHelper.h"
#import "NSData+CocoaGitCompression.h"
#import "NSError+DigitalOust.h"
#import "SYAppDelegate.h"

NSString * const SYAppleHDA_PlatformFile        = @"Platforms.xml.zlib";
NSString * const SYAppleHDA_PlatformFileBackup  = @"Platforms.xml.zlib_save";

@implementation SYAppleHDAHelper

#pragma mark - Paths

+ (NSString *)appleHDAKextPath
{
    return @"/System/Library/Extensions/AppleHDA.kext";
}

+ (NSString *)appleHDAPathForFile:(NSString *)file
{
    NSString *sle = @"/System/Library/Extensions/AppleHDA.kext/Contents/Resources/";
    if(!file)
        return sle;
    return [sle stringByAppendingPathComponent:file];
}

+ (NSDictionary *)dicForFile:(NSString *)file
{
    if(!file)
        return nil;
    
    NSData *compressedLayout = [NSData dataWithContentsOfFile:[self appleHDAPathForFile:file]];
    NSData *inflatedLayout = [compressedLayout zlibInflate];
    
    NSString *layoutAsString = [[NSString alloc] initWithData:inflatedLayout encoding:NSUTF8StringEncoding];
    NSDictionary *layoutAsDic = [NSPropertyListSerialization
                                 propertyListWithData:[layoutAsString dataUsingEncoding:NSUTF8StringEncoding]
                                 options:kNilOptions
                                 format:NULL
                                 error:NULL];
    
    return layoutAsDic;
}

+ (NSError *)saveDic:(NSDictionary *)dic forFile:(NSString *)file
{
    if(!file || !dic)
        return [NSError SYErrorWithCode:SYErrorCodeNoInput userInfo:nil];
    
    NSError *error;
    NSData *layout = [NSPropertyListSerialization dataWithPropertyList:dic format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:&error];
    if(error) return error;
    
    NSData *layoutDeflated = [layout zlibDeflate];
    [layoutDeflated writeToFile:[self appleHDAPathForFile:file] options:NSDataWritingAtomic error:&error];
    if(error) return error;
    
    [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions:@0644,
                                                    NSFileOwnerAccountName:@"root",
                                                    NSFileGroupOwnerAccountName:@"wheel"}
                                     ofItemAtPath:[self appleHDAPathForFile:file]
                                            error:&error];
    return error;
}

#pragma mark - Dictionaries

+ (NSDictionary *)dicForPlatforms:(BOOL)useBackupFile
{
    return [self dicForFile:(useBackupFile ? SYAppleHDA_PlatformFileBackup : SYAppleHDA_PlatformFile)];
}

+ (NSDictionary *)dicForLayout:(NSNumber *)layout
{
    return [self dicForFile:[NSString stringWithFormat:@"layout%d.xml.zlib", [layout intValue]]];
}

+ (NSNumber *)dicIndexForPathIDInPlatforms:(NSNumber *)pathID useBackupFile:(BOOL)useBackupFile
{
    NSDictionary *platforms = [self dicForPlatforms:useBackupFile];
    NSMutableArray *paths = [[platforms objectForKey:@"PathMaps"] mutableCopy];
    for(NSUInteger i = 0; i < [paths count]; ++i)
    {
        NSDictionary *path = paths[i];
        if([path[@"PathMapID"] isEqualTo:pathID])
        {
            return @(i);
        }
    }
    
    return nil;
}

+ (NSDictionary *)dicForPathIDInPlatforms:(NSNumber *)pathID useBackupFile:(BOOL)useBackupFile
{
    NSDictionary *platforms = [self dicForPlatforms:useBackupFile];
    NSMutableArray *paths = [[platforms objectForKey:@"PathMaps"] mutableCopy];
    for(NSDictionary *path in paths)
    {
        if([path[@"PathMapID"] isEqualTo:pathID])
        {
            //NSLog(@"Found item: %d ins, %d outs", (int)[path[@"PathMap"][0] count], (int)[path[@"PathMap"][1] count]);
            return path;
        }
    }
    
    return nil;
}

#pragma mark - Layouts

+ (NSArray *)pathIDsForLayout:(NSNumber *)layout
{
    if(!layout)
        return nil;
    
    NSDictionary *dic = [self dicForLayout:layout];
    if(!dic)
        return nil;
    
    NSMutableArray *ids = [NSMutableArray array];
    
    NSArray *items = dic[@"PathMapRef"];
    for(NSDictionary *item in items)
    {
        [ids addObject:item[@"PathMapID"]];
    }
    return [ids copy];
}

+ (NSNumber *)digitalOutIndexInLayout:(NSNumber *)layout
{
    if(!layout)
        return nil;
    
    NSDictionary *dic = [self dicForLayout:layout];
    if(!dic)
        return nil;
    
    NSArray *outputs = dic[@"PathMapRef"][0][@"Outputs"];
    NSUInteger index = [outputs indexOfObject:@"SPDIFOut"];
    
    return index == NSNotFound ? nil : @(index);
}

+ (NSNumber *)numberOfOutputsInLayout:(NSNumber *)layout
{
    if(!layout)
        return nil;
    
    NSDictionary *dic = [self dicForLayout:layout];
    if(!dic)
        return nil;
    
    NSArray *outputs = dic[@"PathMapRef"][0][@"Outputs"];
    return outputs ? @([outputs count]) : nil;
}

#pragma mark - Platforms

+ (NSNumber *)numberOfRootsForPathIDInPlaftorms:(NSNumber *)pathID useBackupFile:(BOOL)useBackupFile
{
    if(!pathID)
        return nil;
    
    NSDictionary *dic = [self dicForPathIDInPlatforms:pathID useBackupFile:useBackupFile];
    if(!dic)
        return nil;
    
    NSArray *items = dic[@"PathMap"];
    return items ? @([items count]) : nil;
}

+ (NSNumber *)numberOfOutputsForPathIDInPlaftorms:(NSNumber *)pathID useBackupFile:(BOOL)useBackupFile
{
    if(!pathID)
        return nil;
    
    NSDictionary *dic = [self dicForPathIDInPlatforms:pathID useBackupFile:useBackupFile];
    if(!dic)
        return nil;
    
    NSArray *items = dic[@"PathMap"];
    
    // When there are more items i don't know to what they correspond
    if([items count] == 2)
        return @([items[1] count]);
    
    return nil;
}

#pragma mark - Patch requirements

+ (BOOL)hasBackupFile
{
    NSString *path = [self appleHDAPathForFile:SYAppleHDA_PlatformFileBackup];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)layoutIDSeemsSupported:(NSNumber *)layout useBackupFileIfPresent:(BOOL)useBackupFileIfPresent details:(NSString *__autoreleasing *)details
{
    NSMutableString *info = [NSMutableString string];
    if([self hasBackupFile] && !useBackupFileIfPresent) {
        [info appendFormat:NSLocalizedString(@"Backup file is present, revert to it before patching again", nil)];
        if(details) *details = [info copy];
        return NO;
    }
    
    if(![self hasBackupFile])
        [info appendFormat:NSLocalizedString(@"Backup file absent, can continue", nil)];
    [info appendString:@"\n"];
    
    
    BOOL useBackupFile = useBackupFileIfPresent && [self hasBackupFile];
    if(!layout) {
        [info appendFormat:NSLocalizedString(@"Sound card not recognized", nil)];
        if(details) *details = [info copy];
        return NO;
    }
    [info appendFormat:NSLocalizedString(@"Sound card recognized, layout %@", nil), [layout stringValue]];
    [info appendString:@"\n"];
    
    NSDictionary *layoutDic = [self dicForLayout:layout];
    if(!layoutDic) {
        [info appendFormat:NSLocalizedString(@"Layout file %@ missing", nil), [layout stringValue]];
        if(details) *details = [info copy];
        return NO;
    }
    [info appendFormat:NSLocalizedString(@"Layout file %@ present", nil), [layout stringValue]];
    [info appendString:@"\n"];
    
    NSArray *pathRefs = [self pathIDsForLayout:layout];
    if([pathRefs count] != 1) {
        [info appendFormat:NSLocalizedString(@"More than 1 path reference in layout file %@", nil), [layout stringValue]];
        if(details) *details = [info copy];
        return NO;
    }
    [info appendFormat:NSLocalizedString(@"Single path reference found", nil)];
    [info appendString:@"\n"];
    
    NSNumber *numberOfOutputsLayout = [self numberOfOutputsInLayout:layout];
    if (!numberOfOutputsLayout) {
        [info appendFormat:NSLocalizedString(@"Couldn't find number of outputs", nil)];
        if(details) *details = [info copy];
        return NO;
    }
    [info appendFormat:NSLocalizedString(@"Found %@ outputs in layout file", nil), [numberOfOutputsLayout stringValue]];
    [info appendString:@"\n"];
    
    NSNumber *digIndex = [self digitalOutIndexInLayout:layout];
    if(!digIndex) {
        [info appendFormat:NSLocalizedString(@"Digital output wasn't found in layout file %@", nil), [layout stringValue]];
        if(details) *details = [info copy];
        return NO;
    }
    [info appendFormat:NSLocalizedString(@"Digital output found in layout file %@", nil), [layout stringValue]];
    [info appendString:@"\n"];
    
    NSNumber *pathRef = pathRefs[0];
    NSNumber *rootsCount = [self numberOfRootsForPathIDInPlaftorms:pathRef useBackupFile:useBackupFile];
    if([rootsCount integerValue] != 2) {
        [info appendFormat:NSLocalizedString(@"Can't identify outputs list for path %@", nil), [pathRef stringValue]];
        if(details) *details = [info copy];
        return NO;
    }
    [info appendFormat:NSLocalizedString(@"Found list of outputs in path file %@", nil), [pathRef stringValue]];
    [info appendString:@"\n"];
    
    NSNumber *numberOfOutputsPlatforms = [self numberOfOutputsForPathIDInPlaftorms:pathRef useBackupFile:useBackupFile];
    if([numberOfOutputsLayout integerValue] != [numberOfOutputsPlatforms integerValue]) {
        [info appendFormat:NSLocalizedString(@"Number of outputs for layout %@ and path %@ differs (%@ != %@)", nil),
         [layout stringValue],
         [pathRef stringValue],
         [numberOfOutputsLayout stringValue],
         [numberOfOutputsPlatforms stringValue]];
        if(details) *details = [info copy];
        return NO;
    }
    [info appendFormat:NSLocalizedString(@"Number of outputs for layout %@ and path %@ is the same", nil), [layout stringValue], [pathRef stringValue]];
    [info appendString:@"\n"];
    
    [info appendString:NSLocalizedString(@"Card seems fully supported", nil)];
    if(details) *details = [info copy];
    
    return YES;
}

#pragma mark - Patching / restoring

+ (void)applyPatchForLayout:(NSNumber *)layout block:(void (^)(NSString *, NSError *, BOOL))block
{
    if([self hasBackupFile])
    {
        block(nil, [NSError SYErrorWithCode:SYErrorCodeBackupFilePresent userInfo:nil], YES);
        return;
    }
    
    if(![self layoutIDSeemsSupported:layout useBackupFileIfPresent:NO details:NULL])
    {
        block(nil, [NSError SYErrorWithCode:SYErrorCodeSoundCardNotSupported userInfo:nil], YES);
        return;
    }
    
    int pathRef = [[self pathIDsForLayout:layout][0] intValue];
    int digIndex = [[self digitalOutIndexInLayout:layout] intValue];
    int pathIndexInPlatforms = [[self dicIndexForPathIDInPlatforms:@(pathRef) useBackupFile:NO] intValue];
    
    // Loading data
    NSMutableDictionary *platforms = [[self dicForFile:SYAppleHDA_PlatformFile] mutableCopy];
    NSMutableArray *allPathMaps = [platforms[@"PathMaps"] mutableCopy];
    NSMutableDictionary *pathDic = [allPathMaps[pathIndexInPlatforms] mutableCopy];
    NSMutableArray *pathMaps = [pathDic[@"PathMap"] mutableCopy];
    NSMutableArray *outputsArray = [pathMaps[1] mutableCopy]; // second item seems to be output list
    
    // Patching
    [outputsArray removeObjectAtIndex:digIndex];
    
    // Building new data
    [pathMaps replaceObjectAtIndex:1 withObject:[outputsArray copy]];
    [pathDic setObject:[pathMaps copy] forKey:@"PathMap"];
    [allPathMaps replaceObjectAtIndex:pathIndexInPlatforms withObject:[pathDic copy]];
    [platforms setObject:[allPathMaps copy] forKey:@"PathMaps"];
    
    // Saving backup file
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:[self appleHDAPathForFile:SYAppleHDA_PlatformFile]
                                            toPath:[self appleHDAPathForFile:SYAppleHDA_PlatformFileBackup]
                                             error:&error];
    
    if (error) { block(nil, error, YES); return; }
    
    // Saving new platforms file
    error = [self saveDic:platforms forFile:SYAppleHDA_PlatformFile];
    if (error) { block(nil, error, YES); return; }
    
    // Ask system to rebuild cache on next reboot
    error = [self touchCache];
    if (error) { block(nil, error, YES); return; }
}

+ (void)restoreOriginalFile:(void (^)(NSString *, NSError *, BOOL))block
{
    if(![self hasBackupFile])
    {
        block(nil, [NSError SYErrorWithCode:SYErrorCodeBackupFileAbsent userInfo:nil], YES);
        return;
    }
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[self appleHDAPathForFile:SYAppleHDA_PlatformFile]
                                               error:&error];
    if (error) { block(nil, error, YES); return; }
    
    // Restoring backup file
    [[NSFileManager defaultManager] moveItemAtPath:[self appleHDAPathForFile:SYAppleHDA_PlatformFileBackup]
                                            toPath:[self appleHDAPathForFile:SYAppleHDA_PlatformFile]
                                             error:&error];
    if (error) { block(nil, error, YES); return; }
    
    // Ask system to rebuild cache on next reboot
    error = [self touchCache];
    if (error) { block(nil, error, YES); return; }
}

+ (NSError *)touchCache
{
    NSError *error;
    [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:[NSDate date]}
                                     ofItemAtPath:@"/System/Library/Extensions"
                                            error:&error];
    return error;
}

+ (NSError *)rebuildCache
{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [[NSBundle mainBundle] pathForResource:@"KextUtilScript" ofType:@"sh"];
    task.arguments = @[];
    task.standardOutput = pipe;
    //task.standardInput  = pipe;
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"grep returned:\n%@", grepOutput);
    return nil;
}

+ (NSString *)reloadKext
{
    NSString *unload = [self unloadKextPersonalities];
    NSString *load = [self loadKext];
    return [NSString stringWithFormat:@"Unloading Kext personalities...\n%@\nLoading kext...\n%@", unload, load];
}

+ (NSString *)unloadKextPersonalities
{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/sbin/kextunload";
    task.arguments = @[@"-p", [self appleHDAKextPath]];
    task.standardOutput = pipe;
    //task.standardInput  = pipe;
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"grep returned:\n%@", grepOutput);
    return grepOutput;
}

+ (NSString *)loadKext
{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/sbin/kextload";
    task.arguments = @[[self appleHDAKextPath]];
    task.standardOutput = pipe;
    //task.standardInput  = pipe;
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"grep returned:\n%@", grepOutput);
    return grepOutput;
}

#pragma mark - DEBUG

+ (void)inflateAllAndSaveToPath:(NSString *)outpath
{
    [[NSFileManager defaultManager] createDirectoryAtPath:outpath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    
    NSString *sle = [self appleHDAPathForFile:nil];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sle error:NULL];
    
    for(NSString *file in files)
    {
        if(![file hasSuffix:@"zlib"])
            continue;
        
        NSData *compressedLayout = [NSData dataWithContentsOfFile:[sle stringByAppendingPathComponent:file]];
        NSData *inflatedLayout = [compressedLayout zlibInflate];
        
        NSString *newFileName = [file stringByReplacingOccurrencesOfString:@".xml.zlib" withString:@".plist"];
        [inflatedLayout writeToFile:[outpath stringByAppendingPathComponent:newFileName] atomically:YES];
        NSLog(@"Inflated %@", file);
    }
}

+ (void)listAllLayoutIDToPathRef
{
    NSString *sle = [self appleHDAPathForFile:nil];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sle error:NULL];
    
    NSMutableArray *layoutIDs = [NSMutableArray array];
    for(NSString *file in files)
    {
        if(![file hasSuffix:@"zlib"])
            continue;
        
        if([file hasPrefix:@"Platforms"])
            continue;
        
        NSString *layoutID = [[file stringByReplacingOccurrencesOfString:@"layout" withString:@""]
                              stringByReplacingOccurrencesOfString:@".xml.zlib" withString:@""];
        
        [layoutIDs addObject:layoutID];
    }
    
    [layoutIDs sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:(NSNumericSearch)];
    }];
    
    for(NSString *layoutID in layoutIDs)
    {
        NSArray *pathIDs = [self pathIDsForLayout:[NSNumber numberWithInteger:[layoutID intValue]]];
        NSLog(@"%@ -> %@", layoutID, [pathIDs componentsJoinedByString:@", "]);
    }
}

+ (void)test
{
    //[self listAllLayoutIDToPathRef];
    //NSDictionary *dic = [self dicForLayout:@20];
    //NSLog(@"%@", dic[@"PathMapRef"][0][@"Outputs"]);
}


@end
