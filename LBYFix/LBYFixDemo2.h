//
//  LBYFixDemo2.h
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/19.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBYFixDemo2 : NSObject

+ (void)classMightCrash:(id)object;
+ (void)runBeforeClassMethod;
+ (void)runAfterClassMethod;
+ (void)beforeClassMethod;
+ (void)afterClassMethod:(NSString *)param1 param2:(int)param2;

@end
