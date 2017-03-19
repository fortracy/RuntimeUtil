//
//  CLComponentRuntimeUtils.m
//  ComponentLinkDemo
//
//  Created by newworld on 2017/3/2.
//  Copyright © 2017年 zhenby. All rights reserved.
//

#import "RunTimeUtil.h"


@implementation RuntimeUtils


+ (Class) classWithName:(NSString *)className withLoad:(BOOL)load
{
    Class clazz = NULL;
    if (load) {
        //call class callback
        clazz = objc_getClass(className.UTF8String);
    }else{
        //just search
        clazz = objc_lookUpClass(className.UTF8String);
    }
    
    return clazz;
}


+ (NSSet *) propertyNameForClass:(Class)clazz
{
    return [NSSet setWithArray:[self propertyNameWithClassForClass:clazz].allKeys];
}

+ (NSSet *) nameForClass:(Class)clazz type:(ObjcType)ojcType
{
    NSSet *names = nil;
    switch (ojcType) {
        case ObjcTypeIvar:
            //TODO: IVAR
            
            break;
        case ObjcTypeProperty:
            return [self propertyNameForClass:clazz];
            
        default:
            break;
    }
    return names;
}

+ (NSDictionary *) propertyNameWithClassForClass:(Class)clazz
{
    NSMutableDictionary *currentClassPropertyNameWithClass = nil;
    
    if (!clazz || clazz == NSObject.class || clazz == [NSNull null]) {
        return currentClassPropertyNameWithClass;
    }
    currentClassPropertyNameWithClass = [NSMutableDictionary dictionary];
    unsigned int propertyCount = 0;
    //get all property of clazz
    objc_property_t *clazzProperties = class_copyPropertyList(clazz, &propertyCount);
    for (unsigned int index = 0; index<propertyCount; index++) {
        objc_property_t property = clazzProperties[index];
        const char *propertyName = property_getName(property);
        if (propertyName) {
            NSString *name = [NSString stringWithUTF8String:propertyName];
            //get property class
            id propertyClass = (id)[self classOfProperty:property] ?: [NSNull null];
            currentClassPropertyNameWithClass[name] = propertyClass;
        }
    }
    free(clazzProperties);
    
    //get superClassProperty
    NSDictionary *superClassPropertyWithClass = [self propertyNameWithClassForClass:[clazz superclass]];
    
    NSMutableDictionary * combinePropertyWithClass = [NSMutableDictionary dictionaryWithDictionary:currentClassPropertyNameWithClass];
    if (superClassPropertyWithClass && superClassPropertyWithClass.count>0) {
        [combinePropertyWithClass addEntriesFromDictionary:superClassPropertyWithClass];
    }
    
    return combinePropertyWithClass;
    
}


+ (Class) classOfProperty:(objc_property_t)property {
    NSString* propertyAttributesDescription = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
    char *name = property_getName(property);
    NSArray* splitPropertyAttributes = [propertyAttributesDescription componentsSeparatedByString:@"\""];
    if ( [propertyAttributesDescription hasPrefix:@"T@"] && [splitPropertyAttributes count] > 1 ) {
        return [self classWithName:splitPropertyAttributes[1] withLoad:NO];
    } else {
        return nil;
    }
}



+ (NSString *) stringTypeOfProperty:(objc_property_t)property
{
    char *propertyType = property_copyAttributeValue(property,"T");
    NSString *type = [NSString stringWithFormat:@"%s",propertyType];
    free(propertyType);
    
    //TODO: 类型反解,不只是OC对象
    switch (1) {
        case 'c':
            return @"char";
            
        default:
            break;
    }
    
    
    
    
    return type;
}



#pragma mark - search

+ (BOOL) doesClass:(Class)clazz search:(NSString *)name type:(ObjcType)objcType superClass:(BOOL)search
{
    BOOL has = NO;
    has = [self doesClass:clazz search:name type:objcType];
    if (search && !has) {
        has = [self doesClass:[clazz superclass] search:name type:objcType superClass:YES];
    }
    
    return has;
}



+(BOOL) doesClass:(Class)clazz search:(NSString *)name type:(ObjcType)objcType
{
    BOOL has = NO;
    if (clazz == NULL || clazz == [NSNull null] || !name) {
        return has;
    }
    
    NSString *searchName = name;
    
    
    switch (objcType) {
        case ObjcTypeProperty:
            has = [self doesClass:clazz hasProperty:searchName];
            
            break;
        case ObjcTypeIvar:
            has = [self doesClass:clazz hasIvar:searchName];
            
            break;
            
        default:
            break;
    }
    
    return has;
}

+ (BOOL) doesClass:(Class)clazz hasProperty:(NSString *)propertyName
{
    BOOL hasProperty = NO;
    
    if (clazz == NULL || clazz == [NSNull null] || !propertyName) {
        return hasProperty;
    }
    
    NSString *searchProperty = propertyName;
    
    unsigned int propertyCount = 0;
    //get all property of clazz
    objc_property_t *clazzProperties = class_copyPropertyList(clazz, &propertyCount);
    for (unsigned int index = 0; index<propertyCount; index++) {
        objc_property_t property = clazzProperties[index];
        const char *propertyName = property_getName(property);
        if (propertyName) {
            NSString *name = [NSString stringWithUTF8String:propertyName];
            if ([name isEqualToString:searchProperty]) {
                hasProperty = YES;
                break;
            }
        }
    }
    free(clazzProperties);
    
    return hasProperty;
}


+ (BOOL) doesClass:(Class)clazz hasIvar:(NSString *)IvarName
{
    BOOL hasIvar = NO;
    
    if (clazz == NULL || clazz == [NSNull null] || !IvarName) {
        return hasIvar;
    }
    
    NSString *searchIvar = IvarName;
    
    unsigned int ivarCount = 0;
    //get all property of clazz
    Ivar* clazzIvar = class_copyIvarList(clazz, &ivarCount);
    for (unsigned int index = 0; index<ivarCount; index++) {
        Ivar ivar = clazzIvar[index];
        const char *propertyName = ivar_getName(ivar);
        if (propertyName) {
            NSString *name = [NSString stringWithUTF8String:propertyName];
            if ([name isEqualToString:searchIvar]) {
                hasIvar = YES;
                break;
            }
        }
    }
    free(clazzIvar);
    
    return hasIvar;
}

//type encoding
//c A char
//i An int
//s A short
//l A long
//l is treated as a 32-bit quantity on 64-bit programs.
//q A long long
//C An unsigned char
//I An unsigned int
//S An unsigned short
//L An unsigned long
//Q An unsigned long long
//f A float
//d A double
//B A C++ bool or a C99 _Bool
//v A void
//* A character string (char *)
//@ An object (whether statically typed or typed id)
//# A class object (Class)
//: A method selector (SEL)
//[array type] An array
//{name=type...} A structure
//(name=type...) A union
//bnum A bit field of num bits
//^type A pointer to type
//? An unknown type (among other things, this code is used for function pointers)

//property encoding
//Code	Meaning
//R	The property is read-only (readonly).
//C	The property is a copy of the value last assigned (copy).
//&	The property is a reference to the value last assigned (retain).
//N	The property is non-atomic (nonatomic).
//G<name>	The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
//S<name>	The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,)
//D	The property is dynamic (@dynamic).
//W	The property is a weak reference (__weak).
//P	The property is eligible for garbage collection.
//t<encoding>	Specifies the type using old-style encoding.

//method encoding
//v means void return type
//12 means the size of the argument frame (12 bytes)
//@0 means that there is an Objective-C object type at byte offset 0 of the argument frame (this is the implicit self object in each Objective-C method)
//:4 means that there is a selector at byte offset 4 (this is the implicit _cmd in every method, which is the selector that was used to invoke the method).
//@8 means that there is another Objective-C object type at byte offset 8.



@end
