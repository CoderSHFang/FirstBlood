//
//  Common.swift
//  MyProject
//
//  Created by Mac mini on 2020/9/8.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import Foundation
/// 压缩包的下载信息
let archiveInfoPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("archiveInfo.json")
/// 沙盒路径
let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
/// 三维沙盘文件的路径
let sanWeiPath = (path as NSString).appendingPathComponent("sanWei")
/// 园林漫游文件的路径
let manYouPath = (path as NSString).appendingPathComponent("manYou")
