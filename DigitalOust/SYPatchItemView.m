//
//  SYPatchItemView.m
//  DigitalOust
//
//  Created by Stan Chevallier on 28/06/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYPatchItemView.h"
#import "Masonry.h"

static NSImage *imageCheck;
static NSImage *imageCross;

@interface SYPatchItemView ()
@property (nonatomic, strong) NSTextField *labelTitle;
@property (nonatomic, strong) NSTextField *labelDescr;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) NSButton *button;
@property (nonatomic, strong) NSMutableDictionary *dicTitles;
@property (nonatomic, strong) NSMutableDictionary *dicButtons;
@end

@implementation SYPatchItemView

#pragma mark - Init

+ (void)initialize
{
    imageCheck = [NSImage imageNamed:@"check.png"];
    imageCross = [NSImage imageNamed:@"cross.png"];
}

- (nonnull instancetype)init
{
    self = [super init];
    if (self) [self customInit];
    return self;
}

- (nonnull instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) [self customInit];
    return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) [self customInit];
    return self;
}

- (void)customInit
{
    if(self.labelTitle)
        return;
    
    [self setWantsLayer:YES];
    
    self.dicTitles  = [NSMutableDictionary dictionary];
    self.dicButtons = [NSMutableDictionary dictionary];
    
    self.labelTitle = [[NSTextField alloc] init];
    [self.labelTitle setBordered:NO];
    [self.labelTitle setEditable:NO];
    [self.labelTitle setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]+1]];
    [self.labelTitle setDrawsBackground:NO];
    [self addSubview:self.labelTitle];
    
    self.labelDescr = [[NSTextField alloc] init];
    [self.labelDescr setBordered:NO];
    [self.labelDescr setEditable:NO];
    [self.labelDescr setLineBreakMode:NSLineBreakByWordWrapping];
    [self.labelDescr setDrawsBackground:NO];
    [self addSubview:self.labelDescr];
    
    self.imageView = [[NSImageView alloc] init];
    [self.imageView setImageScaling:NSImageScaleProportionallyDown];
    [self.imageView setImageAlignment:NSImageAlignCenter];
    [self addSubview:self.imageView];
    
    self.button = [[NSButton alloc] init];
    [self.button setButtonType:NSMomentaryPushInButton];
    [self.button setBezelStyle:NSRoundedBezelStyle];
    [self.button setTarget:self];
    [self.button setAction:@selector(buttonTap:)];
    [self addSubview:self.button];
    /*
    self.buttonDescr = [[NSButton alloc] init];
    [self.buttonDescr setButtonType:NSPushOnPushOffButton];
    [self.buttonDescr setBezelStyle:NSDisclosureBezelStyle];
    [self.buttonDescr setTitle:@""];
    [self.buttonDescr setTarget:self];
    [self.buttonDescr setAction:@selector(buttonDescrTap:)];
    [self addSubview:self.buttonDescr];
    */
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(@22);
        make.left.equalTo(@0);
        make.top.equalTo(@0);
    }];
    
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@21);
        make.width.width.equalTo(@80);
        make.right.equalTo(@0);
        make.top.equalTo(@0);
    }];
    
    [self.labelTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imageView.mas_right).offset(10);
        make.right.equalTo(self.button.mas_left).offset(-10);
        make.centerY.equalTo(self.imageView);
        make.height.equalTo(@20);
    }];
    
    [self.labelDescr mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imageView.mas_left);
        make.right.equalTo(self.button.mas_right);
        make.top.equalTo(self.labelTitle.mas_bottom).offset(6);
        make.bottom.equalTo(@0);
    }];
    
    [self layoutSubtreeIfNeeded];
    [self updateState];
}

#pragma mark - Properties

- (void)setTitleText:(NSString *)title forState:(NSString *)state
{
    [self.dicTitles setObject:(title ?: [NSNull null]) forKey:state];
    [self updateState];
}

- (void)setButtonText:(NSString *)title forState:(NSString *)state
{
    [self.dicButtons setObject:(title ?: [NSNull null]) forKey:state];
    [self updateState];
}

- (void)setDescrText:(NSString *)descrText
{
    self->_descrText = descrText;
    [self updateState];
}

- (void)setButtonEnabled:(BOOL)buttonEnabled
{
    self->_buttonEnabled = buttonEnabled;
    [self.button setEnabled:buttonEnabled];
}

#pragma mark - Layout

- (CGFloat)descrTextHeight
{
    CGFloat descrW = CGRectGetWidth(self.labelDescr.frame);
    NSSize descrS = [self.labelDescr.attributedStringValue
                     boundingRectWithSize:NSMakeSize(descrW, CGFLOAT_MAX)
                     options:NSStringDrawingUsesLineFragmentOrigin].size;
    return descrS.height;
}

#pragma mark - State

- (void)updateState
{
    if(!self.determineStateBlock)
        return;
    
    NSString *state = self.determineStateBlock();
    
    if (self.useSuccessImageForStateBlock)
        [self.imageView setImage:(self.useSuccessImageForStateBlock(state) ? imageCheck : imageCross)];
    
    NSString *title = [self.dicTitles objectForKey:state];
    [self.labelTitle setStringValue:title];
    
    NSString *button = [self.dicButtons objectForKey:@"all"] ?: [self.dicButtons objectForKey:state];
    [self.button setHidden:[button isEqualTo:[NSNull null]]];
    if(![button isEqualTo:[NSNull null]])
        [self.button setTitle:(button ?: @"")];
    
    [self.labelDescr setStringValue:(self.descrText ?: @"")];
    
    [self setNeedsUpdateConstraints:YES];
}

#pragma mark - Buttons

- (void)buttonTap:(id)sender
{
    if (self.buttonTappedBlock)
        self.buttonTappedBlock();
}

@end
