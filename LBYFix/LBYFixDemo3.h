//
//  LBYFixDemo3.h
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/19.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LBYFixDemo3 : NSObject

- (void)instanceMethodHasNoParams;
- (void)instanceMethodHasOneParam:(NSString *)param1;
- (void)instanceMethodHasTwoParams:(int)param1 param2:(CGFloat)param2;
- (void)instanceMethodHasMultipleParams:(CGPoint)origin size:(CGSize)size rect:(CGRect)rect;

+ (void)classMethodHasNoParams;
+ (void)classMethodHasOneParam:(CGVector)vector;
+ (void)classMethodHasTwoParams:(CGAffineTransform)form form3D:(CATransform3D)form3D;
+ (void)classMethodHasMultipleParams:(NSRange)range offset:(UIOffset)offset inset:(UIEdgeInsets)inset;

@end
