//
//  SYStepView.m
//  DigitalOust
//
//  Created by Stan Chevallier on 28/06/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import "SYStepView.h"
#import "SYStep.h"
#import "JESCircularProgressView.h"
#import "Masonry.h"

static NSImage *imageCheck;
static NSImage *imageCross;

@interface SYStepView ()
@property (nonatomic, strong) NSTextField *labelTitle;
@property (nonatomic, strong) NSTextField *labelDescr;
@property (nonatomic, strong) NSTextField *labelNumber;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) JESCircularProgressView *progressView;
@property (nonatomic, strong) NSButton *button;
@end

@implementation SYStepView

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
    [self.labelDescr setTextColor:[NSColor darkGrayColor]];
    [self addSubview:self.labelDescr];
    
    self.imageView = [[NSImageView alloc] init];
    [self.imageView setImageScaling:NSImageScaleProportionallyDown];
    [self.imageView setImageAlignment:NSImageAlignCenter];
    [self addSubview:self.imageView];
    
    self.progressView = [[JESCircularProgressView alloc] init];
    [self.progressView setTintColor:[NSColor grayColor]];
    [self.progressView setProgressLineWidth:10.];
    [self.progressView setOuterLineWidth:3.];
    
    self.button = [[NSButton alloc] init];
    [self.button setButtonType:NSMomentaryPushInButton];
    [self.button setBezelStyle:NSRoundedBezelStyle];
    [self.button setTarget:self];
    [self.button setAction:@selector(buttonTap:)];
    [self addSubview:self.button];
    
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
    
    [self updateConstraints];
    [self layoutSubtreeIfNeeded];
    [self updateState];
}

#pragma mark - Properties

- (void)updateConstraints
{
    [super updateConstraints];
    [self.labelDescr mas_remakeConstraints:^(MASConstraintMaker *make) {
        BOOL hasContent = (self.labelDescr.stringValue.length != 0);
        make.top.equalTo(self.labelTitle.mas_bottom).offset(hasContent ? 6 : 0);
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        if (!hasContent)
            make.height.equalTo(@0);
    }];
}

- (void)setButtonEnabled:(BOOL)buttonEnabled
{
    self->_buttonEnabled = buttonEnabled;
    [self.button setEnabled:buttonEnabled];
}

- (void)setStep:(SYStep *)step
{
    [self.step setProgressBlock:nil];
    [self.step setUpdatedBlock:nil];
    
    self->_step = step;
    [self updateState];
    
    __weak SYStepView *wSelf = self;
    [step setProgressBlock:^(CGFloat progress) {
        [wSelf.progressView setProgress:progress animated:YES];
    }];
    [step setUpdatedBlock:^{
        [wSelf updateState];
    }];
}

#pragma mark - State

- (void)updateState
{
    if(!self.step)
        return;
    
    switch ([self.step image]) {
        case SYStepImageOK:
            [self.imageView setHidden:NO];
            [self.imageView setImage:imageCheck];
            [self.progressView setHidden:YES];
            break;
        case SYStepImageNotOK:
            [self.imageView setHidden:NO];
            [self.imageView setImage:imageCross];
            [self.progressView setHidden:YES];
            break;
        case SYStepImageProgressDetermined:
            [self.imageView setHidden:YES];
            [self.progressView setHidden:NO];
            break;
        case SYStepImageProgressUndetermined:
            [self.imageView setHidden:YES];
            [self.progressView setHidden:NO];
            break;
    }
    
    [self.labelTitle setStringValue:[self.step titleText] ?: @""];
    [self.labelDescr setStringValue:[self.step descrText] ?: @""];
    
    NSString *buttonText = [self.step buttonText];
    [self.button setHidden:buttonText ? NO : YES];
    [self.button setTitle:buttonText ?: @""];
    
    [self setNeedsUpdateConstraints:YES];
}

#pragma mark - Buttons

- (void)buttonTap:(id)sender
{
    [self.step buttonTap:self.window];
}

@end
