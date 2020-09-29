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
    private var imageView: UIImageView?
    
    private lazy var backView = UIImageView(image: UIImage(named: "download_back_icon"))
    private lazy var iconView = UIImageView(image: UIImage(named: "download_title_icon"))
    private lazy var logoView = UIImageView(image: UIImage(named: "download_logo_icon"))
    private lazy var downloadProgressView = UIProgressView(progressViewStyle: .default)
    private lazy var downloadProgressLabel = UILabel()
    private lazy var downloadItemLabel = UILabel()
    private lazy var downloadSpeedLabel = UILabel()
    
    private var currentDownloadTask: URLSessionDownloadTask?
    private var currentResumeData: Data?
    private var currentArchiveTuple: (allArchives: [[YSSequenceArchive]], paths: [String])?
    private var networkModels: [YSSequenceArchive]?
    private lazy var downloadSpeed: (date: Date, lastRead: Int64, speed: String) = (Date(), 0, "0 KB")
    
    private var downloadTaskModel: FBDownloadTaskModel?
    private var resumeData: Data?
    
    var downloadCompletion: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupUI()
//        loadData()
//        addObserver()
//        let download = FBDownloadManager.default
        
//        download1()
//        download2()
        
        let windown = UIApplication.shared.windows[0]
        windown.touchIcons = [UIImage(named: "yk_yuanquan_fill_1"),
                                             UIImage(named: "yk_yuanquan_fill_2"),
                                             UIImage(named: "yk_yuanquan_fill_3"),
                                             UIImage(named: "yk_yuanquan_fill_4"),
                                             UIImage(named: "yk_yuanquan_fill_5")]
    }
    
    
    func download2() {
     let urlString = "https://yunnto.oss-cn-shenzhen.aliyuncs.com/List/H5/sequence/dyc/loucengquanshi/1-3.zip"

        _ = FBDownloadManager.default.downloadFile(urlString: urlString, progress: { (downloadProgress) in
            let progress = Float(downloadProgress.totalBytesWritten) / Float(downloadProgress.totalBytesExpectedToWrite)
            print("progress2: \(progress)")
        }, destination: { (tmpURL, response) -> URL in
            let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let cachePath = (path as NSString).appendingPathComponent("1-3.zip")
            let url = URL(fileURLWithPath: cachePath)
            print("cachePath: \(url.path)")
            return url
        }) { (filePath, response, error) in
            print("filePath: \(filePath)")
        }
        
//        self.downloadTaskModel = downloadTaskModel
    }
    
    func download1() {
        let urlString = "https://yunnto.oss-cn-shenzhen.aliyuncs.com/List/H5/sequence/dyc/loucengquanshi/1-2.zip"
        
        _ = FBDownloadManager.default.downloadFile(urlString: urlString, progress: { (downloadProgress) in
            let progress = Float(downloadProgress.totalBytesWritten) / Float(downloadProgress.totalBytesExpectedToWrite)
            print("progress1: \(progress)")
        }, destination: { (tmpURL, response) -> URL in
            let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let cachePath = (path as NSString).appendingPathComponent("1-2.zip")
            let url = URL(fileURLWithPath: cachePath)
            print("cachePath: \(url.path)")
            return url
        }) { (filePath, response, error) in
            print("filePath: \(filePath)")
        }
        
//        self.downloadTaskModel = downloadTaskModel
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        if resumeData == nil {
//            FBDownloadManager.default.cancelDownload(at: downloadTaskModel!) { (data) in
//                self.resumeData = data
//            }
//
//        }else {
//            downloadTaskModel = FBDownloadManager.default.downloadFile(resumeData: resumeData!, progress: { (downloadProgress) in
//                let progress = Float(downloadProgress.totalBytesWritten) / Float(downloadProgress.totalBytesExpectedToWrite)
//                print("progress: \(progress)")
//            }, destination: { (tmpURL, response) -> URL in
//                let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
//                let cachePath = (path as NSString).appendingPathComponent("1-2.zip")
//                let url = URL(fileURLWithPath: cachePath)
//                print("cachePath: \(url.path)")
//                return url
//            }) { (filePath, response, error) in
//                print("filePath: \(filePath)")
//            }
//
//            resumeData = nil
//        }
        
        
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
                self?.networkModels = networkModels
                
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
                        self?.readLocalResourcesTip()
                    }
                }
            }else {
                // 1. 检查本地是否有 archiveInfo
                guard let data = NSData(contentsOfFile: archiveInfoPath),
                    let _ = try? JSONSerialization.jsonObject(with: data as Data, options: []) as? [[String: Any]] else {
                        print("本地没有 archiveInfo")
                        FBAlertView.alertController(withTitle: "提示",
                                                    message: "请链接您的网络下载资源",
                                                    actionTitle: "确定",
                                                    ctrl: self!,
                                                    finish: nil)
                    return
                }
                
                self?.readLocalResourcesTip()
            }
        }
    }
    
    /// 读取本地资源的提示
    func readLocalResourcesTip() {
        var progress: Float = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] (timer) in
            
            if progress >= 1.0 {
                timer.invalidate()
                self?.updateProgress(progressInfo: (1.0, "加载完成", "", ""))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    self?.downloadCompletion?()
                    self?.dismiss(animated: true, completion: nil)
                }
                return
            }else {
                self?.updateProgress(progressInfo: (progress, "正在加载本地资源", "", ""))
            }
            
            progress += 0.01
        }
    }
    
    func loadArchiveInfo(comlpetion: @escaping (_ networkModels: [YSSequenceArchive], _ isSuccess: Bool)->()) {
        let urlString = "http://list.yunnto.cn/api/app/getUploadImgUrl"
        let param = ["project_id": 36]
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
        var sanWeiArchives = [YSSequenceArchive]()
        var manYouArchives = [YSSequenceArchive]()
        
        // 资源分类
        for model in models {
            
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
        
        return ([sanWeiArchives, manYouArchives],
                [sanWeiPath, manYouPath])
    }
}

// MARK: 下载图像的方法
private extension ViewController {
    func downloadAndUnzip(models: [YSSequenceArchive]) {
        let tuple = classifyArchive(models: models)
        
        currentArchiveTuple = tuple
        
        downloadAllSequences(at: tuple.allArchives, paths: tuple.paths, comlpetion: { [weak self] in
            
            self?.downloadSpeedLabel.text = ""
            self?.downloadItemLabel.text = ""
            self?.downloadProgressView.progress = 1.0
            self?.downloadProgressLabel.text = "正在解压中..."
            
            let group = DispatchGroup()
            
            // 解压
            for (idx, archives) in (tuple.allArchives).enumerated() {
                
                if archives.count == 0 {
                    continue
                }
                
                group.enter()
                
                DispatchQueue.global().async {
                    let fileDirectory = tuple.paths[idx]
                    self?.archiveUnzip(archives: archives, toDestination: fileDirectory, comlpetion: {
                        
                        group.leave()
                    })
                }
            }
            
            group.notify(queue: DispatchQueue.main) {
                // 保存下载信息
                guard let networkModels = self?.networkModels,
                    let data = try? JSONSerialization.data(withJSONObject: networkModels.kj.JSONObjectArray(), options: [])
                    else {
                    return
                }
                
                (data as NSData).write(toFile: archiveInfoPath, atomically: true)
                
                // 完成!
                self?.downloadProgressLabel.text = "解压完成!"
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    self?.downloadCompletion?()
                    self?.dismiss(animated: true, completion: nil)
                }
            }
            
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
            
            if archives.count == 0 {
                continue
            }
            
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
        
        for (idx, model) in models.enumerated() {
            // 3. 创建任务
            let op = BlockOperation { [weak self] in
                
                semaphoreSignal.wait()
                
                let requestInfo = (queue, semaphoreSignal, model, cachesPath, idx, models.count)
                self?.downloadTask(with: requestInfo, comlpetion: comlpetion)
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
    
    func downloadTask(with requestInfo: (queue: OperationQueue,
                                        semaphoreSignal: DispatchSemaphore,
                                        model: YSSequenceArchive,
                                        cachesPath: String,
                                        idx: Int,
                                        count: Int),
                      comlpetion: @escaping ()->()) {
        
        guard let url = URL(string: requestInfo.model.url ?? "") else {
            print("URL 创建失败")
            requestInfo.semaphoreSignal.signal()
            return
        }
        
        let request = URLRequest(url: url)
        
        downloadSpeed.date = Date()
        
        let task = FBNetworkManager.shared.downloadTask(with: request, progress: {[weak self] (downloadProgress) in
            self?.calculateDownloadProgress(downloadProgress: downloadProgress,
                                            type: requestInfo.model.type,
                                            idx: requestInfo.idx,
                                            count: requestInfo.count)
            
        }, destination: { (tmpURL, response) -> URL in
            
            // 2.3 创建一个空的文件夹
            if FileManager.default.fileExists(atPath: requestInfo.cachesPath) == false {
                try? FileManager.default.createDirectory(atPath: requestInfo.cachesPath,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
            }
            
            return URL(fileURLWithPath: requestInfo.cachesPath
                                        + "/\(requestInfo.model.name ?? "")"
                                        + ".\(requestInfo.model.extension ?? "")")
            
        }) { [weak self] (response, filePath, error) in
            print("filePath: \(String(describing: filePath))")
            
            if let error = (error as NSError?),
                let resumeData = error.userInfo["NSURLSessionDownloadTaskResumeData"] as? Data {
                
                self?.currentResumeData = resumeData
                self!.downloadSpeed.lastRead = 0
                
                self?.downloadTaskResumeData(with: requestInfo, comlpetion: comlpetion)
                
            }else {
                
                self?.currentResumeData = nil
                self?.currentDownloadTask = nil
                self!.downloadSpeed.lastRead = 0
                
                // 所有的操作都已完成
                if requestInfo.queue.operations.count == 0 {
                    comlpetion()
                }
                
                requestInfo.semaphoreSignal.signal()
            }
            
        }
        
        print(String(format: "正在下载: %@", requestInfo.model.name ?? ""))
        
        currentDownloadTask = task
        task.resume()
    }
    
    func downloadTaskResumeData(with requestInfo: (queue: OperationQueue,
                                                semaphoreSignal: DispatchSemaphore,
                                                model: YSSequenceArchive,
                                                cachesPath: String,
                                                idx: Int,
                                                count: Int),
                                comlpetion: @escaping ()->()) {
        
        guard let resumeData = currentResumeData else {
            return
        }
        
        downloadSpeed.date = Date()
        
        let task = FBNetworkManager.shared.downloadTask(withResumeData: resumeData, progress: { [weak self] (downloadProgress) in
            self?.calculateDownloadProgress(downloadProgress: downloadProgress,
                                            type: requestInfo.model.type,
                                            idx: requestInfo.idx,
                                            count: requestInfo.count)
            
        }, destination: { (tmpURL, response) -> URL in
            // 2.3 创建一个空的文件夹
            if FileManager.default.fileExists(atPath: requestInfo.cachesPath) == false {
                try? FileManager.default.createDirectory(atPath: requestInfo.cachesPath,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
            }
            
            return URL(fileURLWithPath: requestInfo.cachesPath
                                        + "/\(requestInfo.model.name ?? "")"
                                        + ".\(requestInfo.model.extension ?? "")")
            
        }) { [weak self] (response, filePath, error) in
            print("filePath: \(String(describing: filePath))")
            
            if let error = (error as NSError?),
                let resumeData = error.userInfo["NSURLSessionDownloadTaskResumeData"] as? Data {
                
                self?.currentResumeData = resumeData
                self!.downloadSpeed.lastRead = 0
                
                self?.downloadTaskResumeData(with: requestInfo, comlpetion: comlpetion)
                
            }else {
                
                self?.currentResumeData = nil
                self?.currentDownloadTask = nil
                self!.downloadSpeed.lastRead = 0
                
                // 所有的操作都已完成
                if requestInfo.queue.operations.count == 0 {
                    comlpetion()
                }
                
                requestInfo.semaphoreSignal.signal()
            }
        }
        
        print(String(format: "断点下载: %@", requestInfo.model.name ?? ""))
        
        currentDownloadTask = task
        task.resume()
    }
    
    /// 计算下载进度
    /// - Parameters:
    ///   - downloadProgress: Progress
    ///   - type: 下载资源的类型
    ///   - idx: 下载资源的索引
    ///   - count: 下载一组资源的个数
    func calculateDownloadProgress(downloadProgress: Progress,
                                   type: Int,
                                   idx: Int,
                                   count: Int) {
        // 计算下载速度
        let currentDate = Date()
        let time = Int64(currentDate.timeIntervalSince(downloadSpeed.date))
        if time >= 1 {
            let speed = (downloadProgress.completedUnitCount - downloadSpeed.lastRead) / time
            
            let countStyle: ByteCountFormatter.CountStyle = speed > 1024 ? .file : .binary
            
            downloadSpeed.speed = ByteCountFormatter.string(fromByteCount: speed, countStyle: countStyle)
            downloadSpeed.lastRead = downloadProgress.completedUnitCount
            downloadSpeed.date = currentDate
        }
        
        // 计算下载进度
        let progress = 1.0 * Float(downloadProgress.completedUnitCount) / Float(downloadProgress.totalUnitCount)
        
        var resourcesName = ""
        if type == 2 {
            resourcesName = "三维沙盘"
        }
        
        let itemProgress = "正在下载：\(resourcesName)（\(idx + 1)/\(count)）"
        // 更新 UI
        let downSpeed = "下载速度：\(downloadSpeed.speed + "/秒")"
        updateProgress(progressInfo: (progress, "下载进度", itemProgress, downSpeed))
    }
}

// MARK: 解压zip文件的方法
private extension ViewController {
    
    func archiveUnzip(archives: [YSSequenceArchive], toDestination: String, comlpetion: @escaping ()->()) {

        let group = DispatchGroup()
        
        for model in archives {
            group.enter()
            
            DispatchQueue.global().async {
                let filePath = toDestination + "/\(model.name ?? "")" + ".\(model.extension ?? "")"
                SSZipArchive.unzipFile(atPath: filePath, toDestination: toDestination, progressHandler: nil) { (path, isSuccess, error) in
                    try? FileManager.default.removeItem(atPath: filePath)
                    group.leave()
                    
                    if isSuccess {
                        print("解压成功")
                    }else {
                        print("解压失败")
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            comlpetion()
        }
    }
}

// MARK: 更新进度，计算网速的方法
private extension ViewController {
    
    // 更新进度的方法
    func updateProgress(progressInfo: (progress: Float,
                                       tipText: String,
                                       resourcesName: String,
                                       speed: String))
    {
        DispatchQueue.main.async {
            self.downloadSpeedLabel.text = progressInfo.speed
            self.downloadItemLabel.text = progressInfo.resourcesName
            self.downloadProgressView.progress = 1.0 * progressInfo.progress
            self.downloadProgressLabel.text = String(format: "\(progressInfo.tipText): %.0f%%", 100.0 * progressInfo.progress)
        }
    }
}

// MARK: 设置 UI 界面
private extension ViewController {
    func setupUI() {
        setupLeftUI()
        setupWebView()
//        setupImageView()
    }
    
    func setupLeftUI() {
        downloadProgressView.tintColor = .white
        downloadProgressView.progress = 0.0
        downloadProgressLabel.textColor = .white
        downloadProgressLabel.text = "正在下载...0%"
        downloadItemLabel.font = UIFont.systemFont(ofSize: 12)
        downloadItemLabel.textColor = .white
        downloadSpeedLabel.font = UIFont.systemFont(ofSize: 12)
        downloadSpeedLabel.textColor = .white
        
        view.addSubview(backView)
        view.addSubview(iconView)
        view.addSubview(downloadProgressLabel)
        view.addSubview(downloadProgressView)
        view.addSubview(downloadItemLabel)
        view.addSubview(downloadSpeedLabel)
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
        
        downloadSpeedLabel.snp.makeConstraints { (make) in
            make.top.equalTo(downloadProgressView.snp.bottom).offset(10)
            make.left.equalTo(downloadProgressView.snp.left)
        }


        logoView.snp.makeConstraints { (make) in
            make.centerX.equalTo(iconView)
            make.top.equalTo(downloadProgressView.snp.bottom).offset(150)
        }
    }
    
    func setupImageView() {
        imageView = UIImageView(image: UIImage(named: "山钦湾封面"))
        imageView?.layer.cornerRadius = 12
        imageView?.layer.masksToBounds = true
        imageView?.layer.borderWidth = 0.7
        imageView?.layer.borderColor = UIColor.white.cgColor
        
        view.addSubview(imageView!)
        imageView?.snp.makeConstraints({ (make) in
            make.top.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.bottom.equalTo(view).offset(-20)
            make.width.equalTo(imageView!.snp.height).multipliedBy(0.67)
        })
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
        webView?.layer.cornerRadius = 12
        webView?.layer.masksToBounds = true
        webView?.layer.borderWidth = 0.7
        webView?.layer.borderColor = UIColor.white.cgColor
        
        loadWebView(fileName: "download")
        
        view.addSubview(webView!)
        webView?.snp.makeConstraints({ (make) in
            make.top.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.bottom.equalTo(view).offset(-20)
            make.width.equalTo(webView!.snp.height).multipliedBy(0.67)
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
