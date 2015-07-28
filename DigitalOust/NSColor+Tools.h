//
//  NSColor+Tools.h
//  DigitalOust
//
//  Created by Stan Chevallier on 23/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Tools)

+ (NSColor *)colorWithHex:(NSString *)hex;

+ (NSColor *)colorTrafficLightRedStroke;
+ (NSColor *)colorTrafficLightRedFill;

+ (NSColor *)colorTrafficLightOrangeStroke;
+ (NSColor *)colorTrafficLightOrangeFill;

+ (NSColor *)colorTrafficLightGreenStroke;
+ (NSColor *)colorTrafficLightGreenFill;

+ (NSColor *)colorAquaStroke;
+ (NSColor *)colorAquaFill;

+ (NSColor *)windowBackgroundColor:(BOOL)active;

@end
