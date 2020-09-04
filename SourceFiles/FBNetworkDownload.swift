//
//  FBNetworkDownload.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/9/1.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import Foundation

/// 网络下载文件模型
public class FBNetworkDownload {
    /// 下载任务
    var downloadTask: URLSessionDataTask?
    
    /// 下载地址
    var URLString: String?
    
    /// 文件名
    var fileName: String?
    
    /// 文件路径
    var filePath: String?
    
    /// 文件目录
    var fileDirectory: String?
    
    /// 完整文件的大小
    var fileSize: String?
    
    /// 已下载文件的大小，字节长度
    var fileContentLength: Int {
        get{
            if FileManager.default.fileExists(atPath: filePath ?? "") {
                guard let dict = try? FileManager.default.attributesOfItem(atPath: filePath ?? "") else {
                    return 0
                }
                
                return Int((dict as NSDictionary).fileSize())
            }else {
                return 0
            }
        }
    }
    
    /// 文件句柄
    var fileHandle: FileHandle?
    
    /// 从服务器接收数据时记录下载时间，用于计算下载速度
    var downloadDate: Date?
    
    /// 下载进度
    lazy var progress = FBNetworkDownloadProgress()
    
}

/// 网络下载文件进度模型
public class FBNetworkDownloadProgress {
    /// 写入字节的数据长度。
    var totalBytesWritten: Int = 0
    
    /// 预期要写入的总字节数
    var totalBytesExpectedToWrite: Int = 0
    
    /// 文件的总字节数
    var totalBytes: Int = 0
    
    /// 下载速度
    var downloadSpeed: Float = 0.00
    
    /// 下载进度
    var downloadProgress: Float = 0.00
}
