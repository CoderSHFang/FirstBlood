//
//  FBCacheTool.m
//  Doctor
//
//  Created by gg on 2019/3/15.
//  Copyright © 2019年 gg. All rights reserved.
//

#import "FBCacheTool.h"

@implementation FBCacheTool
// 把对象归档存到沙盒里
+ (BOOL)saveObject:(id)object byFileName:(NSString *)fileName {
    NSString *path  = [self appendFilePath:fileName];
    path = [path stringByAppendingString:@".archive"];
    BOOL success = [NSKeyedArchiver archiveRootObject:object toFile:path];
    return success;
}

// 通过文件名从沙盒中找到归档的对象
+ (id)getObjectByFileName:(NSString*)fileName {
    NSString *path  = [self appendFilePath:fileName];
    path = [path stringByAppendingString:@".archive"];
    id obj =  [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    return obj;
}

// 根据文件名删除沙盒中的文件
+ (void)removeObjectByFileName:(NSString *)fileName {
    NSString *path  = [self appendFilePath:fileName];
    path = [path stringByAppendingString:@".archive"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
}

/**
 *  删除本地指定元素
 */
+ (void)clearAppointUserDefaultsData
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"domains"];
}

// 拼接文件路径
+ (NSString *)appendFilePath:(NSString *)fileName {
    
    // 1. 沙盒缓存路径
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",cachesPath,fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return filePath;
}

#pragma mark - User Default
// 存储用户偏好设置
+ (void)saveUserData:(id)data forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 读取用户偏好设置
+ (id)readUserDataForKey:(NSString *)key {
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return obj;
    
}

// 删除用户偏好设置
+ (void)removeUserDataForkey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
