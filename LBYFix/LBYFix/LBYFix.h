//
//  LBYFix.h
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/12.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, LBYFixOptions) {
    LBYFixOptionsBefore     = 0,    // Called before the original implementation
    LBYFixOptionsInstead    = 1,    // Called replace the original implementation
    LBYFixOptionsAfter      = 2,    // Called after the original implementation
};

@interface LBYFix : NSObject

+ (void)fixIt;
+ (void)evalString:(NSString *)jsString;

@end
