//
//  CubeTransitionView.swift
//  CubeTransitionViewTest
//
//  Created by 孟嘉明 on 2017/10/10.
//  Copyright © 2017年 孟嘉明. All rights reserved.
//

import UIKit

class CubicTransitionView: UIView {
    
    private var isAutoRotating: Bool = false
    private let perspectiveContainerLayer = CATransformLayer()
    private let testView = UIView()
    private var contentViews: [UIView]!
    private var shadowLayers: [CALayer] = []
    
    // for debug
    //private var contentLayers: [CALayer] = []
    
    private var numberOfContentViews = 0
    private var unitAngle: CGFloat = 0.0
    private var currentAngle: CGFloat = 0 {
        didSet{
            if currentAngle > CGFloat.pi * 2
            {
                currentAngle -= CGFloat.pi * 2
            }
            else if currentAngle < 0
            {
                currentAngle += CGFloat.pi * 2
            }
        }
    }
    
    private var tempAngle: CGFloat = 0
    
    private var previousRotatedAngle: CGFloat = 0.0
    
    /**contentView 的左右两边到旋转中心的距离*/
    private var radius: CGFloat = 0.0
    
    private var panGR: UIPanGestureRecognizer!
    private var isPanning: Bool = false
    private var velocity: CGFloat = 0
    public var isRotationSpringy: Bool = true
    
    private let shortDuration: CGFloat = 0.5
    private let longDuration: CGFloat = 1.0
    private var autoRotatingDuration: CGFloat = 0
    private var angleToRotate: CGFloat = 0
    private var targetSide: Int = 0
    
    // 用于动画
    private var anchorTimestamp: CFTimeInterval = 0
    private var anchorRotatedAngle: CGFloat = 0
    
    /**为了解决“布局更新不及时（只更新于显示后，且只更新存在于显示链的 layer ），导致旋转时旁边的面出现破绽”这个问题，在初始化时就把所有的contentView 添加为 subview，又为了防止各个 contentView 重叠在一起导致手势冲突，在初始化时先将所有contentView 都放到视野以外*/
    private var outSideFrame: CGRect!
    
    public weak var transitionDelegate: CubicTransitionProtocol!
    
    init?(frame: CGRect, contentViews: [UIView]) {
        super.init(frame: frame)
        
        self.contentViews = contentViews
        numberOfContentViews = contentViews.count
        
        if numberOfContentViews <= 1
        {
            return nil
        }
        
        unitAngle = CGFloat.pi / CGFloat(numberOfContentViews)
        radius = bounds.width / 2 / sin(unitAngle)
    
        perspectiveContainerLayer.frame = self.layer.bounds
        perspectiveContainerLayer.transform.m34 = -1 / 1000
        self.layer.addSublayer(perspectiveContainerLayer)
        
        var anchorPointZ = -radius * cos(unitAngle)
        if abs(anchorPointZ) < 0.001
        {
            anchorPointZ = -0.001
        }
        
        outSideFrame = CGRect(x: 0, y: -3000, width: self.frame.width, height: self.frame.height)
        
        for contentView in contentViews {
            contentView.frame = outSideFrame
            contentView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            contentView.layer.anchorPointZ = anchorPointZ
            contentView.clipsToBounds = true
            self.addSubview(contentView)
            
            let shadowLayer = CALayer()
            shadowLayer.isOpaque = false
            shadowLayer.backgroundColor = UIColor.black.cgColor
            shadowLayer.frame = self.bounds
            shadowLayer.opacity = 0
            shadowLayers.append(shadowLayer)
            
        }
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        panGR.maximumNumberOfTouches = 1
        panGR.minimumNumberOfTouches = 1
        self.addGestureRecognizer(panGR)
        
        contentViews[0].frame = self.bounds
        self.addSubview(contentViews[0])
    }
    
    
    @objc private func panHandler(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            isPanning = true
            prepareForRotation()
        }
        else if recognizer.state == .changed {
            currentAngle = previousRotatedAngle + recognizer.translation(in: self).x / self.bounds.width * 2 * unitAngle
            velocity = recognizer.velocity(in: self).x
            rotate()
        }
        else if recognizer.state == .cancelled || recognizer.state == .ended || recognizer.state == .failed
        {
            autoRotateToTheNearestSide()
            isPanning = false
        }
    }
    
    private func prepareForRotation() {
        previousRotatedAngle = currentAngle
        for i in 0 ..< contentViews.count {
            
            contentViews[i].removeFromSuperview()
            contentViews[i].frame = self.bounds
            contentViews[i].layer.addSublayer(shadowLayers[i])
            perspectiveContainerLayer.addSublayer(contentViews[i].layer)
        }
        rotate()
    }
    
    private func rotate(){
        let remainderAngle = currentAngle.truncatingRemainder(dividingBy: unitAngle * 2)
        let distanceToTranslate = -self.radius * max(abs(cos(remainderAngle - unitAngle)), abs(cos(remainderAngle + unitAngle)))
        for i in 0 ..< contentViews.count {
            let translationBackwards = CATransform3DMakeTranslation(0, 0, distanceToTranslate)
            contentViews[i].layer.transform = CATransform3DRotate(translationBackwards, currentAngle + 2 * unitAngle * CGFloat(i), 0, 1, 0)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            // add shadow
            let angle =  currentAngle + CGFloat(i) * 2 * unitAngle
            shadowLayers[i].opacity = Float(1 - cos(angle))
            CATransaction.commit()
        }
        
        if let delegate = transitionDelegate
        {
            let sideAngle = CGFloat.pi * 2 - currentAngle
            delegate.displayedPortion(begin: (sideAngle / (CGFloat.pi * 2)).truncatingRemainder(dividingBy: 1), end: ((sideAngle + unitAngle * 2) / (CGFloat.pi * 2)).truncatingRemainder(dividingBy: 1))
        }
    }
    
    private func autoRotateToTheNearestSide(){
        
        // 求出当前面所在面（面的标记方向与 currentAngle 增加方向相反）
        let completeAngle = 2 * CGFloat.pi - currentAngle
        let theLeftSide = Int(completeAngle / (2 * unitAngle))
        let remainderAngle = completeAngle.truncatingRemainder(dividingBy: 2 * unitAngle)
    
        if remainderAngle > unitAngle {
            if velocity > 800 {
                self.targetSide = theLeftSide
                rotateToTargetSideWithDuration(duration: shortDuration * ( remainderAngle / (2 * unitAngle)))
                return
            }
            self.targetSide = (theLeftSide + 1) % numberOfContentViews
            rotateToTargetSideWithDuration(duration: shortDuration * (1 - remainderAngle / (2 * unitAngle)))
        } else {
            if velocity < -800 {
                self.targetSide = (theLeftSide + 1) % numberOfContentViews
                rotateToTargetSideWithDuration(duration: shortDuration * (1 - remainderAngle / (2 * unitAngle)))
                return
            }
            self.targetSide = theLeftSide
            rotateToTargetSideWithDuration(duration: shortDuration * ( remainderAngle / (2 * unitAngle)))
        }
        
        
    }
    
    public func rotateToSide(side: Int)
    {
        
        if side < 0 || side >= numberOfContentViews || isAutoRotating || targetSide == side || isPanning
        {
            return
        }
        
        prepareForRotation()
        
        
        if abs(CGFloat(side - targetSide)) * unitAngle * 2 > 90 && CGFloat(side) * unitAngle * 2 < 270
        {
            targetSide = side
            rotateToTargetSideWithDuration(duration: longDuration)
        }
        else
        {
            targetSide = side
            rotateToTargetSideWithDuration(duration: shortDuration)
        }
        
    }
    
    private func rotateToTargetSideWithDuration(duration: CGFloat)
    {
        
        setEnableRotating(enabled: false)
        
        let angleToRotateTo = CGFloat.pi * 2 - CGFloat(targetSide) * unitAngle * 2
        if angleToRotateTo - currentAngle > CGFloat.pi
        {
            angleToRotate = angleToRotateTo - currentAngle - CGFloat.pi * 2
        }
        else if angleToRotateTo - currentAngle < -CGFloat.pi
        {
            angleToRotate = CGFloat.pi * 2 + (angleToRotateTo - currentAngle)
        }
        else
        {
            angleToRotate = angleToRotateTo - currentAngle
        }
        
        if duration < 0.1 {
            autoRotatingDuration = 0.1
        }
        else
        {
            autoRotatingDuration = duration
        }
        
        let displayLink = CADisplayLink(target: self, selector: #selector(renderAutoRotating))
        anchorTimestamp = 0
        anchorRotatedAngle = currentAngle
        tempAngle = currentAngle
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
        
    }
    
    @objc private func renderAutoRotating(displayLink: CADisplayLink)
    {
        if isRotationSpringy
        {
            renderAutoRotatingSpringily(displayLink: displayLink)
        }
        else
        {
            renderAutoRotatingSmoothly(displayLink: displayLink)
        }
    }
    
     private func renderAutoRotatingSmoothly(displayLink: CADisplayLink)
    {
        if anchorTimestamp == 0
        {
            anchorTimestamp = displayLink.timestamp
        }
        let passedTime = displayLink.timestamp - anchorTimestamp
        if passedTime < Double(autoRotatingDuration)
        {
            let animatingProgress = getAnimatingProgressWith(timeProgress: passedTime / Double(autoRotatingDuration))

            currentAngle = anchorRotatedAngle + angleToRotate * animatingProgress
            rotate()
        }
        else
        {
            displayLink.remove(from: .main, forMode: .defaultRunLoopMode)
            finishRotating()
        }
    }
    
    private func getAnimatingProgressWith( timeProgress: CFTimeInterval) -> CGFloat
    {
        var _timeProgress = timeProgress
        if _timeProgress < 0
        {
            _timeProgress = 0
        }
        else if _timeProgress > 1
        {
            _timeProgress = 1
        }
        
        if _timeProgress <= 0.5
        {
            return CGFloat(2 * pow(_timeProgress, 2))
        }
        else
        {
            return CGFloat(1 - 2 * pow(_timeProgress - 1, 2))
        }
    }
    
    private func renderAutoRotatingSpringily(displayLink: CADisplayLink)
    {
        let a = (angleToRotate + anchorRotatedAngle - tempAngle) * 50000 - velocity * 10
        velocity += a / 60.0
        tempAngle += velocity / radius / 60.0
        currentAngle = tempAngle
        rotate()
        
        if (abs(velocity) < 5 && abs(angleToRotate + anchorRotatedAngle - currentAngle) < 0.01)
        {
            displayLink.remove(from: .main, forMode: .defaultRunLoopMode)
            finishRotating()
            velocity = 0
        }
    }
    
    
    private func finishRotating()
    {
        currentAngle = anchorRotatedAngle + angleToRotate
        rotate()
        
        for i in 0 ..< numberOfContentViews
        {
            contentViews[i].layer.transform = CATransform3DIdentity
            contentViews[i].layer.removeFromSuperlayer()
            shadowLayers[i].removeFromSuperlayer()
        }
        contentViews[targetSide].frame = self.bounds
        self.addSubview(contentViews[targetSide])
        
        if transitionDelegate != nil
        {
            transitionDelegate.didRotateTo(side: targetSide)
        }
        
        setEnableRotating(enabled: true)
    }
    
    private func setEnableRotating(enabled: Bool)
    {
        if enabled
        {
            isAutoRotating = false
            panGR.isEnabled = true
        }
        else
        {
            isAutoRotating = true
            panGR.isEnabled = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

protocol CubicTransitionProtocol: class {
    func didRotateTo(side: Int)
    
    func displayedPortion(begin: CGFloat, end: CGFloat)
}
