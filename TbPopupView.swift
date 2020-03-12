//
//  TbPopupView.swift
//  TbPopView
//
//  Created by Tb on 2020/3/11.
//  Copyright © 2020 Tb. All rights reserved.
//

import UIKit

protocol TbPopupViewAnimationProtocol: AnyObject {
    
    func setup(contentView: UIView , backgroundView: TbBackgroundView, containerView: UIView)
    
    func display(contentView: UIView, backgroundView: TbBackgroundView, animated: Bool, completion: @escaping () ->())
    
    func dismiss(contentView: UIView, backgroundView: TbBackgroundView, animated: Bool, completion: @escaping () ->())
}

public enum TbPopupViewBackgroundStyle {
    case solidColor
    case blur
}

class TbBackgroundView: UIControl {
   
    public var style = TbPopupViewBackgroundStyle.solidColor {
        didSet {
            refreshBackgroundStyle()
        }
    }
    
    public var blurEffectStyle = UIBlurEffect.Style.dark {
        didSet {
           refreshBackgroundStyle()
        }
    }
    var color = UIColor.black.withAlphaComponent(0.3){
        didSet {
            backgroundColor = color
        }
    }
    
    var effectView: UIVisualEffectView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        refreshBackgroundStyle()
        backgroundColor = color
        layer.allowsGroupOpacity = false
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == effectView {
            // 将event交给backgroundView处理
            return self
        }
        return view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        effectView?.frame = self.bounds
    }
    
    func refreshBackgroundStyle(){
        if style == .solidColor {
            effectView?.removeFromSuperview()
            effectView = nil
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: self.blurEffectStyle))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}

class TbPopupView: UIView {

    public var isDismissible = false {
        didSet {
            //backgroundView.isUserInteractionEnabled = isDismissible
        }
    }
    public var isInteractive = true
    public var isPenetrable = false
    public let backgroundView: TbBackgroundView
    public var willDisplayCallback: (() -> ())?
    public var didDisplayCallback: (() -> ())?
    public var willDismissCallback: (() -> ())?
    public var didDismissCallback: (() -> ())?
    
    weak var containerView: UIView!
    let contentView: UIView
    let animator: TbPopupViewAnimationProtocol
    var isAnimating = false
    
    deinit {
        willDismissCallback = nil
        didDismissCallback = nil
        willDismissCallback = nil
        didDismissCallback = nil
    }
    
    public init(containerView: UIView, contentView: UIView,animator: TbPopupViewAnimationProtocol){
        self.containerView = containerView
        self.contentView = contentView
        self.animator = animator
        backgroundView = TbBackgroundView(frame: .zero)
        
        
        super.init(frame: containerView.bounds)

        backgroundView.isUserInteractionEnabled = isDismissible
        backgroundView.addTarget(self, action: #selector(backgroundViewClicked), for: .touchUpInside)
        addSubview(backgroundView)
        addSubview(contentView)
        animator.setup(contentView: contentView, backgroundView: backgroundView, containerView: containerView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointInContent = convert(point, to: contentView)
        let isPointInContent = contentView.bounds.contains(pointInContent)
        if isPointInContent {
            if isInteractive {
                return super.hitTest(point, with: event)
            } else {
                return nil
            }
        } else {
            if !isPenetrable {
                return super.hitTest(point, with: event)
            } else {
                return nil
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = self.bounds
    }
    
    func display(animated: Bool, completeion: (()->())?) {
        if isAnimating {
            return
        }
        
        isAnimating = true
        containerView.addSubview(self)
        
        willDisplayCallback?()
        animator.display(contentView: contentView, backgroundView: backgroundView, animated: animated, completion: {
            completeion?()
            self.isAnimating = false
            self.didDisplayCallback?()
           
        })
    }
    
    func dismiss(animated: Bool, completion: (()->())?) {
        if isAnimating {
            return
        }
        isAnimating = true
        willDismissCallback?()
        animator.dismiss(contentView: contentView, backgroundView: backgroundView, animated: animated, completion: {
            self.removeFromSuperview()
            completion?()
            self.isAnimating = false
            self.didDismissCallback?()
        })
    }
    
    @objc func backgroundViewClicked(){
        dismiss(animated: true, completion: nil)
    }
    
}

open class TbPopupViewBaseAnimator: TbPopupViewAnimationProtocol {
    open var displayDuration: TimeInterval = 0.25
    open var displayAnimationOptions = UIView.AnimationOptions.init(rawValue:
        UIView.AnimationOptions.beginFromCurrentState.rawValue &
            UIView.AnimationOptions.curveEaseInOut.rawValue)
    /// 展示动画的配置block
    open var displayAnimateBlock: (()->())?
    
    open var dismissDuration: TimeInterval = 0.25
    open var dismissAnimationOptions =
        UIView.AnimationOptions.init(rawValue:
            UIView.AnimationOptions.beginFromCurrentState.rawValue &
            UIView.AnimationOptions.curveEaseInOut.rawValue)
    // 消失动画的配置block
    open var dismissAnimateBlock: (()->())?
    
    func setup(contentView: UIView, backgroundView: TbBackgroundView, containerView: UIView) {
    }
    
    func display(contentView: UIView, backgroundView: TbBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: displayDuration, delay: 0, options: displayAnimationOptions, animations: {
                self.displayAnimateBlock?()
            }) { (finished) in
                completion()
            }
        }else {
            self.displayAnimateBlock?()
            completion()
        }
    }
    
    func dismiss(contentView: UIView, backgroundView: TbBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: dismissDuration, delay: 0, options: dismissAnimationOptions, animations: {
                self.dismissAnimateBlock?()
            }) { (finished) in
                completion()
            }
        } else {
            dismissAnimateBlock?()
            completion()
        }
    }
}

open class TbPopupViewLeftwardAnimator: TbPopupViewBaseAnimator {
    override func setup(contentView: UIView, backgroundView: TbBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.x = containerView.bounds.size.width
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0
        
        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 0
        }
        
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
        
    }
}

open class TbPopupViewRightwardAnimator: TbPopupViewBaseAnimator {
    override func setup(contentView: UIView, backgroundView: TbBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.x = -contentView.bounds.size.width
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0
        
        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
    }
}

open class TbPopupViewUpwardAnimator: TbPopupViewBaseAnimator {
    override func setup(contentView: UIView, backgroundView: TbBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.y = containerView.bounds.size.height
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0
        
        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
    }
}

open class TbPopupViewDownwardAnimator: TbPopupViewBaseAnimator {
    override func setup(contentView: UIView, backgroundView: TbBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.y = -contentView.bounds.size.height
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0
        
        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
    }
}

open class TbPopupViewZoomInOutAnimator: TbPopupViewBaseAnimator {
    override func setup(contentView: UIView, backgroundView: TbBackgroundView, containerView: UIView) {
       
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        displayAnimateBlock = {
            contentView.alpha = 1
            contentView.transform = .identity
            backgroundView.alpha = 1
        }
        
        dismissAnimateBlock = {
            contentView.alpha = 0
            contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            backgroundView.alpha = 0
        }
    }
}

open class TbPopupViewFadeInOutAnimator: TbPopupViewBaseAnimator {
    override func setup(contentView: UIView, backgroundView: TbBackgroundView, containerView: UIView) {
       
        contentView.alpha = 0
        backgroundView.alpha = 0
        
        displayAnimateBlock = {
            contentView.alpha = 1
            backgroundView.alpha = 1
        }
        
        dismissAnimateBlock = {
            contentView.alpha = 0
            backgroundView.alpha = 0
        }
    }
}

class JXPopupViewSpringDownwardAnimator: TbPopupViewDownwardAnimator {

    override func display(contentView: UIView, backgroundView: TbBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: displayAnimationOptions, animations: {
                self.displayAnimateBlock?()
            }) { (finished) in
                completion()
            }
        }else {
            self.displayAnimateBlock?()
            completion()
        }
    }
}

