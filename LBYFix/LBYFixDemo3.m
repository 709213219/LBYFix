//
//  LBYFixDemo3.m
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/19.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import "LBYFixDemo3.h"

@implementation LBYFixDemo3

- (void)instanceMethodHasNoParams {
    NSLog(@"instanceMethodHasNoParams");
}

- (void)instanceMethodHasOneParam:(NSString *)param1 {
    NSLog(@"instanceMethodHasOneParam: param1 = %@", param1);
}

- (void)instanceMethodHasTwoParams:(int)param1 param2:(CGFloat)param2 {
    NSLog(@"instanceMethodHasTwoParams: param1 = %i, param2 = %f", param1, param2);
}

- (void)instanceMethodHasMultipleParams:(CGPoint)origin size:(CGSize)size rect:(CGRect)rect {
    NSLog(@"instanceMethodHasMultipleParams: origin = %@, size = %@, rect = %@", NSStringFromCGPoint(origin), NSStringFromCGSize(size), NSStringFromCGRect(rect));
}

+ (void)classMethodHasNoParams {
    NSLog(@"classMethodHasNoParams");
}

+ (void)classMethodHasOneParam:(CGVector)vector {
    NSLog(@"classMethodHasOneParam: vector = %@", NSStringFromCGVector(vector));
}

+ (void)classMethodHasTwoParams:(CGAffineTransform)form form3D:(CATransform3D)form3D {
    NSLog(@"classMethodHasTwoParams: form = %@, form3D = [%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f]", NSStringFromCGAffineTransform(form), form3D.m11, form3D.m12, form3D.m13, form3D.m14, form3D.m21, form3D.m22, form3D.m23, form3D.m24, form3D.m31, form3D.m32, form3D.m33, form3D.m34, form3D.m41, form3D.m42, form3D.m43, form3D.m44);
}

+ (void)classMethodHasMultipleParams:(NSRange)range offset:(UIOffset)offset inset:(UIEdgeInsets)inset {
    NSLog(@"classMethodHasMultipleParams: range = %@, offset = %@, inset = %@", NSStringFromRange(range), NSStringFromUIOffset(offset), NSStringFromUIEdgeInsets(inset));
}

@end
