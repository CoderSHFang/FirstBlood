//
//  FBDownloadManager.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/9/1.
//  Copyright © 2020 Mac mini. All rights reserved.
//
import UIKit

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
    public var resumeData: Data?
    public var sessionTask: URLSessionTask?
    public var progressBlock: ((_ progress: FBDownloadBytesProgress)->())?
    public var destinationBlock: ((_ tmpURL: URL, _ response: URLResponse?)-> URL)?
    public var completionBlock: ((_ filePath: String, _ response: URLResponse?, _ error: Error?)->())?
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
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationwillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
    
    /// 判断文件是否存在
    func isExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}

@objc private extension FBDownloadManager {
    /// 即将进入前台
    func willEnterForeground() {
        print("willEnterForeground: 即将进入前台")
    }
    
    /// 程序从后台进入激活
    func didBecomeActive() {
        print("didBecomeActive: 程序从后台进入激活")
        
        // 开始任务下载
        for model in downloadTasks {
            guard let resumeData = model.resumeData else {
                continue
            }
            
            model.sessionTask = session.downloadTask(withResumeData: resumeData)
            model.sessionTask?.resume()
        }
    }
    
    /// 程序即将从前台退出活动
    func willResignActive() {
        print("willResignActive: 程序即将从前台退出活动")
        
        // 停止任务下载
        for model in downloadTasks {
            guard let task = model.sessionTask,
                let downloadTask = task as? URLSessionDownloadTask
                else {
                continue
            }
            
            downloadTask.cancel { (data) in
                model.resumeData = data
            }
        }
    }
    
    /// 进入后台
    func didEnterBackground() {
        print("didEnterBackground: 进入后台")
    }
    
    /// 程序即将终止
    func applicationwillTerminate() {
        print("applicationwillTerminate: 程序即将终止")
    }
}

// MARK: 下载的方法
extension FBDownloadManager {
    /// 取消下载
    /// - Parameter downloadTaskModel: 下载任务的模型
    /// - Parameter completionHandler: 完成回调
    /// - Returns: resumeData
    func cancelDownload(at downloadTaskModel: FBDownloadTaskModel,
                        byProducingResumeData completionHandler: @escaping (Data?) -> Void) {
        let address1 = Unmanaged.passUnretained(downloadTaskModel).toOpaque()
        
        let completion = { (resumeData: Data?)->() in
            downloadTaskModel.resumeData = resumeData
            completionHandler(resumeData)
        }
        
        for model in downloadTasks {
            let address2 = Unmanaged.passUnretained(model).toOpaque()
            
            if address1 == address2 {
                guard let downloadTask = model.sessionTask as? URLSessionDownloadTask else {
                    return
                }
                
                downloadTask.cancel(byProducingResumeData: completion)
                
                break
            }
        }
    }
    
    /// 下载文件的方法
    /// - Parameters:
    ///   - urlString: urlString
    ///   - progress: 下载进度
    ///   - destination: 保存文件的路径
    ///   - completion: 完成回调
    func downloadFile(urlString: String,
                      progress: @escaping (_ progress: FBDownloadBytesProgress)->(),
                      destination: @escaping (_ tmpURL: URL, _ response: URLResponse?)-> URL,
                      completion: @escaping (_ filePath: String, _ response: URLResponse?, _ error: Error?)->()) -> FBDownloadTaskModel? {
        guard let url = URL(string: urlString) else {
            print("无效 urlString")
            return nil
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
        
        return downloadTask
    }
    
    /// 断点续传下载文件的方法
    /// - Parameters:
    ///   - resumeData: 恢复数据
    ///   - progress: 下载进度
    ///   - destination: 保存文件的路径
    ///   - completion: 完成回调
    func downloadFile(resumeData: Data,
                      progress: @escaping (_ progress: FBDownloadBytesProgress)->(),
                      destination: @escaping (_ tmpURL: URL, _ response: URLResponse?)-> URL,
                      completion: @escaping (_ filePath: String, _ response: URLResponse?, _ error: Error?)->()) -> FBDownloadTaskModel? {
        
        var downloadTask: FBDownloadTaskModel?
        for model in downloadTasks {
            if resumeData != model.resumeData {
                continue
            }
            
            model.sessionTask = session.downloadTask(withResumeData: resumeData)
            model.progressBlock = progress
            model.destinationBlock = destination
            model.completionBlock = completion
            model.sessionTask?.resume()
            downloadTask = model
            break
        }
        
        return downloadTask
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
                // 保存文件
                let cacheURL = model.destinationBlock?(location, downloadTask.response)
                let cachePath = cacheURL?.path ?? ""
                try? FileManager.default.moveItem(atPath: location.path, toPath: cachePath)
                
                // 完成回调
                model.completionBlock?(cachePath, downloadTask.response, downloadTask.error)
                break
            }
        }
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
