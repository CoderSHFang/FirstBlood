//
//  FBAlertView.h
//
//  Created on 2019/8/7.
//  Copyright © 2019 Fat brther. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/**对系统的警告视图进行封装*/
@interface FBAlertView : NSObject

/**
 弹出有提示标题，只有一个按钮的提示窗口，按钮字体颜色为蓝色

 @param title 提示标题
 @param message 信息内容
 @param actionTitle 按钮标题
 @param containCtrl 提示框显示在哪个控制器上显示
 @param finishBlock 点击按钮的回调,可以置空。
 */
+ (void)alertControllerWithTitle:(nullable NSString *)title
                         message:(nullable NSString *)message
                     actionTitle:(nullable NSString *)actionTitle
                            ctrl:(UIViewController *)containCtrl
                     finishBlock:(nullable void (^)(void))finishBlock;

/**
 弹出有提示标题，有两一个按钮的提示窗口，按钮字体颜色均为蓝色
 
 @param title 提示标题
 @param message 信息内容
 @param leftTitle 左边按钮的标题
 @param rightTitle 右边按钮的标题
 @param containCtrl 提示框显示在哪个控制器上显示
 @param finishBlock 点击按钮的回调,可以置空。
 */
+ (void)alertControllerWithTitle:(nullable NSString *)title
                         message:(nullable NSString *)message
                       leftTitle:(NSString *)leftTitle
                      rightTitle:(NSString *)rightTitle
                            ctrl:(UIViewController *)containCtrl
                     finishBlock:(void (^)(NSString *title))finishBlock;

/**
 弹出没有提示标题，只有一个按钮的提示窗口，
 按钮字体颜色为系统默认的蓝色
 
 @param message 信息内容
 @param actionTitle 按钮标题
 @param containCtrl 提示框显示在哪个控制器上显示
 @param finishBlock 点击按钮的回调,回调的内容是左右按钮的标题。
 */
+ (void)alertControllerWithMessage:(NSString *)message
                       actionTitle:(nullable NSString *)actionTitle
                              ctrl:(UIViewController *)containCtrl
                       finishBlock:(nullable void (^)(void))finishBlock;

/**
 弹出没有提示标题，有两个按钮的的提示窗口，
 左右两边的按钮字体颜色都是系统默认的蓝色
 
 @param message 信息内容
 @param leftTitle 左边按钮的标题
 @param rightTitle 右边按钮的标题
 @param containCtrl 提示框显示在哪个控制器上显示
 @param finishBlock 点击按钮的回调,回调的内容是左右按钮的标题。
 */
+ (void)alertControllerWithMessage:(NSString *)message
                         leftTitle:(NSString *)leftTitle
                        rightTitle:(NSString *)rightTitle
                              ctrl:(UIViewController *)containCtrl
                       finishBlock:(void (^)(NSString *title))finishBlock;

/**
 从底部弹出的列表弹窗(在底部有取消按钮的，按钮标题可自定义)

 @param cancel 取消按钮标题
 @param titles 其他提示标题数组，这里只可以传字符串类型
 @param containCtrl 提示框显示在哪个控制器上显示
 @param finishBlock 点击按钮的回调,回调的内容是标题数组的按钮的信息，不带其他按钮。
 */
+ (void)alertControllerSheetWithCancelButtonTitle:(nullable NSString *)cancel
                                otherButtonTitles:(NSArray<NSString *> *)titles
                                             ctrl:(UIViewController *)containCtrl
                                      finishBlock:(void(^)(UIAlertAction * action,
                                                           NSString *selectedTitle,
                                                           NSInteger selectedIndex))finishBlock;


@end

NS_ASSUME_NONNULL_END
