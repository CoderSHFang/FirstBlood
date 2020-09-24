//
//  UIWindow+Extensions.swift
//  MyProject
//
//  Created by Mac mini on 2020/9/21.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import UIKit

extension UIWindow {
    
    private struct FBRelationKey {
        static var icons_relation = "icons_relation"
    }
    
    public var touchIcons: [UIImage?] {
        get {
            objc_getAssociatedObject(self, &FBRelationKey.icons_relation) as! [UIImage]
        }
        set {
            objc_setAssociatedObject(self,
                                     &FBRelationKey.icons_relation,
                                     newValue,
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    public func drawImage(at touches: Set<UITouch>) {
        
        if touchIcons.count == 0 { return }
        
        for (idx, touch) in touches.enumerated() {
            
            let location = touch.location(in: self)
            
            let imageView = UIImageView(image: touchIcons[idx])
            imageView.sizeToFit()
            imageView.center = location
            
            self.addSubview(imageView)
            
            UIView.animate(withDuration: 0.3, animations: {
                imageView.alpha = 0.0
            }) { (_) in
                imageView.removeFromSuperview()
            }
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawImage(at: touches)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawImage(at: touches)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawImage(at: touches)
    }
}
