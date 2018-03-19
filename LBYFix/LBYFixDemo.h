//
//  LBYFixDemo.h
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/16.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBYFixDemo : NSObject

- (void)instanceMightCrash:(id)object;
- (void)runBeforeInstanceMethod;
- (void)runAfterInstanceMethod;
- (void)beforeInstanceMethod:(NSString *)param1 param2:(int)param2;
- (void)afterInstanceMethod;

@end
