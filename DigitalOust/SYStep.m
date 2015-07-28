//
//  SYStep.m
//  DigitalOust
//
//  Created by Stan Chevallier on 20/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStep.h"

@implementation SYStep

- (NSString *)statusString
{
    return nil;
}

- (NSString *)titleText
{
    return nil;
}

- (NSString *)buttonText;
{
    return nil;
}

- (NSString *)descrText;
{
    return nil;
}

- (SYStepImage)image
{
    return SYStepImageNotOK;
}

- (BOOL)show
{
    return YES;
}

- (BOOL)requiresRoot
{
    return YES;
}

- (void)buttonTap:(NSView *)sender
{
    
}

- (void)startUpdating
{
    
}

- (void)stopUpdating
{
    
}

@end
