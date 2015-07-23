//
//  NSAttributedString+Tools.m
//  eBookQA
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 SQLI. All rights reserved.
//

#import "NSAttributedString+Tools.h"

@implementation NSAttributedString (Tools)

+ (instancetype)attributedStringWithText:(NSString *)text font:(NSFont *)font color:(NSColor *)color
{
    if (!text) return nil;
    NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
    if (font)  [attribs setObject:font  forKey:NSFontAttributeName];
    if (color) [attribs setObject:color forKey:NSForegroundColorAttributeName];
    return [[NSAttributedString alloc] initWithString:text attributes:attribs];
}

+ (instancetype)attributedStringsWithAttributedStrings:(NSArray *)strings addReturn:(BOOL)addReturn
{
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] init];
    for(NSUInteger i = 0; i < [strings count]; ++i)
    {
        NSAttributedString *s = strings[i];
        [res appendAttributedString:s];
        if (addReturn && i < (strings.count - 1))
        {
            NSAttributedString *ret = [self attributedStringWithText:@"\n" font:nil color:nil];
            [res appendAttributedString:ret];
        }
    }
    return [res copy];
}

@end
