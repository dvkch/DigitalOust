//
//  SYTrafficView.m
//  DigitalOust
//
//  Created by Stan Chevallier on 20/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYTrafficView.h"
#import "INWindowButton.h"
#import "Masonry.h"

@interface SYTrafficView ()
@property (nonatomic, strong) INWindowButton *buttonClose;
@property (nonatomic, strong) INWindowButton *buttonMinimize;
@property (nonatomic, strong) INWindowButton *buttonZoom;
@end

@implementation SYTrafficView

- (nonnull instancetype)init
{
    self = [super init];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit
{
    if (self.buttonClose)
        return;
    
    NSString *group = [NSString stringWithFormat:@"<%@: %p>", [self class], self];
    
    self.buttonClose = [INWindowButton windowButtonWithSize:NSMakeSize(13, 13) groupIdentifier:group];
    [self.buttonClose setTarget:self];
    [self.buttonClose setAction:@selector(buttonCloseTap:)];
    [self setupButton:self.buttonClose imagesWithPrefix:@"close"];
    [self addSubview:self.buttonClose];
    
    self.buttonMinimize = [INWindowButton windowButtonWithSize:NSMakeSize(13, 13) groupIdentifier:group];
    [self.buttonMinimize setTarget:self];
    [self.buttonMinimize setAction:@selector(buttonMinimizeTap:)];
    [self setupButton:self.buttonMinimize imagesWithPrefix:@"minimize"];
    [self addSubview:self.buttonMinimize];
    
    self.buttonZoom = [INWindowButton windowButtonWithSize:NSMakeSize(13, 13) groupIdentifier:group];
    [self.buttonZoom setTarget:self];
    [self.buttonZoom setAction:@selector(buttonZoomTap:)];
    [self setupButton:self.buttonZoom imagesWithPrefix:@"zoom"];
    [self addSubview:self.buttonZoom];
    
    [self setupAccessibilityAttributes];
    
    [self.buttonClose mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.top.equalTo(@0);
        make.size.equalTo(@12);
        make.bottom.equalTo(@0);
    }];
    
    [self.buttonMinimize mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.buttonClose.mas_right).offset(8);
        make.top.equalTo(@0);
        make.size.equalTo(@12);
        make.bottom.equalTo(@0);
    }];
    
    [self.buttonZoom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.buttonMinimize.mas_right).offset(8);
        make.top.equalTo(@0);
        make.size.equalTo(@12);
        make.bottom.equalTo(@0);
        make.right.equalTo(@0);
    }];
}

- (void)setupAccessibilityAttributes
{
    NSDictionary *buttons = @{@(SYTrafficButtonClose):   self.buttonClose,
                              @(SYTrafficButtonMinimize):self.buttonMinimize,
                              @(SYTrafficButtonZoom):    self.buttonZoom};
    
    for (NSNumber *typeN in [buttons allKeys])
    {
        INWindowButton *button = buttons[typeN];
        NSWindowButton type = [typeN unsignedIntegerValue];
        
        NSString *subrole;
        if(type == SYTrafficButtonClose)    subrole = NSAccessibilityCloseButtonSubrole;
        if(type == SYTrafficButtonMinimize) subrole = NSAccessibilityMinimizeButtonSubrole;
        if(type == SYTrafficButtonZoom)     subrole = NSAccessibilityZoomButtonSubrole;
        
        [button.cell accessibilitySetOverrideValue:subrole forAttribute:NSAccessibilitySubroleAttribute];
        [button.cell accessibilitySetOverrideValue:NSAccessibilityRoleDescription(NSAccessibilityButtonRole, subrole)
                                      forAttribute:NSAccessibilityRoleDescriptionAttribute];
    }
}

- (void)setupButton:(INWindowButton *)button imagesWithPrefix:(NSString *)prefix
{
    [button setActiveNotKeyWindowImage:[NSImage imageNamed:@"disabled"]];
    [button setActiveImage:            [NSImage imageNamed:[prefix stringByAppendingString:@"0"]]];
    [button setRolloverImage:          [NSImage imageNamed:[prefix stringByAppendingString:@"1"]]];
    [button setPressedImage:           [NSImage imageNamed:[prefix stringByAppendingString:@"2"]]];
    [button setInactiveImage:          [NSImage imageNamed:@"disabled"]];
}

#pragma mark - Enabled buttons

- (void)setEnabledButtons:(SYTrafficButton)buttons
{
    [self.buttonClose    setEnabled:(buttons & SYTrafficButtonClose)];
    [self.buttonMinimize setEnabled:(buttons & SYTrafficButtonMinimize)];
    [self.buttonZoom     setEnabled:(buttons & SYTrafficButtonZoom)];
}

#pragma mark - Actions

- (void)buttonCloseTap:(id)sender
{
    [self.window close];
}

- (void)buttonMinimizeTap:(id)sender
{
    [self.window miniaturize:nil];
}

- (void)buttonZoomTap:(id)sender
{
    [self.window zoom:nil];
}

@end
