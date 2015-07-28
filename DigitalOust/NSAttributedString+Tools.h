//
//  NSAttributedString+Tools.h
//  eBookQA
//
//  Created by Stan Chevallier on 22/07/2015.
//  Copyright © 2015 SQLI. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSAttributedString (Tools)

+ (instancetype)attributedStringWithText:(NSString *)text font:(NSFont *)font color:(NSColor *)color;
+ (instancetype)attributedStringWithAttributedStrings:(NSArray *)strings addReturn:(BOOL)addReturn;

@end
