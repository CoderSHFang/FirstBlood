//
//  FBSequenceManager.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/8/31.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import UIKit

public class FBSequenceManager {
    // MARK: - 属性
    /// 序列图管理单例
    static let shared = FBSequenceManager()
    
    /// 序列图素材的 bundle
    lazy var bundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "FBSequenceImage.bundle", ofType: nil) else {
            return nil
        }
        return Bundle(path: path)
    }()
    
    /// 当前目录名
    var currentDirectoryName: String?
    
    // MARK: - 初始化
    private init() {}
}

// MARK: - 加载序列帧图的方法
extension FBSequenceManager {
    /// 加载 FBSequenceImage.bundle 中序列图的方法
    /// - Parameter pathName: FBSequenceImage.bundle 下的文件名或者文件路径
    /// - Returns: 模型数组
    func loadBundleSequenceImage(pathName: String) -> [FBSequenceModel]? {
        guard let directory =  bundle?.path(forResource: pathName, ofType: nil)
            else {
            return nil
        }
        
        return loadCachesSequenceImage(atPath: directory)
    }
    
    /// 加载序列图的方法
    /// - Parameter path: 图片所在的目录路径
    /// - Returns: 模型数组
    func loadCachesSequenceImage(atPath: String) -> [FBSequenceModel]? {
        guard var imageNames = try? FileManager.default.contentsOfDirectory(atPath: atPath)
            else {
            return nil
        }
        
        return sortSequenceImage(imageNames: &imageNames, directory: atPath)
    }
    
    /// 将从文件夹中取出的文件进行从小到大的排序，并且转成模型
    /// - Parameters:
    ///   - imageNames: 图片数组
    ///   - directory: 图片所在的目录
    /// - Returns: 模型数组
    func sortSequenceImage(imageNames: inout [String],
                           directory: String)
        -> [FBSequenceModel] {
            
        imageNames.sort()
            
        var models = [FBSequenceModel]()
        for imageName in imageNames {
            let model = FBSequenceModel()
            model.imageName = imageName
            model.directory = directory
            models.append(model)
        }
        
        return models
    }
    
    /// 加载点位图标与坐标的方法
    /// - Parameters:
    ///   - iconPath: FBSequenceImage.bundle 下点位图标的文件名或者路径
    ///   - pointPath: FBSequenceImage.bundle 下坐标点的文件名或者路径，FBSequenceImage 下的坐标点的文件只能是 json 文件
    ///   - containerSize: 点位图标父视图的大小，默认是屏幕的宽高
    ///   - sourceSize: 点位图标是以某个宽高去适配的，默认是 1024 * 768
    /// - Returns: 返回一个元组，(获取的图像, 建议设置的图像的大小, [坐标点])
    func loadPositionIcon(iconPath: String,
                          pointPath: String,
                          _ containerSize: CGSize = UIScreen.main.bounds.size,
                          _ sourceSize: CGSize = CGSize(width: 1024, height: 768))
        ->
        (image: UIImage?, targerSize: CGSize, points: [CGPoint])
    {
        
        guard let imageFilePath = bundle?.path(forResource: iconPath, ofType: nil),
            let imageData = try? Data(contentsOf: URL(fileURLWithPath: imageFilePath)),
            let image = UIImage(data: imageData),
            let pointFilePath = bundle?.path(forResource: pointPath, ofType: nil),
            let pointData = try? Data(contentsOf: URL(fileURLWithPath: pointFilePath)),
            let pointArr = try? JSONSerialization.jsonObject(with: pointData, options: []) as? [[String: CGFloat]]
        else {
            return (nil, CGSize.zero, [CGPoint.zero])
        }
        
        var size = CGSize.zero
        
        if iconPath.hasSuffix(".gif") {
            print("是 gif 图，路径：\(imageFilePath)")
            let width: CGFloat = 120
            let height = width / (size.width / size.height)
            size = CGSize(width: width, height: height)
        }else {
            size = CGSize(width: image.size.width / 2, height: image.size.height / 2)
        }
        
        // 遍历坐标点
        var points = [CGPoint]()
        for item in pointArr {
           let sourceX = item["x"] ?? 0
           let sourceY = item["y"] ?? 0

            let tempX = sourceX * containerSize.width / sourceSize.width
            let tempY = sourceY * containerSize.height / sourceSize.height
           
           let targetX = (tempX / 2) - (size.width / 2)
           let targetY = (tempY / 2) - size.height
           
           points.append(CGPoint(x: targetX, y: targetY))
        }
        
        return (image, size, points)
    }
}


