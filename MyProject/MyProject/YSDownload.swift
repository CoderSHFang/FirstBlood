//
//  YSDownload.swift
//  DaYueCityHD
//
//  Created by Mac mini on 2020/9/4.
//  Copyright © 2020 Fat brother. All rights reserved.
//

import KakaJSON

class YSDownload: Convertible {
    var created_at: String?
    
    var name: String?
    
    var project_id: String?
    
    var type: Int = 0
    
    var url: String?
    
    var version: Int = 0
    
    required init() {
        
    }
}
