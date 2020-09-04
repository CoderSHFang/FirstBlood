//
//  WBNetworkManager.swift
//
//  Created by Fat brother on 2019/8/17.
//  Copyright © 2019 Fat brother. All rights reserved.
//
import AFNetworking
/// Swift 的枚举支持任意数据类型
enum FBHTTPMethod {
    case GET
    case POST
}

/// 网络管理工具
public class FBNetworkManager: AFHTTPSessionManager {
    /// 静态区/常量/闭包
    /// 在第一次访问时，执行闭包，并且将结果保存在shared中
    static let shared: FBNetworkManager = {
        // 实例化对象
        let instance = FBNetworkManager()
        
        // 设置响应反序列化支持的数据类型
        instance.responseSerializer.acceptableContentTypes?.insert("application/json")
        instance.responseSerializer.acceptableContentTypes?.insert("text/json")
        instance.responseSerializer.acceptableContentTypes?.insert("text/javascript")
        instance.responseSerializer.acceptableContentTypes?.insert("text/html")
        instance.responseSerializer.acceptableContentTypes?.insert("text/plain")
        instance.responseSerializer.acceptableContentTypes?.insert("image/png")
        
        // 设置请求超时时间, 单位 秒
        instance.requestSerializer.timeoutInterval = 15
        
        // 2.是否信任具有无效或过期SSL证书的服务器 ,设为 true
        let securityPolicy = AFSecurityPolicy()
        securityPolicy.allowInvalidCertificates = true
        instance.securityPolicy = securityPolicy
        
        // 是否允许无效证书, 默认为 false
        instance.securityPolicy.allowInvalidCertificates = true
        // 是否校验域名, 默认为true
        instance.securityPolicy.validatesDomainName = false
        
        // 返回对象
        return instance
    }()
}

// MARK: AFN网络请求方法
extension FBNetworkManager {
    /// 专门负责拼接 token 的网络请求方法
    /// - Parameters:
    ///   - method: 判断是 POST/GET方法
    ///   - URLString: URLString
    ///   - parameters: 参数字典
    ///   - name: 上传文件使用的字段名，默认为 nil，不上传文件
    ///   - data: 上传文件的二进制数据，默认为 nil，不上传文件
    ///   - completion: 完成回调
    func tokenRequest(method: FBHTTPMethod = .GET,
                      URLString: String,
                      parameters:[String: Any]?,
                      name: String? = nil,
                      data: Data? = nil,
                      completion: @escaping (_ json: Any?,_ isSuccess: Bool)->()) {
        // 处理 token 字典
        // 0> 判断 token 是否为 nil，为 nil 直接返回
        
        // 1> 判断 参数字典是否存在,如果为 nil ，应该新建一个字典
        var parameters = parameters
        if parameters == nil {
            // 实例化字典
            parameters = [String: Any]()
        }
        
        // 设置参数字典, 代码在此处，一定有字典！
        
        // 判断 name 和 data
        if let name = name, let data = data {
            upload(URLString: URLString, parameters: parameters, name: name, data: data, completion: completion)
        }else {
            // 调用 request 发起正真的网络请求方法
            request(method: method, URLString: URLString, parameters: parameters, completion: completion)
        }
    }
    
    /// 封装 AFN 的 GET / POST 请求
    ///
    /// - Parameters:
    ///   - method: GET / POST
    ///   - URLString: URLString
    ///   - parameters: 参数字典吗
    ///   - completion: 完成回调[json(字典/数组),是否成功]
    func request(method: FBHTTPMethod = .GET,
                 URLString: String,
                 parameters:[String: Any]?,
                 completion: @escaping (_ json: Any?,_ isSuccess: Bool)->()) {
        
        // 成功回调
        let success = { (task: URLSessionDataTask, json: Any?)->() in
            completion(json, true)
        }
        // 失败回调
        let failure = { (task: URLSessionDataTask?, error: Error)->() in
            // error 通常比较吓人，例如编号：xxxx，错误原因一堆英文
            print("网络请求错误: \(error)")
            
            // 针对 403 处理用户 token 过期
            if (task?.response as? HTTPURLResponse)?.statusCode == 403 {
                print("token 过期了")
                
                // 发送通知，提示用户再次登录(本方法不知道被谁调用，谁接收到通知，谁处理！)
                
                // 记录登录过期的标记
                
            }
            
            completion(nil, false)
        }
        
        // 判断是 get 请求还是 post 请求
        if method == .GET {
            get(URLString, parameters: parameters, headers: nil, progress: nil, success: success, failure: failure)
        }else {
            post(URLString, parameters: parameters, headers: nil, progress: nil, success: success, failure: failure)
        }
        
    }
    
    /// 封装 AFN 的上传文件方法
    /// - Parameters:
    ///   - URLString: URLString
    ///   - parameters: 参数字典
    ///   - name: 接收上传数据的服务器字段(name - 要咨询公司的后台)
    ///   - data: 要上传的二进制数据
    ///   - completion: 完成回调
    func upload(URLString: String,
                parameters:[String: Any]?,
                name: String, data: Data,
                completion: @escaping (_ json: Any?,_ isSuccess: Bool)->()) {
        
        post(URLString, parameters: parameters, headers: nil, constructingBodyWith: { (formData) in
            // 创建 formData
            /*
             1. data：要上传的二进制数据
             2. name：服务器接收数据的字段名
             3. fileName：保存在服务器的文件名，大多数服务器，现在可以乱写
                很多服务器，上传图片完成后，会生成缩略图，中图，大图......
             4. mimeType：告诉服务器上传文件的类型，如果不想告诉，可以使用 application/octet-stream
                image/png   image/jpg   image/gif
             
             */
            formData.appendPart(withFileData: data, name: name, fileName: "xxx", mimeType: "application/octet-stream")
        }, progress: nil, success: { (task, json) in
            completion(json, true)
        }) { (task, error) in
            completion(nil, false)
        }
    }
    
    /// 封装 AFN 的下载文件方法
    /// - Parameters:
    ///   - URLString: URLString
    ///   - cachesPath: 缓存的目录
    ///   - totalBytesWritten: 已写入的字节数，默认为 0，用于断点下载
    ///   - receiveResponse: 收到响应的回调
    ///   - progress: 收到的进度回调
    ///   - completion: 完成回调
    func download(URLString: String,
                  cachesPath: String,
                  totalBytesWritten: Int = 0,
                  receiveResponse: @escaping (_ download: FBNetworkDownload)->(),
                  progress: @escaping (_ downloadProgress: FBNetworkDownloadProgress)->(),
                  completion: @escaping ( _ isSuccess: Bool)->()) -> FBNetworkDownload? {
        // 0. 创建请求
        guard let url = URL(string: URLString) else {
            print("URL 创建失败")
            return nil
        }
        var request = URLRequest(url: url)
        let range = String(format: "bytes=%zd-", totalBytesWritten)
        request.setValue(range, forHTTPHeaderField: "Range")
        
        // 下载模型
        let downloadModel = FBNetworkDownload()
        
        // 1. 创建下载任务
        let task = dataTask(with: request, uploadProgress: nil, downloadProgress: nil) { (response, responseObject, error) in
            
            guard let response = response as? HTTPURLResponse else {
                print("类型转换: URLResponse 转 HTTPURLResponse 失败")
                completion(false)
                return
            }
            
            // 下载失败
            if response.statusCode != 206 {
                print("error: \(String(describing: error))")
                print("response: \(String(describing: response))")
                print("responseObject: \(String(describing: responseObject))")
                
                downloadModel.fileHandle?.closeFile()
                downloadModel.fileHandle = nil
                completion(false)
                return
            }
            
            // 下载成功
            downloadModel.fileHandle?.closeFile()
            downloadModel.fileHandle = nil
            
            if downloadModel.progress.totalBytesWritten == downloadModel.progress.totalBytes {
                // 下载完成
                // 清空长度
                downloadModel.progress.totalBytesWritten = 0
                downloadModel.progress.totalBytesExpectedToWrite = 0
                completion(true)
            }else {
                print("数据丢失")
                completion(false)
            }
        }
        
        // 2. 任务是否收到响应
        setDataTaskDidReceiveResponseBlock { (session, dataTask, response) -> URLSession.ResponseDisposition in
            
            // 2.1 获取下载文件的总长度
            downloadModel.progress.totalBytesExpectedToWrite = Int(response.expectedContentLength)
            downloadModel.progress.totalBytesWritten = totalBytesWritten
            
            let expectedTotalBytes = downloadModel.progress.totalBytesExpectedToWrite
            let currentTotalBytes = downloadModel.progress.totalBytesWritten
            downloadModel.progress.totalBytes = expectedTotalBytes + currentTotalBytes
            
            downloadModel.fileSize = ByteCountFormatter.string(fromByteCount: Int64(downloadModel.progress.totalBytes), countStyle: .file)
            
            // 2.2 保存文件的路径
            let filePath = (cachesPath as NSString).appendingPathComponent(response.suggestedFilename ?? "")
            
            // 2.3 创建一个空的文件夹
            if FileManager.default.fileExists(atPath: cachesPath) == false {
                try? FileManager.default.createDirectory(atPath: cachesPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 解压之后的文件夹路径
            let folderPath = (filePath as NSString).deletingPathExtension
            
            // 判断是否有解压后的文件夹，如果没有，创建一个
            let isExist = FileManager.default.fileExists(atPath: folderPath)
            if isExist == false {
                if FileManager.default.fileExists(atPath: filePath) == false {
                    FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
                }
            }
            
            // 2.4 创建文件句柄
            downloadModel.fileHandle = FileHandle(forWritingAtPath: filePath)
            
            // 2.5 设置模型属性
            downloadModel.URLString = URLString
            downloadModel.fileName = response.suggestedFilename
            downloadModel.fileDirectory = cachesPath
            downloadModel.filePath = filePath
            
            // 回调
            OperationQueue.main.addOperation {
                receiveResponse(downloadModel)
            }
            
            // 允许处理服务器的响应，才会继续接收服务器返回的数据
            let disposition: URLSession.ResponseDisposition = isExist ? .cancel : .allow
            
            return disposition
        }
        
        // 3. 任务收到的数据
        setDataTaskDidReceiveDataBlock { (session, dataTask, data) in
            // 3.1 指定数据写入位置 -- 文件内容的最后面
            downloadModel.fileHandle?.seekToEndOfFile()
            
            // 3.2 将数据写入沙盒
            downloadModel.fileHandle?.write(data)
            
            // 3.3 拼接以下载文件的长度
            downloadModel.progress.totalBytesWritten += data.count
            
            // 3.4 计算下载速度
            
            // 3.5 计算下载进度
            let currentTotalBytes = Float(downloadModel.progress.totalBytesWritten)
            let totalBytes = Float(downloadModel.progress.totalBytes)
            downloadModel.progress.downloadProgress = currentTotalBytes / totalBytes
            
            // 回调
            progress(downloadModel.progress)
        }
        
        downloadModel.downloadTask = task
        
        task.resume()
        
        return downloadModel
    }
}
