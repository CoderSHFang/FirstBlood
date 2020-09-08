//
//  YSDownloadViewController.swift
//  DaYueCityHD
//
//  Created by Mac mini on 2020/9/4.
//  Copyright © 2020 Fat brother. All rights reserved.
//

import UIKit
import WebKit
import SSZipArchive
import SnapKit
import AFNetworking

class ViewController: UIViewController {
    private var webView: WKWebView?
    
    private lazy var backView = UIImageView(image: UIImage(named: "download_back_icon"))
    private lazy var iconView = UIImageView(image: UIImage(named: "download_title_icon"))
    private lazy var logoView = UIImageView(image: UIImage(named: "download_logo_icon"))
    private lazy var downloadProgressView = UIProgressView(progressViewStyle: .default)
    private lazy var downloadProgressLabel = UILabel()
    private lazy var downloadItemLabel = UILabel()
    
    private var currentDownloadTask: URLSessionDownloadTask?
    private var currentResumeData: Data?
    private var currentArchiveTuple: (allArchives: [[YSSequenceArchive]], paths: [String])?
    
    var issuspend: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        addObserver()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if issuspend {
            issuspend = false
            currentDownloadTask?.resume()
        }else {
            issuspend = true
            currentDownloadTask?.suspend()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationwillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }
    
}

@objc private extension ViewController {
    func applicationwillTerminate() {
        
        guard let tuple = currentArchiveTuple else {
            return
        }
        
        for (idx, archives) in (tuple.allArchives).enumerated() {
            
            let fileDirectory = tuple.paths[idx]
            
            for model in archives {
                let filePath = fileDirectory + "/\(model.name ?? "")" + ".\(model.extension ?? "")"
                // 删除已下载的 zip 包
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
    }
}

// MARK: 下载资源
private extension ViewController {
    func loadData() {
        loadArchiveInfo {[weak self] (networkModels, isSuccess) in
            
            if isSuccess {
                // 1. 检查本地是否有 archiveInfo
                guard let data = NSData(contentsOfFile: archiveInfoPath),
                    let array = try? JSONSerialization.jsonObject(with: data as Data, options: []) as? [[String: Any]] else {
                        print("本地没有 archiveInfo")
                        self?.downloadAndUnzip(models: networkModels)
                    return
                }
                
                let localModels = array.kj.modelArray(type: YSSequenceArchive.self) as! [YSSequenceArchive]
                
                if networkModels.count != localModels.count {
                    print("本地 archiveInfo 与网络请求的 archiveInfo 不一致")
                    self?.downloadAndUnzip(models: networkModels)
                }else {
                    
                    let count = networkModels.count
                    
                    var newModels = [YSSequenceArchive]()
                    
                    for i in 0..<count {
                        let networkModel = networkModels[i]
                        let localModel = localModels[i]
                        
                        if networkModel.version != localModel.version {
                            newModels.append(networkModel)
                        }
                    }
                    
                    if newModels.count != 0 {
                        print("archiveInfo 有更新")
                        self?.downloadAndUnzip(models: newModels)
                    }else {
                        print("archiveInfo 无更新")
                    }
                }
            }
        }
    }
    
    func loadArchiveInfo(comlpetion: @escaping (_ networkModels: [YSSequenceArchive], _ isSuccess: Bool)->()) {
        let urlString = "http://list.yunnto.cn/api/app/getUploadImgUrl"
        let param = ["project_id": 6]
        FBNetworkManager.shared.request(method: .POST, URLString: urlString, parameters: param) { (json, isSuccess) in
            
            if isSuccess {
                // 取出 result
                guard let json = (json as? [String: Any]),
                    let result = json["data"] as? [[String: Any]]
                    else {
                        print("解析失败")
                        comlpetion([YSSequenceArchive](), false)
                        return
                }
                
                // 转模型数组
                let models = result.kj.modelArray(type: YSSequenceArchive.self) as! [YSSequenceArchive]
                
                comlpetion(models, true)
                
            }else {
                print("暂无网络")
                comlpetion([YSSequenceArchive](), false)
            }
        }
    }
    
    /// 对压缩包进行分类
    func classifyArchive(models: [YSSequenceArchive]) -> (allArchives: [[YSSequenceArchive]], paths: [String]) {
        // 准备分类好的模型数组
        var louCengArchives = [YSSequenceArchive]()
        var sanWeiArchives = [YSSequenceArchive]()
        var manYouArchives = [YSSequenceArchive]()
        
        // 资源分类
        for model in models {
            // 楼层诠释
            if model.type == 1 {
                louCengArchives.append(model)
                continue
            }
            
            // 三维沙盘
            if model.type == 2 {
                sanWeiArchives.append(model)
                continue
            }
            
            // 园林漫游
            if model.type == 3 {
                manYouArchives.append(model)
                continue
            }
        }
        
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        
        // 准备路径
        let louCengPath = (path as NSString).appendingPathComponent("louCeng")
        let sanWeiPath = (path as NSString).appendingPathComponent("sanWei")
        let manYouPath = (path as NSString).appendingPathComponent("manYou")
        
        return ([louCengArchives, sanWeiArchives, manYouArchives],
                [louCengPath, sanWeiPath, manYouPath])
//        return ([louCengArchives], [louCengPath])
    }
}

// MARK: 下载图像的方法
private extension ViewController {
    func downloadAndUnzip(models: [YSSequenceArchive]) {
        let tuple = classifyArchive(models: models)
        
        currentArchiveTuple = tuple
        
        downloadAllSequences(at: tuple.allArchives, paths: tuple.paths, comlpetion: { [weak self] in
            
            // 解压
            for (idx, archives) in (tuple.allArchives).enumerated() {
                
                let fileDirectory = tuple.paths[idx]
                
                for model in archives {
                    let filePath = fileDirectory + "/\(model.name ?? "")" + ".\(model.extension ?? "")"
                    self?.archiveUnzip(filePath: filePath, toDestination: fileDirectory)
                }
            }
            
            // 保存下载信息
            guard let data = try? JSONSerialization.data(withJSONObject: models.kj.JSONObjectArray(), options: []) else {
                return
            }
            
            (data as NSData).write(toFile: archiveInfoPath, atomically: true)
            
            // 完成!
        })
    }
    
    /// 下载所有图像的方法
    func downloadAllSequences(at allArchives: [[YSSequenceArchive]], paths: [String], comlpetion: @escaping ()->()) {
        // 1. 创建队列
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        var ops = [BlockOperation]()
        
        let semaphoreSignal = DispatchSemaphore(value: 1)
        
        for (idx, archives) in allArchives.enumerated() {
            let op = BlockOperation { [weak self] in
                semaphoreSignal.wait()
                
                self?.downloadGroupSequences(models: archives, cachesPath: paths[idx]) {
                    
                    // 所有的操作已完成
                    if queue.operations.count == 0 {
                        comlpetion()
                    }
                    
                    semaphoreSignal.signal()
                }
                
            }
            
            ops.append(op)
        }
        
        // 添加依赖关系
        for (i, op) in ops.enumerated() {
            if i > 0 {
                op.addDependency(ops[i - 1])
            }
        }
        
        // 添加到队列中
        queue.addOperations(ops, waitUntilFinished: false)
    }
    
    /// 下载 n 组图像的方法
    func downloadGroupSequences(models: [YSSequenceArchive], cachesPath: String, comlpetion: @escaping ()->()) {
        
        // 1. 创建队列
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        var ops = [BlockOperation]()
        
        let semaphoreSignal = DispatchSemaphore(value: 1)
        
        for model in models {
            // 3. 创建任务
            let op = BlockOperation { [weak self] in
                
                semaphoreSignal.wait()
                
                self?.downloadTask(with: queue,
                                   semaphoreSignal: semaphoreSignal,
                                   model: model,
                                   cachesPath: cachesPath,
                                   comlpetion: comlpetion)
            }
            
            ops.append(op)
        }
        
        // 添加依赖关系
        for (i, op) in ops.enumerated() {
            if i > 0 {
                op.addDependency(ops[i - 1])
            }
        }
        
        // 添加到队列中
        queue.addOperations(ops, waitUntilFinished: false)
    }
    
    func downloadTask(with queue: OperationQueue,
                      semaphoreSignal: DispatchSemaphore,
                      model: YSSequenceArchive,
                      cachesPath: String,
                      comlpetion: @escaping ()->()) {
        
        
        guard let url = URL(string: model.url ?? "") else {
            print("URL 创建失败")
            semaphoreSignal.signal()
            return
        }
        let request = URLRequest(url: url)
        
        let task = FBNetworkManager.shared.downloadTask(with: request, progress: {[weak self] (downloadProgress) in
            let progress = 1.0 * Float(downloadProgress.completedUnitCount) / Float(downloadProgress.totalUnitCount)
            self?.updateProgress(progress: progress, text: "下载中")
            
        }, destination: { (tmpURL, response) -> URL in
            
            // 2.3 创建一个空的文件夹
            if FileManager.default.fileExists(atPath: cachesPath) == false {
                try? FileManager.default.createDirectory(atPath: cachesPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            return URL(fileURLWithPath: cachesPath + "/\(model.name ?? "")" + ".\(model.extension ?? "")")
            
        }) { [weak self] (response, filePath, error) in
            print("filePath: \(String(describing: filePath))")
            
            if let error = (error as NSError?),
                let resumeData = error.userInfo["NSURLSessionDownloadTaskResumeData"] as? Data {
                
                self?.currentResumeData = resumeData
                
                self?.downloadTaskResumeData(with: queue,
                                             semaphoreSignal: semaphoreSignal,
                                             model: model,
                                             cachesPath: cachesPath,
                                             comlpetion: comlpetion)
                
            }else {
                
                self?.currentResumeData = nil
                self?.currentDownloadTask = nil
                
                // 所有的操作都已完成
                if queue.operations.count == 0 {
                    comlpetion()
                }
                
                semaphoreSignal.signal()
            }
            
        }
        
        print(String(format: "正在下载: %@", model.name ?? ""))
        
        currentDownloadTask = task
        task.resume()
    }
    
    func downloadTaskResumeData(with queue: OperationQueue,
                                semaphoreSignal: DispatchSemaphore,
                                model: YSSequenceArchive,
                                cachesPath: String,
                                comlpetion: @escaping ()->()) {
        
        guard let resumeData = currentResumeData else {
            return
        }
        
        let task = FBNetworkManager.shared.downloadTask(withResumeData: resumeData, progress: { [weak self] (downloadProgress) in
            let progress = 1.0 * Float(downloadProgress.completedUnitCount) / Float(downloadProgress.totalUnitCount)
            self?.updateProgress(progress: progress, text: "下载中")
            
        }, destination: { (tmpURL, response) -> URL in
            // 2.3 创建一个空的文件夹
            if FileManager.default.fileExists(atPath: cachesPath) == false {
                try? FileManager.default.createDirectory(atPath: cachesPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            return URL(fileURLWithPath: cachesPath + "/\(model.name ?? "")" + ".\(model.extension ?? "")")
        }) { [weak self] (response, filePath, error) in
            print("filePath: \(String(describing: filePath))")
            
            if let error = (error as NSError?),
                let resumeData = error.userInfo["NSURLSessionDownloadTaskResumeData"] as? Data {
                
                self?.currentResumeData = resumeData
                
                self?.downloadTaskResumeData(with: queue,
                                             semaphoreSignal: semaphoreSignal,
                                             model: model,
                                             cachesPath: cachesPath,
                                             comlpetion: comlpetion)
                
            }else {
                
                self?.currentResumeData = nil
                self?.currentDownloadTask = nil
                
                // 所有的操作都已完成
                if queue.operations.count == 0 {
                    comlpetion()
                }
                
                semaphoreSignal.signal()
            }
        }
        
        print(String(format: "断点下载: %@", model.name ?? ""))
        
        currentDownloadTask = task
        task.resume()
    }
}

// MARK: 解压zip文件的方法
private extension ViewController {
    
    func archiveUnzip(filePath: String, toDestination: String) {
        SSZipArchive.unzipFile(atPath: filePath,
                               toDestination: toDestination,
                               progressHandler: {[weak self] (entry, zipInfo, entryNumber, total) in
                                                
            self?.updateProgress(progress: Float(entryNumber) / Float(total), text: "正在解压")
                                                
        }) { (path, isSuccess, error) in
            // 删除压缩包
            try? FileManager.default.removeItem(atPath: filePath)
        }
    }
}

// MARK: 更新进度的方法
private extension ViewController {
    // 更新进度的方法
    func updateProgress(progress: Float, text: String) {
        DispatchQueue.main.async {
            self.downloadProgressView.progress = 1.0 * progress
            self.downloadProgressLabel.text = String(format: "\(text): %.0f%%", 100.0 * progress)
        }
    }
}

// MARK: 设置 UI 界面
private extension ViewController {
    func setupUI() {
        setupLeftUI()
        setupWebView()
    }
    
    func setupLeftUI() {
        downloadProgressView.tintColor = .white
        downloadProgressView.progress = 0.0
        downloadProgressLabel.textColor = .white
        downloadProgressLabel.text = "下载中...0%"
        downloadItemLabel.font = UIFont.systemFont(ofSize: 12)
        downloadItemLabel.textColor = .white
        
        view.addSubview(backView)
        view.addSubview(iconView)
        view.addSubview(downloadProgressLabel)
        view.addSubview(downloadProgressView)
        view.addSubview(downloadItemLabel)
        view.addSubview(logoView)
       
        backView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        iconView.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(120)
            make.left.equalTo(view).offset(80)
        }
       
        downloadProgressLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(iconView)
            make.top.equalTo(iconView.snp.bottom).offset(100)
        }

        downloadProgressView.snp.makeConstraints { (make) in
            make.centerX.equalTo(iconView)
            make.top.equalTo(downloadProgressLabel.snp.bottom).offset(10)
            make.width.equalTo(400)
        }
        
        downloadItemLabel.snp.makeConstraints { (make) in
            make.top.equalTo(downloadProgressView.snp.bottom).offset(10)
            make.right.equalTo(downloadProgressView.snp.right)
        }

        logoView.snp.makeConstraints { (make) in
            make.centerX.equalTo(iconView)
            make.top.equalTo(downloadProgressView.snp.bottom).offset(150)
        }
    }
    
    func setupWebView() {
        // 创建WKWebViewConfiguration
        let configuration = WKWebViewConfiguration()
        
        //  偏好设置
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // 实例化对象,添加与 H5 交互的方法
        configuration.userContentController = WKUserContentController()
        
        // 创建 webView
        webView = WKWebView(frame: UIScreen.main.bounds, configuration: configuration)
        webView?.isOpaque = false
        webView?.backgroundColor = .black
        
        loadWebView(fileName: "download")
        
        view.addSubview(webView!)
        webView?.snp.makeConstraints({ (make) in
            make.top.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.bottom.equalTo(view).offset(-20)
            make.width.equalTo(380)
        })
    }
    
    func loadWebView(fileName: String) {
        // 加载本地 HTML
        guard let htmlPath = Bundle.main.path(forResource: "tour",
                                              ofType: "html",
                                              inDirectory: "HTMLFile/" + fileName)
            else {
            return
        }
        
        webView?.loadFileURL(URL(fileURLWithPath: htmlPath),
                             allowingReadAccessTo: URL(fileURLWithPath: Bundle.main.bundlePath))
    }
}
