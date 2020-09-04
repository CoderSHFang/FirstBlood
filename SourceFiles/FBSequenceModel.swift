//
//  FBSequenceModel.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/8/31.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import Foundation

public class FBSequenceModel {
    /// 图像路径
    var imagePath: String? {
        guard let imageName = imageName, let directory = directory else {
            return nil
        }
        
        return directory + "/" + imageName
    }
    
    /// 图像模型所在的目录
    var directory: String?
    
    /// 图像名称
    var imageName: String?
}
