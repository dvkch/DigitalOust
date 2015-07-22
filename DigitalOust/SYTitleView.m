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
@property (nonatomic, strong) NSView *viewTitleImage;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) NSTextField *labelTitle;
@property (nonatomic, strong) NSButton *buttonMaker;
@property (nonatomic, strong) NSButton *buttonDonate;
@property (nonatomic, strong) NSView *viewSeparator;
@end

@implementation SYTitleView

@dynamic layer;

- (nonnull CALayer *)makeBackingLayer
{
    return [[CAGradientLayer alloc] init];
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
    [self.layer setLocations:@[@(0), @(1)]];
    [self.layer setStartPoint:CGPointMake(0, 1)];
    [self.layer setEndPoint:CGPointMake(0, 0)];
    [self updateGradient];
    
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
    
    
    self.buttonMaker = [[NSButton alloc] init];
    [self.buttonMaker setButtonType:NSMomentaryPushInButton];
    [self.buttonMaker setBezelStyle:NSInlineBezelStyle];
    [self.buttonMaker setShowsBorderOnlyWhileMouseInside:YES];
    [self.buttonMaker setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    [self.buttonMaker setTitle:@"by @Syan_me"];
    [self.buttonMaker setTarget:self];
    [self.buttonMaker setAction:@selector(buttonMakerTap:)];
    [self addSubview:self.buttonMaker];
    
    
    self.buttonDonate = [[NSButton alloc] init];
    [self.buttonDonate setButtonType:NSMomentaryPushInButton];
    [self.buttonDonate setBezelStyle:NSInlineBezelStyle];
    [self.buttonDonate setShowsBorderOnlyWhileMouseInside:YES];
    [self.buttonDonate setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    [self.buttonDonate setTitle:@"Donate"];
    [self.buttonDonate setTarget:self];
    [self.buttonDonate setAction:@selector(buttonDonateTap:)];
    [self addSubview:self.buttonDonate];
    
    
    [self.viewTraffic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(@0);
        make.left.equalTo(@13);
    }];
    
    [self.viewTitleImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@15);
        make.bottom.equalTo(@(-15));
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
    
    [self.buttonDonate mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-18));
        make.centerY.equalTo(@(-10));
    }];
    
    [self.buttonMaker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-18));
        make.centerY.equalTo(@(10));
    }];
    
    [self.viewSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
        make.bottom.equalTo(@0);
    }];
    
    [self test];
}

- (void)test
{
    [self.buttonMaker setNeedsDisplay:YES];
    [self.buttonDonate setNeedsDisplay:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self test];
    });
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if (self.window)
    {
        [nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:self.window];
        [nc removeObserver:self name:NSWindowDidResignKeyNotification object:self.window];
    }
    if (newWindow)
    {
        [nc addObserver:self selector:@selector(windowDidChangeFocus:) name:NSWindowDidBecomeKeyNotification object:newWindow];
        [nc addObserver:self selector:@selector(windowDidChangeFocus:) name:NSWindowDidResignKeyNotification object:newWindow];
    }
}

- (void)viewDidMoveToWindow
{
    [self updateGradient];
}

- (void)windowDidChangeFocus:(NSNotification *)n
{
    [self updateGradient];
}

- (void)updateGradient
{
    if (!self.window || self.window.isKeyWindow)
    {
        [self.layer setColors:@[(id)[NSColor colorWithCalibratedWhite:232./255. alpha:1.].CGColor,
                                (id)[NSColor colorWithCalibratedWhite:210./255. alpha:1.].CGColor]];
    }
    else
    {
        [self.layer setColors:@[(id)[NSColor colorWithCalibratedWhite:246./255. alpha:1.].CGColor,
                                (id)[NSColor colorWithCalibratedWhite:246./255. alpha:1.].CGColor]];
    }
}

#pragma mark - Actions

- (void)buttonDonateTap:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://syan.me/"]];
}

- (void)buttonMakerTap:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://syan.me/"]];
}

@end
