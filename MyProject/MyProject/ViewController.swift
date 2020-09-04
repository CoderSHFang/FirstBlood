//
//  ViewController.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/8/31.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import UIKit
import SSZipArchive
import WebKit

class ViewController: UIViewController {
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    private var imageView: FBSequenceImageView?
    private var downloadModel: FBNetworkDownload?

    @IBAction func playButtonClick(_ sender: UIButton) {
        
        if sender.isSelected == false {
            guard let URLString = self.downloadModel?.URLString,
                let cachesPath = self.downloadModel?.fileDirectory,
                let totalBytesWritten = self.downloadModel?.fileContentLength
                else {
                return
            }
            
            // 开始下载
            downloadSequences(URLString: URLString, cachesPath: cachesPath, totalBytesWritten: totalBytesWritten)
            
            sender.isSelected = true
            
        }else {
            
            // 暂停下载
            downloadModel?.downloadTask?.suspend()
            downloadModel?.downloadTask = nil
            sender.isSelected = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let htmlPath = Bundle.main.path(forResource: "tour",
                                              ofType: "html",
                                              inDirectory: "test")
            else {
            return
        }

        webView?.loadFileURL(URL(fileURLWithPath: htmlPath),
                             allowingReadAccessTo: URL(fileURLWithPath: Bundle.main.bundlePath))

        imageView = FBSequenceImageView(frame: UIScreen.main.bounds)
        imageView?.isHidden = true
        view.addSubview(imageView!)

//        let URLString = "https://yunnto.oss-cn-shenzhen.aliyuncs.com/test1/sequence/%E5%8C%BA%E4%BD%8D%E8%BD%B4%E4%BE%A7.zip"
//        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
//        let cachesPath = (path as NSString).appendingPathComponent("3D")
//
//        downloadSequences(URLString: URLString, cachesPath: cachesPath, totalBytesWritten: 0)
         
//        let URLString = "http://list.yunnto.cn/api/app/getUploadImgUrl"
//        FBNetworkManager.shared.request(method: .POST, URLString: URLString, parameters: nil) { (result, isSuccess) in
//            print("result: \(result ?? "")")
//            let data = (result as! [String: Any])["data"] as! [String: Any]
//            let downloadURLString = data["url"] as! String
//            let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
//            let cachesPath = (path as NSString).appendingPathComponent("3D")
//            self.downloadSequences(URLString: downloadURLString, cachesPath: cachesPath, totalBytesWritten: 0)
//        }
        
        let downloadURLString = "https://yunnto.oss-cn-shenzhen.aliyuncs.com/List/H5/sequence/dyc/sanweishapan/%E5%8C%BA%E4%BD%8D%E8%BD%B4%E4%BE%A7.zip"
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let cachesPath = (path as NSString).appendingPathComponent("3D")
        self.downloadSequences(URLString: downloadURLString, cachesPath: cachesPath, totalBytesWritten: 0)
        
    }
    
    func downloadSequences(URLString: String, cachesPath: String, totalBytesWritten: Int) {
        
        downloadModel = FBNetworkManager.shared.download(URLString: URLString, cachesPath: cachesPath, totalBytesWritten: totalBytesWritten, receiveResponse: { (download) in
            print("URLString: \(download.URLString ?? "")")
            print("fileName: \(download.fileName ?? "")")
            print("fileDirectory: \(download.fileDirectory ?? "")")
            print("filePath: \(download.filePath ?? "")")
            print("fileSize: \(download.fileSize ?? "")")
            print("--------------------")
            
        }, progress: { (downloadProgress) in
            
            OperationQueue.main.addOperation {
                self.downloadProgressView.progress =  Float(downloadProgress.downloadProgress)
                self.downloadProgressLabel.text = "\(String(format: "加载中...%0.0f", downloadProgress.downloadProgress * 100))%"
            }
            
        }) { (isSuccess) in
            print("--------------------")
            print("fileDirectory: \(self.downloadModel?.filePath ?? "")")
            
            if isSuccess {
                print("下载完成")
                
                self.downloadProgressLabel.text = "下载完成"
                
                // 解压
                guard let downloadModel = self.downloadModel,
                    let fileDirectory = self.archiveUnzip(model: downloadModel) else {
                    return
                }
                
                self.imageView?.currentSequences = FBSequenceManager.shared.loadCachesSequenceImage(atPath: fileDirectory)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    self.imageView?.isHidden = false
                }
            }else {
                print("下载失败")
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
