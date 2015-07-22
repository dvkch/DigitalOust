//
//  SYKextHelper.h
//  DigitalOust
//
//  Created by Stan Chevallier on 21/07/2015.
//  Copyright © 2015 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SYKextHelper : NSObject

+ (void)listInvalidKextsWithProgress:(void(^)(CGFloat progress))progressBlock
                          completion:(void(^)(NSArray *invalidKexts))completionBlock;

@end
