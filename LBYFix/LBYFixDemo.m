//
//  LBYFixDemo.m
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/16.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import "LBYFixDemo.h"

@implementation LBYFixDemo

- (void)instanceMightCrash:(id)object {
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:object];
    NSLog(@"instanceMethod mightCrash object = %@", object);
}

- (void)runBeforeInstanceMethod {
    NSLog(@"run Before Instance Method");
}

- (void)runAfterInstanceMethod {
    NSLog(@"run After Instance Method");
}

- (void)beforeInstanceMethod:(NSString *)param1 param2:(int)param2 {
    NSLog(@"Before Instance Method: param1 = %@, param = %i", param1, param2);
}

- (void)afterInstanceMethod {
    NSLog(@"After Instance Method");
}

@end
