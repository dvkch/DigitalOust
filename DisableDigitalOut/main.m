//
//  main.m
//  DisableDigitalOut
//
//  Created by Stanislas Chevallier on 08/06/15.
//  Copyright (c) 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[])
{
    // we need the spawned process to tell us it's pid
    if(geteuid() == 0)
        printf("%d\n", getpid());
    
    return NSApplicationMain(argc, argv);
}
