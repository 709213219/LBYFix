//
//  LBYFixDemo2.m
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/19.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import "LBYFixDemo2.h"

@implementation LBYFixDemo2

+ (void)classMightCrash:(id)object {
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:object];
    NSLog(@"classMethod mightCrash object = %@", object);
}

+ (void)runBeforeClassMethod {
    NSLog(@"run Before Instance Method");
}

+ (void)runAfterClassMethod {
    NSLog(@"run After Class Method");
}

+ (void)beforeClassMethod {
    NSLog(@"Before Class Method");
}

+ (void)afterClassMethod:(NSString *)param1 param2:(int)param2 {
    NSLog(@"After Class Method: param1 = %@, param2 = %i", param1, param2);
}

@end
