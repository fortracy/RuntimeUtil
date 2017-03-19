//
//  CLComponentRuntimeUtils.h
//  ComponentLinkDemo
//
//  Created by newworld on 2017/3/2.
//  Copyright © 2017年 zhenby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger,ObjcType){
    ObjcTypeProperty,
    ObjcTypeIvar,
    ObjcTypeBoth
};

@interface RuntimeUtils : NSObject

+ (Class) classWithName:(NSString *)className withLoad:(BOOL)load;

+(NSSet *) nameForClass:(Class)clazz type:(ObjcType)ojcType;

+ (BOOL) doesClass:(Class)clazz search:(NSString *)name type:(ObjcType)objcType;

+ (BOOL) doesClass:(Class)clazz search:(NSString *)name type:(ObjcType)objcType superClass:(BOOL)search;


@end
