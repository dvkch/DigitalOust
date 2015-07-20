//
//  SYTitleView.m
//  DigitalOust
//
//  Created by Stan Chevallier on 19/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYTitleView.h"
#import <QuartzCore/QuartzCore.h>
#import "Masonry.h"
#import "SYTrafficView.h"

@interface SYTitleView ()
@property (nullable, strong) CAGradientLayer *layer;
@property (nonatomic, strong) SYTrafficView *viewTraffic;
@property (nonatomic, strong) NSTextField *labelTitle;
@property (nonatomic, strong) NSView *viewSeparator;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) NSView *viewTitleImage;
@end

@implementation SYTitleView

@dynamic layer;

- (nonnull CALayer *)makeBackingLayer
{
    self.layer = [[CAGradientLayer alloc] init];
    [self.layer setFrame:self.bounds];
    return self.layer;
}

- (nonnull instancetype)init
{
    self = [super init];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit
{
    if (self.labelTitle)
        return;
    
    
    [self setWantsLayer:YES];
    [self.layer setColors:@[(id)[NSColor colorWithCalibratedWhite:232./255. alpha:1.].CGColor,
                            (id)[NSColor colorWithCalibratedWhite:210./255. alpha:1.].CGColor]];
    [self.layer setLocations:@[@(0), @(1)]];
    [self.layer setStartPoint:CGPointMake(0, 1)];
    [self.layer setEndPoint:CGPointMake(0, 0)];
    
    
    self.viewTitleImage = [[NSView alloc] init];
    [self addSubview:self.viewTitleImage];

    
    self.imageView = [[NSImageView alloc] init];
    [self.imageView setImage:[NSImage imageNamed:@"AppIcon"]];
    [self.viewTitleImage addSubview:self.imageView];
    
    
    self.labelTitle = [[NSTextField alloc] init];
    [self.labelTitle setBordered:NO];
    [self.labelTitle setEditable:NO];
    [self.labelTitle setFont:[NSFont fontWithName:@"HelveticaNeue-UltraLight" size:30]];
    [self.labelTitle setDrawsBackground:NO];
    [self.labelTitle setStringValue:@"Digital Oust"];
    [self.viewTitleImage addSubview:self.labelTitle];
    

    self.viewTraffic = [[SYTrafficView alloc] init];
    [self.viewTraffic setEnabledButtons:(SYTrafficButtonClose | SYTrafficButtonMinimize)];
    [self addSubview:self.viewTraffic];
    
    
    self.viewSeparator = [[NSView alloc] init];
    [self.viewSeparator setWantsLayer:YES];
    [self.viewSeparator.layer setBackgroundColor:[NSColor colorWithCalibratedWhite:173./255. alpha:1.].CGColor];
    [self addSubview:self.viewSeparator];
    
    [self.viewSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
        make.bottom.equalTo(@0);
    }];

    [self.viewTitleImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@10);
        make.bottom.equalTo(@(-10));
        make.centerX.equalTo(@0);
    }];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.centerY.equalTo(@0);
        make.size.equalTo(@30);
    }];
    
    [self.labelTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imageView.mas_right).offset(14);
        make.top.equalTo(@0);
        make.bottom.equalTo(@0);
        make.right.equalTo(@0);
    }];
    
    [self.viewTraffic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(@0);
        make.left.equalTo(@22);
    }];
}

@end
