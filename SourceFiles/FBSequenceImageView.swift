//
//  FBSequenceImageView.swift
//  DownloadTest
//
//  Created by Mac mini on 2020/8/31.
//  Copyright © 2020 Mac mini. All rights reserved.
//

import UIKit

public class FBSequenceImageView: UIImageView {
    // MARK: 初始化方法
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialization()
    }
    
    public override init(image: UIImage?) {
        super.init(image: image)
        initialization()
    }
    
    public override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        initialization()
    }
    
    deinit {
        myTimer?.invalidate()
        myTimer = nil
    }
    
    // MARK: 属性 Serial
    public enum FBPlayMode {
        case serial
        case reversed
    }
    
    public var  currentSequences: [FBSequenceModel]? {
        didSet {
            if currentSequences?.count ?? 0 == 0 {
                return
            }
            
            setImage()
        }
    }
    
    public var myTimer: Timer?
    
    public var timeInterval: TimeInterval = 1.0 / 30.0
    
    public var currentIndex = 0
    
    public weak var delegate: FBSequenceImageViewDelegate?
    
    public var totalScale: CGFloat = 1.0
    
    public let maxScale: CGFloat = 2.0
    
    public let minScale: CGFloat = 1.0
    
    private var playMode = FBPlayMode.serial
    
    private var currentSlideOffset = CGPoint.zero
    
    private var scaleCenterPoint = CGPoint.zero
    
    private var playCompletion: (()->())?
    
    private var restoreProgress: ((_ index: Int)->())?
    
}

// MARK: 初始设置
extension FBSequenceImageView {
    private func initialization() {
        addGesture()
        addTimer()
    }
    
    private func addGesture() {
        isUserInteractionEnabled = true
        
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        panGes.maximumNumberOfTouches = 1
        addGestureRecognizer(panGes)
        
        let pinchGes = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
        addGestureRecognizer(pinchGes)
    }
    
    private func addTimer() {
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
        switchImage(mode: playMode, cancel: { [weak self] in
            self?.stopAnimatImages()
            self?.playCompletion?()
        }, completion: nil)
    }
    
    func pinchGesture(gesture: UIPinchGestureRecognizer) {
        
        if gesture.numberOfTouches < 2 {
            return
        }
        
        let v = gesture.view
        let scale = gesture.scale

        // 放大情况
        if scale > 1.0 {
            if totalScale <= 1.0 {
                adjustAnchorPoint(for: gesture)
            }
            
            if totalScale > maxScale {
                transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
                return
            }
        }

        // 缩小情况
        if scale <= 1.0 {
            if totalScale < minScale {
                transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                return
            }
        }

        if gesture.state == .changed {
            guard var transform = v?.transform.scaledBy(x: gesture.scale, y: gesture.scale) else {
                return
            }
            
            if transform.a <= 1.0 { transform.a = 1.0 }
            if transform.d <= 1.0 { transform.d = 1.0 }
            v?.transform = transform
            gesture.scale = 1
            totalScale *= scale
        }
    }
    
    func adjustAnchorPoint(for gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            guard let v = gesture.view else {
                return
            }
            
            let location = gesture.location(in: v)
            let anchorPoint = CGPoint(x: location.x / v.bounds.width, y: location.y / v.bounds.height)
            print(anchorPoint)
            v.layer.anchorPoint = anchorPoint
            
            let superLocation = gesture.location(in: superview)
            v.center = superLocation
        }
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
        let differ = Int(abs(location.x - currentSlideOffset.x))
        
        if currentSlideOffset.x > location.x {
            for i in 0 ..< differ {
                if (i % 4) == 0 {
                    switchImage(mode: .serial, cancel: nil) { [weak self] in
                        self?.delegate?.sequenceImageView?(self!, didFingerLeftSlide: location)
                    }
                }
            }
        }
        
        if currentSlideOffset.x < location.x {
            for i in 0 ..< differ {
                if (i % 4) == 0 {
                    switchImage(mode: .reversed, cancel: nil) { [weak self] in
                        self?.delegate?.sequenceImageView?(self!, didFingerRightSlide: location)
                    }
                }
            }
        }
        
        delegate?.sequenceImageView?(self, didFingerSlide: location)
        
        currentSlideOffset = location
    }
    
    func fingerBegan(location: CGPoint) {
        currentSlideOffset = location
        delegate?.sequenceImageView?(self, didFingerBeganSlide: location)
    }
    
    func fingerEnded(location: CGPoint) {
        currentSlideOffset = location
        delegate?.sequenceImageView?(self, didFingerEndSlide: location)
    }
}

// MARK: 设置图像的方法
public extension FBSequenceImageView {
    /// 开始播放序列图
    func startAnimatImages(playMode: FBPlayMode, completion: (()->())?) {
        if myTimer?.isValid == false { return }
        playCompletion = completion
        self.playMode = playMode
        isUserInteractionEnabled = false
        myTimer?.fireDate = Date()
    }
    
    /// 停止播放序列图
    func stopAnimatImages() {
        if myTimer?.isValid == false { return }
        myTimer?.fireDate = Date.distantFuture
        isUserInteractionEnabled = true
    }
    
    /// 将当前序列图恢复到第一张
    func restoreCurrentImages(progress: ((_ index: Int)->())?, completion: (()->())?) {
        restoreProgress = progress
        
        let result = ((currentSequences?.count ?? 0) / 2) <= currentIndex
        let playMode: FBPlayMode = result ? .reversed : .serial
        startAnimatImages(playMode: playMode, completion: completion)
    }
    
    /// 切换图像
    /// - Parameters:
    ///   - isPlus: imageIndex 是否是自增，true 自增，false 自减
    func switchImage(mode: FBPlayMode, cancel: (()->())?, completion: (()->())?) {
        let count = currentSequences?.count ?? 0
        if mode == .serial {
            currentIndex += 1
            
            if currentIndex >= count || currentIndex < 0 {
                currentIndex = 0
                cancel?()
                return
            }
        }else {
            currentIndex -= 1
            
            if currentIndex < 0 || currentIndex >= count  {
                currentIndex = count - 1
                cancel?()
                return
            }
        }
        
        setImage()
        
        restoreProgress?(currentIndex)
        
        completion?()
    }
    
    /// 设置图像
    func setImage() {
        let model = currentSequences?[currentIndex]
        image = UIImage(contentsOfFile: model?.imagePath ?? "")
    }
    
    /// 设置图像
    /// - Parameters:
    ///   - sequences: 序列图模型
    ///   - index: 索引
    func setImage(at sequences: [FBSequenceModel]?, index: Int) {
        currentIndex = index
        currentSequences = sequences
    }
}

/// 序列图对象的代理方法
@objc public protocol FBSequenceImageViewDelegate: NSObjectProtocol {
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerBeganSlide offset: CGPoint)
    
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerEndSlide offset: CGPoint)
    
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerSlide offset: CGPoint)
    
    // 这个方法只有在图片切换并且是才会执行
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerLeftSlide offset: CGPoint)
    
    // 这个方法只有在图片切换的时候才会执行
    @objc optional func sequenceImageView(_ imageView: FBSequenceImageView, didFingerRightSlide offset: CGPoint)
}
