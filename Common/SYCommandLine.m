//
//  SYCommandLine.m
//  DisableDigitalOut
//
//  Created by Stan Chevallier on 18/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYCommandLine.h"

@implementation SYCommandLine

+ (void)askForReboot
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/osascript";
    task.arguments = @[@"-e 'tell app \"loginwindow\" to «event aevtrrst»'"];
    [task launch];
}

@end
