//
//  FBDownloadManager.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/9/1.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import Foundation

class FBDownloadBytesProgress {
    /// 表示自上次调用该方法后，接收到的数据字节数
    public var bytesWritten: Int64 = 0
    /// 表示目前已经接收到的数据字节数
    public var totalBytesWritten: Int64 = 0
    /// 表示期望收到的文件总字节数
    public var totalBytesExpectedToWrite: Int64 = 0
}

class FBDownloadTaskModel {
    public lazy var progress = FBDownloadBytesProgress()
    public var sessionTask: URLSessionTask?
    public var progressBlock: ((_ progress: FBDownloadBytesProgress)->())?
    public var destinationBlock: ((_ tmpURL: URL, _ response: URLResponse)-> URL)?
    public var completionBlock: ((_ response: URLResponse)->())?
}

class FBDownloadManager: NSObject {
    // MARK: - 属性
    /// 单例
    public static let `default` = FBDownloadManager()
    
    /// 下载管理队列
    public lazy var queue = OperationQueue()
    
    public lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    public lazy var downloadTasks = [FBDownloadTaskModel]()
    
    // MARK: - 初始化
    private override init() {
        super.init()
        
        // 获取保存文件路径
//        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
//        // 准备路径
//        let savePath = (path as NSString).appendingPathComponent("1-2.zip")
//        downloadFile(urlString: "https://yunnto.oss-cn-shenzhen.aliyuncs.com/List/H5/sequence/dyc/loucengquanshi/1-2.zip", savePath: savePath)
    }
    
    /// 判断文件是否存在
    func isExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}

// MARK: 下载的方法
extension FBDownloadManager {
    func downloadFile(urlString: String,
                      progress: @escaping (_ progress: FBDownloadBytesProgress)->(),
                      destination: @escaping (_ tmpURL: URL, _ response: URLResponse)-> URL,
                      completion: @escaping (_ response: URLResponse)->()) {
        guard let url = URL(string: urlString) else {
            print("无效 urlString")
            return
        }
        
        // 创建任务
        let downloadTask = FBDownloadTaskModel()
        downloadTask.sessionTask = session.downloadTask(with: url)
        downloadTask.progressBlock = progress
        downloadTask.destinationBlock = destination
        downloadTask.completionBlock = completion
        
        // 保存任务信息
        downloadTasks.append(downloadTask)
        
        // 开启任务
        downloadTask.sessionTask?.resume()
    }
}

// MARK: 下载任务代理方法
extension FBDownloadManager: URLSessionDownloadDelegate {
    // 下载完成
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        
        for model in downloadTasks {
            if model.sessionTask == downloadTask {
                
                break
            }
        }
        
        print("下载完成: ", location)
        
        let fileName = downloadTask.response?.suggestedFilename ?? ""
        
        // 获取保存文件路径
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]// 准备路径
        let louCengPath = (path as NSString).appendingPathComponent(fileName)
        
        // 保存文件
        try? FileManager.default.moveItem(atPath: location.path, toPath: louCengPath)
    }
    
    // 下载进度
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        
        for model in downloadTasks {
            if model.sessionTask == downloadTask {
                model.progress.bytesWritten = bytesWritten
                model.progress.totalBytesWritten = totalBytesWritten
                model.progress.totalBytesExpectedToWrite = totalBytesExpectedToWrite
                model.progressBlock?(model.progress)
                break
            }
        }
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        print(String(format: "下载进度: %.2f", progress))
    }
    
    // 恢复下载时的进度
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64,
                           expectedTotalBytes: Int64) {
        let progress = expectedTotalBytes
        print("恢复下载时的下载进度: %0.2f", progress)
    }
}
