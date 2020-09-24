//
//  NSString+FBExtension.h
//
//  Created on 2019/8/26.
//  Copyright © 2019 Fat brther. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (FBExtension)
/// URLEncoded编码
- (NSString *)URLEncodedString;
/// URLDecode解码
- (NSString *)URLDecodedString;

/// 判断是否是空字符串
/// @param string 字符串
+ (BOOL)isEmptyString:(NSString *)string;

/// 从当前字符串中，提取文本
- (NSString *)fb_href;

@end

NS_ASSUME_NONNULL_END
