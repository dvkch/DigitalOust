//
//  NSColor+Tools.m
//  DigitalOust
//
//  Created by Stan Chevallier on 23/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "NSColor+Tools.h"

@implementation NSColor (Tools)

+ (NSColor *)colorWithHex:(NSString *)hex
{
    if (!hex.length)
        return nil;
    
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    NSScanner* scanner = [NSScanner scannerWithString:hex];
    [scanner scanHexInt:&colorCode];
    
    redByte   = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte  = (unsigned char)(colorCode);
    
    return [NSColor colorWithCalibratedRed:(CGFloat)redByte   / 0xff
                                     green:(CGFloat)greenByte / 0xff
                                      blue:(CGFloat)blueByte  / 0xff
                                     alpha:1.0];
}

+ (NSColor *)colorTrafficLightRedStroke
{
    return [self colorWithHex:@"df4744"];
}

+ (NSColor *)colorTrafficLightRedFill
{
    return [self colorWithHex:@"fc5753"];
}

+ (NSColor *)colorTrafficLightOrangeStroke
{
    return [self colorWithHex:@"de9f34"];
}

+ (NSColor *)colorTrafficLightOrangeFill
{
    return [self colorWithHex:@"fdbc40"];
}

+ (NSColor *)colorTrafficLightGreenStroke
{
    return [self colorWithHex:@"27aa35"];
}

+ (NSColor *)colorTrafficLightGreenFill
{
    return [self colorWithHex:@"33c748"];
}

+ (NSColor *)colorAquaStroke
{
    return [self colorWithHex:@"0064f5"];
}

+ (NSColor *)colorAquaFill
{
    return [self colorWithHex:@"65b4f5"];
}

+ (NSColor *)windowBackgroundColor:(BOOL)active
{
    return [NSColor colorWithCalibratedWhite:(active ? 232. : 246.)/255. alpha:1.];
}

@end
