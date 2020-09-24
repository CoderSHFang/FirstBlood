//
//  MyView.swift
//  MyProject
//
//  Created by Mac mini on 2020/9/18.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import UIKit

class MyView: UIView {
    
    lazy var dotView: UIView = {
        let v = UIView()
        v.backgroundColor = .red
        v.frame.size = CGSize(width: 50, height: 50)
        return v
    }()
    
    // MARK: 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dotView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveDotView(at: touches)
        dotView.isHidden = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveDotView(at: touches)
        dotView.isHidden = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveDotView(at: touches)
    }
    
    func moveDotView(at touches: Set<UITouch>) {
        let touch = (touches as NSSet).anyObject() as! UITouch
        let currentPoint = touch.location(in: self)
        
        let dotX = currentPoint.x - dotView.bounds.width / 2
        let dotY = currentPoint.y - dotView.bounds.height / 2
        
        dotView.frame.origin = CGPoint(x: dotX, y: dotY)
        
        //        添加缩放的动画
        redLayer.add(createAnimation(keyPath: "transform.scale.x", toValue: 0.5), forKey: nil)
    }
    
    
    // 懒加载缩放的layer
    private lazy var redLayer: CALayer = {
        let layer = self.createLayer(position: CGPoint(x: 125, y: 150), backgroundColor: UIColor.red)
        
        return layer
    }()
    
    //    创建calayer
    fileprivate func createLayer (position: CGPoint, backgroundColor: UIColor) -> CALayer {
        //创建calayer
        let layer = CALayer()
        //设置位置和大小
        layer.position = position
        layer.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        //设置背景颜色
        layer.backgroundColor = backgroundColor.cgColor
        //把layer添加到UIView的layer上
        dotView.layer.addSublayer(layer)
        
        return layer
    }
    
    //创建基础Animation
    fileprivate func createAnimation (keyPath: String, toValue: CGFloat) -> CABasicAnimation {
        //创建动画对象
        let scaleAni = CABasicAnimation()
        //设置动画属性
        scaleAni.keyPath = keyPath
        
        //设置动画的起始位置。也就是动画从哪里到哪里。不指定起点，默认就从positoin开始
        scaleAni.toValue = toValue
        
        //动画持续时间
        scaleAni.duration = 2;
        
        //动画重复次数
        scaleAni.repeatCount = Float(CGFloat.greatestFiniteMagnitude)
        
        return scaleAni;
    }
}
