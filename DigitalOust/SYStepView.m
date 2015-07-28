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
#import "NSAttributedString+Tools.h"
#import "NSAlert+DigitalOust.h"
#import "NSColor+Tools.h"

@interface SYStepView ()
@property (nonatomic, strong) NSView *roundView;
@property (nonatomic, strong) NSTextField *labelText;
@property (nonatomic, strong) NSTextField *labelNumber;
@property (nonatomic, strong) JESCircularProgressView *progressView;
@property (nonatomic, strong) NSButton *button;
@property (nonatomic, assign) CGFloat widthDiffForLabelText;
@property (nonatomic, assign) CGFloat lastLayoutWidth;
@end

@implementation SYStepView

#pragma mark - Init

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
    if(self.labelText)
        return;
    
    [self setWantsLayer:YES];

    self.roundView = [[NSView alloc] init];
    [self.roundView setWantsLayer:YES];
    [self.roundView.layer setCornerRadius:30];
    [self.roundView.layer setBorderWidth:1.];
    [self addSubview:self.roundView];
    
    self.labelNumber = [[NSTextField alloc] init];
    [self.labelNumber setBordered:NO];
    [self.labelNumber setEditable:NO];
    [self.labelNumber setLineBreakMode:NSLineBreakByWordWrapping];
    [self.labelNumber setDrawsBackground:NO];
    [self.labelNumber setFont:[NSFont boldSystemFontOfSize:30]];
    [self.labelNumber setTextColor:[NSColor windowBackgroundColor:YES]];
    [self addSubview:self.labelNumber];
    
    self.progressView = [[JESCircularProgressView alloc] init];
    [self.progressView setTintColor:[NSColor grayColor]];
    [self.progressView setProgressLineWidth:3.];
    [self.progressView setOuterLineWidth:1.];
    [self addSubview:self.progressView];
    
    self.labelText = [[NSTextField alloc] init];
    [self.labelText setBordered:NO];
    [self.labelText setEditable:NO];
    [self.labelText setDrawsBackground:NO];
    [self.labelText setLineBreakMode:NSLineBreakByWordWrapping];
    [self addSubview:self.labelText];
    
    self.button = [[NSButton alloc] init];
    [self.button setButtonType:NSMomentaryPushInButton];
    [self.button setBezelStyle:NSRoundedBezelStyle];
    [self.button setTarget:self];
    [self.button setAction:@selector(buttonTap:)];
    [self addSubview:self.button];
    
    [self.roundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(@0);
        make.top.greaterThanOrEqualTo(@0);
        make.bottom.lessThanOrEqualTo(@0);
        make.size.equalTo(@60);
        make.left.equalTo(@0);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.roundView);
    }];
    
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@21);
        make.width.width.equalTo(@80);
        make.right.equalTo(@0);
        make.top.equalTo(@0);
    }];
    
    [self.labelText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(@0);
        make.top.greaterThanOrEqualTo(@0);
        make.bottom.lessThanOrEqualTo(@0);
        make.left.equalTo(self.roundView.mas_right).offset(10);
        make.right.equalTo(self.button.mas_left).offset(-10);
    }];
    
    [self.labelNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.roundView);
    }];
    
    self.widthDiffForLabelText = 60 + 80 + 2 * 10;
    
    [self setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];
    
    [self layoutSubtreeIfNeeded];
    [self updateState:NO];
}

#pragma mark - Public

- (void)startUpdate
{
    [self.step startUpdating];
    [self updateState:NO];
}

- (void)stopUpdate
{
    [self.step stopUpdating];
}

#pragma mark - Properties

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
    [self updateState:NO];
    
    __weak SYStepView *wSelf = self;
    [step setProgressBlock:^(CGFloat progress) {
        [wSelf.progressView setProgress:progress animated:NO];
    }];
    [step setUpdatedBlock:^{
        [wSelf updateState:YES];
    }];
}

#pragma mark - State

- (void)updateState:(BOOL)animated
{
    if(!self.step)
        return;
    
    if (animated)
    {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 2.f;
            [self updateState:NO];
        } completionHandler:nil];
        return;
    }
    
    switch ([self.step image]) {
        case SYStepImageOK:
            [self.roundView.layer setBackgroundColor:[NSColor colorAquaFill].CGColor];
            [self.roundView.layer     setBorderColor:[NSColor colorAquaStroke].CGColor];
            [self.roundView     setHidden:NO];
            [self.progressView  setHidden:YES];
            break;
        case SYStepImageNotOK:
            [self.roundView.layer setBackgroundColor:[NSColor colorTrafficLightRedFill].CGColor];
            [self.roundView.layer     setBorderColor:[NSColor colorTrafficLightRedStroke].CGColor];
            [self.roundView     setHidden:NO];
            [self.progressView  setHidden:YES];
            break;
        case SYStepImageNotOKOptional:
            [self.roundView.layer setBackgroundColor:[NSColor colorTrafficLightOrangeFill].CGColor];
            [self.roundView.layer     setBorderColor:[NSColor colorTrafficLightOrangeStroke].CGColor];
            [self.roundView     setHidden:NO];
            [self.progressView  setHidden:YES];
            break;
        case SYStepImageProgressDetermined:
            [self.roundView.layer setBackgroundColor:[NSColor grayColor].CGColor];
            [self.roundView.layer     setBorderColor:[NSColor grayColor].CGColor];
            [self.roundView     setHidden:YES];
            [self.progressView  setHidden:NO];
            break;
    }
    
    NSFont *fontTitle = [NSFont systemFontOfSize:[NSFont systemFontSize]+1];
    NSFont *fontDescr = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    NSColor *colorTitle = [NSColor blackColor];
    NSColor *colorDescr = [NSColor darkGrayColor];
    
    NSAttributedString *title = [NSAttributedString attributedStringWithText:(self.step.titleText ?: @"")
                                                                        font:fontTitle color:colorTitle];
    NSAttributedString *descr = [NSAttributedString attributedStringWithText:self.step.descrText
                                                                        font:fontDescr color:colorDescr];
    
    NSArray *strings = (descr ? @[title, descr] : @[title]);
    [self.labelText setAttributedStringValue:[NSAttributedString attributedStringWithAttributedStrings:strings
                                                                                             addReturn:YES]];
    
    NSString *buttonText = [self.step buttonText];
    [self.button setHidden:buttonText ? NO : YES];
    [self.button setTitle:buttonText ?: @""];
    
    [self.labelNumber setStringValue:[NSString stringWithFormat:@"%d", (int)self.step.stepNumber + 1]];
    
    [self invalidateIntrinsicContentSize];
}

- (CGFloat)fittingHeight
{
    CGFloat textW = self.frame.size.width - self.widthDiffForLabelText;
    CGFloat textH = [self.labelText.attributedStringValue boundingRectWithSize:NSMakeSize(textW, CGFLOAT_MAX)
                                                                       options:NSStringDrawingUsesLineFragmentOrigin].size.height;
    return MAX(60, textH);
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(NSViewNoInstrinsicMetric, [self fittingHeight]);
}

- (void)layout
{
    [super layout];
    BOOL newWidth = fabs(self.frame.size.width - self.lastLayoutWidth) > 0.1;
    self.lastLayoutWidth = self.frame.size.width;
    if (newWidth)
        [self invalidateIntrinsicContentSize];
}

#pragma mark - Buttons

- (void)buttonTap:(NSView *)sender
{
    [self.step buttonTap:sender];
}

#pragma mark - NSObject

- (NSString *)description
{
    NSMutableString *description = [[super description] mutableCopy];
    [description insertString:[NSString stringWithFormat:@", step: %@", [self.step class]] atIndex:([description length]-1)];
    return [description copy];
}

@end
