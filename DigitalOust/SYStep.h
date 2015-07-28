//
//  SYStep.h
//  DigitalOust
//
//  Created by Stan Chevallier on 20/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <AppKit/AppKit.h>

typedef enum : NSUInteger {
    SYStepImageOK,
    SYStepImageNotOK,
    SYStepImageNotOKOptional,
    SYStepImageProgressDetermined,
} SYStepImage;

@interface SYStep : NSObject

@property (nonatomic, assign) NSUInteger stepNumber;
@property (nonatomic, copy) void(^progressBlock)(CGFloat progress);
@property (nonatomic, copy) void(^updatedBlock)(void);

- (NSString *)statusString;
- (NSString *)titleText;
- (NSString *)buttonText;
- (NSString *)descrText;
- (SYStepImage)image;
- (BOOL)show;
- (BOOL)requiresRoot;
- (void)buttonTap:(NSView *)sender;
- (void)startUpdating;
- (void)stopUpdating;

@end
