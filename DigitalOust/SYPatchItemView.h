//
//  SYPatchItemView.h
//  DigitalOust
//
//  Created by Stan Chevallier on 28/06/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SYPatchItemView : NSView

@property (atomic, copy) NSString *(^determineStateBlock)(void);
@property (atomic, copy) BOOL(^useSuccessImageForStateBlock)(NSString *state);
@property (atomic, copy) void(^buttonTappedBlock)(void);

@property (nonatomic, assign) BOOL buttonEnabled;
@property (nonatomic, strong) NSString *descrText;

- (void)setTitleText:(NSString *)title forState:(NSString *)state;
- (void)setButtonText:(NSString *)title forState:(NSString *)state;

- (void)updateState;

@end
