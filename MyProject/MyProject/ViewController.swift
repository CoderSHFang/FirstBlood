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

class ViewController: UIViewController {
    private var webView: WKWebView?
    
    private lazy var backView = UIImageView(image: UIImage(named: "download_back_icon"))
    private lazy var iconView = UIImageView(image: UIImage(named: "download_title_icon"))
    private lazy var logoView = UIImageView(image: UIImage(named: "download_logo_icon"))
    private lazy var downloadProgressView = UIProgressView(progressViewStyle: .default)
    private lazy var downloadProgressLabel = UILabel()
    private lazy var downloadItemLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        
    }
}

// MARK: 下载资源
private extension ViewController {
    func loadData() {
        let urlString = "http://list.yunnto.cn/api/app/getUploadImgUrl"
        let param = ["project_id": 6]
        FBNetworkManager.shared.request(method: .POST, URLString: urlString, parameters: param) { [weak self] (json, isSuccess) in
            // 取出 result
            guard let json = (json as? [String: Any]),
                let result = json["data"] as? [[String: Any]]
                else {
                return
            }
            
            // 转模型数组
            let downloadArr = result.kj.modelArray(type: YSDownload.self) as! [YSDownload]
            
            // 准备分类好的模型
            var louCengdownloadArr = [YSDownload]()
            var sanWeidownloadArr = [YSDownload]()
            var manYoudownloadArr = [YSDownload]()
            
            // 资源分类
            for model in downloadArr {
                // 楼层诠释
                if model.type == 1 {
                    louCengdownloadArr.append(model)
                    continue
                }
                
                // 三维沙盘
                if model.type == 2 {
                    sanWeidownloadArr.append(model)
                    continue
                }
                
                // 园林漫游
                if model.type == 3 {
                    manYoudownloadArr.append(model)
                    continue
                }
            }
            
            // 准备需要保存的模型数组
    //            var louCengArr = [FBNetworkDownload]()
    //            var sanWeiArr = [FBNetworkDownload]()
    //            var manYouArr = [FBNetworkDownload]()
            
            // 下载资源
    //            self?.downloadResources(at: louCengdownloadArr, directoryName: "louCeng", completion: { (downloads) in
    //            })
            
            let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let cachesPath = (path as NSString).appendingPathComponent("manYou")
            self?.downloadSequences(URLString: manYoudownloadArr.first?.url ?? "", cachesPath: cachesPath, totalBytesWritten: 0, completion: { (download) in
            })
            
//            FBNetworkManager.shared.downloadFile(URLString: manYoudownloadArr.first?.url ?? "", cachesPath: cachesPath)
        }
    }
    
    func downloadSequences(URLString: String, cachesPath: String, totalBytesWritten: Int, completion: @escaping (_ download: FBNetworkDownload?)->()) {
        
        var tempDownload: FBNetworkDownload?
        
        tempDownload = FBNetworkManager.shared.download(URLString: URLString, cachesPath: cachesPath, totalBytesWritten: totalBytesWritten, receiveResponse: { (download) in
            print("URLString: \(download.URLString ?? "")")
            print("fileName: \(download.fileName ?? "")")
            print("fileDirectory: \(download.fileDirectory ?? "")")
            print("fileSize: \(download.fileSize ?? "")")
            print("--------------------")
            
        }, progress: { (downloadProgress) in
            
//            OperationQueue.main.addOperation {
//                self.downloadProgressView.progress =  Float(downloadProgress.downloadProgress)
//                self.downloadProgressLabel.text = "\(String(format: "下载中...%0.0f", downloadProgress.downloadProgress * 100))%"
//            }
            print("\(String(format: "下载中...%0.0f", downloadProgress.downloadProgress * 100))%")
            
        }) { (isSuccess) in
            
            if isSuccess {
                
//                self.downloadProgressLabel.text = "下载完成"
                
                // 解压
                guard let downloadModel = tempDownload,
                    let fileDirectory = self.archiveUnzip(model: downloadModel) else {
                    return
                }

                print("fileDirectory: \(fileDirectory)")
                
                print("下载完成")
                
                completion(tempDownload)
                
            }else {
                print("下载失败")
                completion(nil)
            }
            
        }
    }
    
    func archiveUnzip(model: FBNetworkDownload) -> String? {
        let isSuccess = SSZipArchive.unzipFile(atPath: model.filePath ?? "", toDestination: model.fileDirectory ?? "")
        
        if isSuccess == false {
            return nil
        }
        
        // 删除压缩包
        try? FileManager.default.removeItem(atPath: model.filePath ?? "")
        
        return  ((model.filePath ?? "") as NSString).deletingPathExtension
        
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
