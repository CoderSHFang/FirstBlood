//
//  FBCacheTool.h
//  Doctor
//
//  Created by gg on 2019/3/15.
//  Copyright © 2019年 gg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBCacheTool : NSObject
/**
 *  把对象归档存到沙盒里Cache路径下
 */
+ (BOOL)saveObject:(id)object byFileName:(NSString*)fileName;

/**
 *  通过文件名从沙盒中找到归档的对象
 */
+ (id)getObjectByFileName:(NSString*)fileName;

/**
 *  根据文件名删除沙盒中的归档对象
 */
+ (void)removeObjectByFileName:(NSString*)fileName;

/**
 *  存储用户偏好设置 到 NSUserDefults
 */
+ (void)saveUserData:(id)data forKey:(NSString*)key;

/**
 *  读取用户偏好设置
 */
+(id)readUserDataForKey:(NSString*)key;

/**
 *  删除用户偏好设置
 */
+(void)removeUserDataForkey:(NSString*)key;
/**
 *  删除本地指定元素
 */
+ (void)clearAppointUserDefaultsData;
@end
