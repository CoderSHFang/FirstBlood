//
//  FBAlertView.m
//
//  Created on 2019/8/7.
//  Copyright © 2019 Fat brther. All rights reserved.
//

#import "FBAlertView.h"
#import "NSString+FBExtension.h"

@implementation FBAlertView
//  弹出有提示标题，只有一个按钮的提示窗口，按钮字体颜色为蓝色
+ (void)alertControllerWithTitle:(NSString *)title message:(nullable NSString *)message actionTitle:(nullable NSString *)actionTitle ctrl:(nonnull UIViewController *)containCtrl finishBlock:(nullable void (^)(void))finishBlock {
    //初始化
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        !finishBlock?:finishBlock();
    }];
    
    [alertController addAction:action];
    
    [containCtrl presentViewController:alertController animated:YES completion:nil];
}

//弹出有提示标题，有两一个按钮的提示窗口，按钮字体颜色均为蓝色
+ (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message leftTitle:(nonnull NSString *)leftTitle rightTitle:(nonnull NSString *)rightTitle ctrl:(nonnull UIViewController *)containCtrl finishBlock:(nonnull void (^)(NSString * _Nonnull))finishBlock {
    //初始化
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:leftTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        !finishBlock?:finishBlock(leftTitle);
    }];
    
    UIAlertAction *sure = [UIAlertAction actionWithTitle:rightTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        !finishBlock?:finishBlock(rightTitle);
    }];
    
    [alertController addAction:cancel];
    [alertController addAction:sure];
    
    [containCtrl presentViewController:alertController animated:YES completion:nil];
}

//弹出没有提示标题，只有一个按钮的提示窗口，按钮字体颜色为系统默认的蓝色
+ (void)alertControllerWithMessage:(NSString *)message actionTitle:(NSString *)actionTitle ctrl:(nonnull UIViewController *)containCtrl finishBlock:(nullable void (^)(void))finishBlock {
    //初始化
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    //设置提示信息
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:message];
    [alertController setValue:attribute forKey:@"attributedTitle"];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        !finishBlock?:finishBlock();
    }];
    
    [alertController addAction:action];
    
    [containCtrl presentViewController:alertController animated:YES completion:nil];
}

//弹出没有提示标题，有两个按钮的的提示窗口，左右两边的按钮字体颜色都是系统默认的蓝色
+ (void)alertControllerWithMessage:(NSString *)message leftTitle:(nonnull NSString *)leftTitle rightTitle:(nonnull NSString *)rightTitle ctrl:(nonnull UIViewController *)containCtrl finishBlock:(nonnull void (^)(NSString * _Nonnull))finishBlock {
    //初始化
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    //设置提示信息
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:message];
    [alertController setValue:attribute forKey:@"attributedTitle"];
    
    //取消按钮
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:leftTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        !finishBlock?:finishBlock(leftTitle);
    }];
    //确定按钮
    UIAlertAction *sure = [UIAlertAction actionWithTitle:rightTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        !finishBlock?:finishBlock(rightTitle);
    }];
    
    [alertController addAction:cancel];
    [alertController addAction:sure];
    
    [containCtrl presentViewController:alertController animated:YES completion:nil];
}

//从底部弹出的列表弹窗(在底部有取消按钮的，按钮标题可自定义)
+ (void)alertControllerSheetWithCancelButtonTitle:(NSString *)cancel otherButtonTitles:(NSArray<NSString *> *)titles ctrl:(nonnull UIViewController *)containCtrl finishBlock:(void (^)(UIAlertAction * _Nonnull, NSString * _Nonnull, NSInteger))finishBlock {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 0; i < titles.count; i ++) {
        NSString *buttonTitle = titles[i];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            !finishBlock ? : finishBlock(action, buttonTitle, i);
        }];
        [alertController addAction:doneAction];
    }
    
    if (![NSString isEmptyString:cancel]) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
    }
    
    [containCtrl presentViewController:alertController animated:YES completion:nil];
}

@end
