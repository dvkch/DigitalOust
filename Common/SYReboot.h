//
//  SYReboot.h
//  DigitalOust
//
//  Created by Stan Chevallier on 18/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SYReboot : NSObject

+ (void)askForRebootNow;
+ (void)askForReboot60Alert;
+ (void)askForReboot60Notif;
+ (BOOL)launchOnLogin;
+ (void)setLaunchOnLogin:(BOOL)launchOnLogin;

@end
