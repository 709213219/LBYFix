//
//  LBYFix.m
//  LBYFix
//
//  Created by 叶晓倩 on 2018/3/12.
//  Copyright © 2018年 acnc. All rights reserved.
//

#import "LBYFix.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIGeometry.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <Aspects/Aspects.h>

@implementation LBYFix

#pragma mark - Singleton
+ (LBYFix *)sharedInstance {
    static LBYFix *fix = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fix = [[self alloc] init];
    });
    return fix;
}

#pragma mark - Public
+ (void)fixIt {
    JSContext *context = [self context];
    
    context[@"fixMethod"] = ^(NSString *instanceName, NSString *selectorName, LBYFixOptions options, BOOL isClassMethod, JSValue *fixImpl) {
        [self fixWithMethod:isClassMethod options:options instanceName:instanceName selectorName:selectorName fixImp:fixImpl];
    };
    
    context[@"runInvocation"] = ^(NSInvocation *invocation) {
        [invocation invoke];
    };
    
    context[@"runErrorBranch"] = ^(NSString *instanceName, NSString *selectorName) {
        NSLog(@"runErrorBranch: instanceName = %@, selectorName = %@", instanceName, selectorName);
    };
    
    context[@"runClassMethod"] = ^id(NSString *className, NSString *selectorName, NSArray *arguments) {
        return [self runClassWithClassName:className selector:selectorName arguments:arguments];
    };
    
    context[@"runInstanceMethod"] = ^id(NSString * className, NSString *selectorName, NSArray *arguments) {
        return [self runInstanceWithInstance:className selector:selectorName arguments:arguments];
    };
}

+ (void)evalString:(NSString *)jsString {
    if (jsString == nil || jsString == (id)[NSNull null] || ![jsString isKindOfClass:[NSString class]]) return;
    
    [[self context] evaluateScript:jsString];
}

#pragma mark - Private
+ (JSContext *)context {
    static JSContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[JSContext alloc] init];
    });
    return context;
}

+ (void)fixWithMethod:(BOOL)isClassMethod options:(LBYFixOptions)options instanceName:(NSString *)instanceName selectorName:(NSString *)selectorName fixImp:(JSValue *)fixImpl {
    Class klass = NSClassFromString(instanceName);
    if (isClassMethod) {
        klass = object_getClass(klass);
    }
    
    SEL sel = NSSelectorFromString(selectorName);
    [klass aspect_hookSelector:sel withOptions:(AspectOptions)options usingBlock:^(id<AspectInfo> aspectInfo) {
        [fixImpl callWithArguments:@[aspectInfo.instance, aspectInfo.originalInvocation, aspectInfo.arguments]];
    } error:nil];
}

+ (id)runClassWithClassName:(NSString *)className selector:(NSString *)selector arguments:(NSArray *)arguments {
    Class klass = NSClassFromString(className);
    if (!klass) return nil;
    
    SEL sel = NSSelectorFromString(selector);
    if (!sel) return nil;
    
    if (![klass respondsToSelector:sel]) return nil;
    
    NSMethodSignature *signature = [klass methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = sel;
    [self setInv:invocation withSig:signature andArgs:arguments];
    [invocation invokeWithTarget:klass];
    
    return [self getReturnFromInv:invocation withSig:signature];
}

+ (id)runInstanceWithInstance:(NSString *)className selector:(NSString *)selector arguments:(NSArray *)arguments {
    Class klass = NSClassFromString(className);
    if (!klass) return nil;
    
    SEL sel = NSSelectorFromString(selector);
    if (!sel) return nil;
    
    id instance = [[klass alloc] init];
    
    if (![instance respondsToSelector:sel]) return nil;
    
    NSMethodSignature *signature = [instance methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = sel;
    [self setInv:invocation withSig:signature andArgs:arguments];
    [invocation invokeWithTarget:instance];
    
    return [self getReturnFromInv:invocation withSig:signature];
}

+ (id)getReturnFromInv:(NSInvocation *)inv withSig:(NSMethodSignature *)sig {
    NSUInteger length = [sig methodReturnLength];
    if (length == 0) return nil;
    
    char *type = (char *)[sig methodReturnType];
    while (*type == 'r' ||  // const
           *type == 'n' ||  // in
           *type == 'N' ||  // inout
           *type == 'o' ||  // out
           *type == 'O' ||  // bycopy
           *type == 'R' ||  // byref
           *type == 'V') {  // oneway
        type++; // cutoff useless prefix
    }
    
#define return_with_number(_type_) \
do { \
_type_ ret; \
[inv getReturnValue:&ret]; \
return @(ret); \
} while(0)
    
    switch (*type) {
        case 'v': return nil; // void
        case 'B': return_with_number(bool);
        case 'c': return_with_number(char);
        case 'C': return_with_number(unsigned char);
        case 's': return_with_number(short);
        case 'S': return_with_number(unsigned short);
        case 'i': return_with_number(int);
        case 'I': return_with_number(unsigned int);
        case 'l': return_with_number(int);
        case 'L': return_with_number(unsigned int);
        case 'q': return_with_number(long long);
        case 'Q': return_with_number(unsigned long long);
        case 'f': return_with_number(float);
        case 'd': return_with_number(double);
        case 'D': { // long double
            long double ret;
            [inv getReturnValue:&ret];
            return [NSNumber numberWithDouble:ret];
        };
            
        case '@': { // id
            void *ret;
            [inv getReturnValue:&ret];
            return (__bridge id)(ret);
        };
            
        case '#' : { // Class
            Class ret = nil;
            [inv getReturnValue:&ret];
            return ret;
        };
            
        default: { // struct / union / SEL / void* / unknown
            const char *objCType = [sig methodReturnType];
            char *buf = calloc(1, length);
            if (!buf) return nil;
            [inv getReturnValue:buf];
            NSValue *value = [NSValue valueWithBytes:buf objCType:objCType];
            free(buf);
            return value;
        };
    }
#undef return_with_number
}

+ (void)setInv:(NSInvocation *)inv withSig:(NSMethodSignature *)sig andArgs:(NSArray *)args {
    
#define args_length_judgments(_index_) \
[self argsLengthJudgment:args index:_index_] \
    
#define set_with_args(_index_, _type_, _sel_) \
do { \
_type_ arg; \
if (args_length_judgments(_index_-2)) { \
arg = [args[_index_-2] _sel_]; \
} \
[inv setArgument:&arg atIndex:_index_]; \
} while(0)
    
#define set_with_args_struct(_dic_, _struct_, _param_, _key_, _sel_) \
do { \
if (_dic_ && [_dic_ isKindOfClass:[NSDictionary class]]) { \
if ([_dic_.allKeys containsObject:_key_]) { \
_struct_._param_ = [_dic_[_key_] _sel_]; \
} \
} \
} while(0)

    NSUInteger count = [sig numberOfArguments];
    for (int index = 2; index < count; index++) {
        char *type = (char *)[sig getArgumentTypeAtIndex:index];
        while (*type == 'r' ||  // const
               *type == 'n' ||  // in
               *type == 'N' ||  // inout
               *type == 'o' ||  // out
               *type == 'O' ||  // bycopy
               *type == 'R' ||  // byref
               *type == 'V') {  // oneway
            type++;             // cutoff useless prefix
        }
        
        BOOL unsupportedType = NO;
        switch (*type) {
            case 'v':   // 1:void
            case 'B':   // 1:bool
            case 'c':   // 1: char / BOOL
            case 'C':   // 1: unsigned char
            case 's':   // 2: short
            case 'S':   // 2: unsigned short
            case 'i':   // 4: int / NSInteger(32bit)
            case 'I':   // 4: unsigned int / NSUInteger(32bit)
            case 'l':   // 4: long(32bit)
            case 'L':   // 4: unsigned long(32bit)
            { // 'char' and 'short' will be promoted to 'int'
                set_with_args(index, int, intValue);
            } break;
                
            case 'q':   // 8: long long / long(64bit) / NSInteger(64bit)
            case 'Q':   // 8: unsigned long long / unsigned long(64bit) / NSUInteger(64bit)
            {
                set_with_args(index, long long, longLongValue);
            } break;
                
            case 'f': // 4: float / CGFloat(32bit)
            {
                set_with_args(index, float, floatValue);
            } break;
                
            case 'd': // 8: double / CGFloat(64bit)
            case 'D': // 16: long double
            {
                set_with_args(index, double, doubleValue);
            } break;
                
            case '*': // char *
            {
                if (args_length_judgments(index-2)) {
                    NSString *arg = args[index-2];
                    if ([arg isKindOfClass:[NSString class]]) {
                        const void *c = [arg UTF8String];
                        [inv setArgument:&c atIndex:index];
                    }
                }
            } break;
                
            case '#': // Class
            {
                if (args_length_judgments(index-2)) {
                    NSString *arg = args[index-2];
                    if ([arg isKindOfClass:[NSString class]]) {
                        Class klass = NSClassFromString(arg);
                        if (klass) {
                            [inv setArgument:&klass atIndex:index];
                        }
                    }
                }
            } break;
                
            case '@': // id
            {
                if (args_length_judgments(index-2)) {
                    id arg = args[index-2];
                    [inv setArgument:&arg atIndex:index];
                }
            } break;

            case '{': // struct
            {
                if (strcmp(type, @encode(CGPoint)) == 0) {
                    CGPoint point = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, point, x, @"x", doubleValue);
                        set_with_args_struct(dict, point, y, @"y", doubleValue);
                    }
                    [inv setArgument:&point atIndex:index];
                } else if (strcmp(type, @encode(CGSize)) == 0) {
                    CGSize size = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, size, width, @"width", doubleValue);
                        set_with_args_struct(dict, size, height, @"height", doubleValue);
                    }
                    [inv setArgument:&size atIndex:index];
                } else if (strcmp(type, @encode(CGRect)) == 0) {
                    CGRect rect;
                    CGPoint origin = {0};
                    CGSize size = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        NSDictionary *pDict = dict[@"origin"];
                        set_with_args_struct(pDict, origin, x, @"x", doubleValue);
                        set_with_args_struct(pDict, origin, y, @"y", doubleValue);
                        
                        NSDictionary *sDict = dict[@"size"];
                        set_with_args_struct(sDict, size, width, @"width", doubleValue);
                        set_with_args_struct(sDict, size, height, @"height", doubleValue);
                    }
                    rect.origin = origin;
                    rect.size = size;
                    [inv setArgument:&rect atIndex:index];
                } else if (strcmp(type, @encode(CGVector)) == 0) {
                    CGVector vector = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, vector, dx, @"dx", doubleValue);
                        set_with_args_struct(dict, vector, dy, @"dy", doubleValue);
                    }
                    [inv setArgument:&vector atIndex:index];
                } else if (strcmp(type, @encode(CGAffineTransform)) == 0) {
                    CGAffineTransform form = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, form, a, @"a", doubleValue);
                        set_with_args_struct(dict, form, b, @"b", doubleValue);
                        set_with_args_struct(dict, form, c, @"c", doubleValue);
                        set_with_args_struct(dict, form, d, @"d", doubleValue);
                        set_with_args_struct(dict, form, tx, @"tx", doubleValue);
                        set_with_args_struct(dict, form, ty, @"ty", doubleValue);
                    }
                    [inv setArgument:&form atIndex:index];
                } else if (strcmp(type, @encode(CATransform3D)) == 0) {
                    CATransform3D form3D = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, form3D, m11, @"m11", doubleValue);
                        set_with_args_struct(dict, form3D, m12, @"m12", doubleValue);
                        set_with_args_struct(dict, form3D, m13, @"m13", doubleValue);
                        set_with_args_struct(dict, form3D, m14, @"m14", doubleValue);
                        set_with_args_struct(dict, form3D, m21, @"m21", doubleValue);
                        set_with_args_struct(dict, form3D, m22, @"m22", doubleValue);
                        set_with_args_struct(dict, form3D, m23, @"m23", doubleValue);
                        set_with_args_struct(dict, form3D, m24, @"m24", doubleValue);
                        set_with_args_struct(dict, form3D, m31, @"m31", doubleValue);
                        set_with_args_struct(dict, form3D, m32, @"m32", doubleValue);
                        set_with_args_struct(dict, form3D, m33, @"m33", doubleValue);
                        set_with_args_struct(dict, form3D, m34, @"m34", doubleValue);
                        set_with_args_struct(dict, form3D, m41, @"m41", doubleValue);
                        set_with_args_struct(dict, form3D, m42, @"m42", doubleValue);
                        set_with_args_struct(dict, form3D, m43, @"m43", doubleValue);
                        set_with_args_struct(dict, form3D, m44, @"m44", doubleValue);
                    }
                    [inv setArgument:&form3D atIndex:index];
                } else if (strcmp(type, @encode(NSRange)) == 0) {
                    NSRange range = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, range, location, @"location", unsignedIntegerValue);
                        set_with_args_struct(dict, range, length, @"length", unsignedIntegerValue);
                    }
                    [inv setArgument:&range atIndex:index];
                } else if (strcmp(type, @encode(UIOffset)) == 0) {
                    UIOffset offset = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, offset, horizontal, @"horizontal", doubleValue);
                        set_with_args_struct(dict, offset, vertical, @"vertical", doubleValue);
                    }
                    [inv setArgument:&offset atIndex:index];
                } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
                    UIEdgeInsets insets = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, insets, top, @"top", doubleValue);
                        set_with_args_struct(dict, insets, left, @"left", doubleValue);
                        set_with_args_struct(dict, insets, bottom, @"bottom", doubleValue);
                        set_with_args_struct(dict, insets, right, @"right", doubleValue);
                    }
                    [inv setArgument:&insets atIndex:index];
                } else {
                    unsupportedType = YES;
                }
            } break;
                
            case '^': // pointer
            {
                unsupportedType = YES;
            } break;
                
            case ':': // SEL
            {
                unsupportedType = YES;
            } break;
                
            case '(': // union
            {
                unsupportedType = YES;
            } break;
                
            case '[': // array
            {
                unsupportedType = YES;
            } break;
                
            default: // what?!
            {
                unsupportedType = YES;
            } break;
        }
        
        NSAssert(!unsupportedType, @"arg unsupportedType");
    }
}

+ (BOOL)argsLengthJudgment:(NSArray *)args index:(NSInteger)index {
    return [args isKindOfClass:[NSArray class]] && index < args.count;
}

@end
