//
//  NSString+FBExtension.m
//
//  Created on 2019/8/26.
//  Copyright © 2019 Fat brther. All rights reserved.
//

#import "NSString+FBExtension.h"

@implementation NSString (FBExtension)
// URLEncoded编码
- (NSString *)URLEncodedString {
    NSString *unencodedString = self;
    NSString *encodedString = (NSString *)
    [unencodedString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //        [unencodedString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<>"].invertedSet];
    
    
//    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                              (CFStringRef)unencodedString,
//                                                              NULL,
//                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
//                                                              kCFStringEncodingUTF8));
    return encodedString;
}

// URLDecode解码
- (NSString *)URLDecodedString {
    NSString *result = [(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    // [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
    return [result stringByRemovingPercentEncoding];
}

// 判断字符串是否为空
+ (BOOL)isEmptyString:(NSString *)string {
    if (!string || [string isKindOfClass:[NSNull class]] || !string.length || ![string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length) {
        return YES;
    }
    
    return NO;
}

/// 从当前字符串中，提取文本
- (NSString *)fb_href {
    // 0. 匹配方案
    NSString *pattern = @"<a href=\"(.*?)\" .*?>(.*?)</a>";
    
    // 1. 创建正则表达式，并且匹配第一项
    NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *result = [regx firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    

    // 2. 获取结果
    NSString *text = [self substringWithRange:[result rangeAtIndex:2]];
    return text;
}
@end
