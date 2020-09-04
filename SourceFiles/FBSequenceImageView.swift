//
//  FBSequenceImageView.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/8/31.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import UIKit

class FBSequenceImageView: UIImageView {
    // MARK: 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialization()
    }
    
    override init(image: UIImage?) {
        super.init(image: image)
        initialization()
    }
    
    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        initialization()
    }
    
    deinit {
        myTimer?.invalidate()
        myTimer = nil
    }
    
    // MARK: 属性
    private var currentOffset = CGPoint.zero
    
    var  currentSequences: [FBSequenceModel]? {
        didSet {
            if currentSequences?.count == 0 {
                return
            }
            
            setImage()
        }
    }
    
    var myTimer: Timer?
    
    var timeInterval: TimeInterval = 1 / 30
    
    var currentIndex = 0
    
    weak var delegate: FBSequenceImageViewDelegate?
}

// MARK: 初始设置
private extension FBSequenceImageView {
    func initialization() {
        addGesture()
        addTimer()
    }
    
    func addGesture() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture)))
    }
    
    func addTimer() {
        myTimer = Timer.scheduledTimer(timeInterval: animationDuration,
                                       target: self,
                                       selector: #selector(updateTime),
                                       userInfo: nil,
                                       repeats: true)
        myTimer?.fireDate = Date.distantFuture
    }
}

// MARK: 监听方法
@objc private extension FBSequenceImageView {
    func updateTime() {
        if currentIndex == 0 {
            stopAnimatImages()
        }
        
        switchImage(isPlus: true, completion: nil)
    }
    
    func panGesture(gesture: UIPanGestureRecognizer) {
        
        let fingerLocation = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            fingerBegan(location: fingerLocation)
        case .changed:
            fingerMoved(location: fingerLocation)
        case .ended:
            fingerEnded(location: fingerLocation)
        default:
            break
        }
    }
    
    func fingerMoved(location: CGPoint) {
        let differ = Int(abs(location.x - currentOffset.x))
        
        if currentOffset.x > location.x {
            for i in 0 ..< differ {
                if (i % 4) == 0 {
                    switchImage(isPlus: true) {[weak self] in
                        self?.delegate?.sequenceImageView?(self!, didFingerLeftSlide: location)
                    }
                }
            }
        }
        
        if currentOffset.x < location.x {
            for i in 0 ..< differ {
                if (i % 4) == 0 {
                    switchImage(isPlus: false) {[weak self] in
                        self?.delegate?.sequenceImageView?(self!, didFingerRightSlide: location)
                    }
                }
            }
        }
        
        delegate?.sequenceImageView?(self, didFingerSlide: location)
        
        currentOffset = location
    }
    
    func fingerBegan(location: CGPoint) {
        currentOffset = location
        delegate?.sequenceImageView?(self, didFingerBeganSlide: location)
    }
    
    func fingerEnded(location: CGPoint) {
        currentOffset = location
        delegate?.sequenceImageView?(self, didFingerEndSlide: location)
    }
}

extension FBSequenceImageView {
    /// 开始播放序列图
    func startAnimatImages() {
        if myTimer?.isValid == false { return }
        myTimer?.fireDate = Date()
    }
    
    /// 停止播放序列图
    func stopAnimatImages() {
        if myTimer?.isValid == false { return }
        myTimer?.fireDate = Date.distantFuture
    }
    
    /// 切换图像
    /// - Parameters:
    ///   - isPlus: imageIndex 是否是自增，true 自增，false 自减
    func switchImage(isPlus: Bool, completion: (()->())?) {
        
        if isPlus {
            currentIndex += 1
        }else {
            currentIndex -= 1
        }
        
        let count = currentSequences?.count ?? 0
        
        if isPlus {
            if currentIndex >= count || currentIndex < 0 {
                currentIndex = 0
                return
            }
        }else {
            if currentIndex < 0 || currentIndex >= count  {
                currentIndex = count - 1
                return
            }
        }
        
        setImage()
        
        completion?()
    }
    
    /// 设置图像
    func setImage() {
        let model = currentSequences?[currentIndex]
        image = UIImage(contentsOfFile: model?.imagePath ?? "")
    }
}

/// 序列图对象的代理方法
@objc protocol FBSequenceImageViewDelegate: NSObjectProtocol {
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerBeganSlide offset: CGPoint)
    
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerEndSlide offset: CGPoint)
    
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerSlide offset: CGPoint)
    
    // 这个方法只有在图片切换并且是才会执行
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerLeftSlide offset: CGPoint)
    
    // 这个方法只有在图片切换的时候才会执行
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerRightSlide offset: CGPoint)
}
