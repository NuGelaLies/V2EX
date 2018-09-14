import UIKit

extension UIView {

    var layoutGuide: UILayoutGuide {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide
        } else {
            return layoutMarginsGuide
        }
    }

    var layoutInsets: UIEdgeInsets {
        if #available(iOS 11, *) {
            return safeAreaInsets
        } else {
            return layoutMargins
        }
    }

    /// 给View加上圆角
    @IBInspectable var setCornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = newValue > 0
        }
    }

    /// 根据类查找视图
    ///
    /// - Parameter superViewClass: 类
    /// - Returns: View
    func findSuperView<T>(cls superViewClass : T.Type) -> T? {
        
        var xsuperView: UIView! = self.superview!
        var foundSuperView: UIView!
        
        while (xsuperView != nil && foundSuperView == nil) {
            
            if xsuperView.self is T {
                foundSuperView = xsuperView
            } else {
                xsuperView = xsuperView.superview
            }
        }
        return foundSuperView as? T
    }


    @discardableResult
    public func addSubviews(_ subviews: UIView...) -> UIView{
        subviews.forEach(addSubview)
        return self
    }
    
    @discardableResult
    public func addSubviews(_ subviews: [UIView]) -> UIView{
        subviews.forEach (addSubview)
        return self
    }
    
    func addTapGesture() -> UITapGestureRecognizer {
        let tapGesture = UITapGestureRecognizer()
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        return tapGesture
    }
    
    func addLongPressGesture() -> UILongPressGestureRecognizer {
        let longPressGesture = UILongPressGestureRecognizer()
        addGestureRecognizer(longPressGesture)
        isUserInteractionEnabled = true
        return longPressGesture
    }
    
    /// 删除所有View
    public func removeAllSubviews() {
        while subviews.count != 0 {
            subviews.last?.removeFromSuperview()
        }
    }
    
    public func responderViewController() -> UIViewController {
        var responder: UIResponder!
        var nextResponder = superview?.next
        repeat {
            responder = nextResponder
            nextResponder = nextResponder?.next
            
        } while !(responder.isKind(of: UIViewController.self))
        return responder as! UIViewController
    }

    public func shake() {
        self.transform = CGAffineTransform(translationX: 10, y: 0)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 50, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
            self.transform = .identity
        }, completion: nil)
    }
    
    /// Create a shake effect.
    ///
    /// - Parameters:
    ///   - count: Shakes count. Default is 2.
    ///   - duration: Shake duration. Default is 0.15.
    ///   - translation: Shake translation. Default is 5.
    func shake(count: Float = 2, duration: TimeInterval = 0.15, translation: Float = 5) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.repeatCount = count
        animation.duration = (duration) / TimeInterval(animation.repeatCount)
        animation.autoreverses = true
        animation.byValue = translation
        
        self.layer.add(animation, forKey: "shake")
    }
    

    /// 使用视图的alpha创建一个淡出动画
    public func fadeOut(_ duration: TimeInterval = 0.4, delay: TimeInterval = 0.0, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }

    /// 使用视图的alpha创建一个淡入动画
    public func fadeIn(_ duration: TimeInterval = 0.4, delay: TimeInterval = 0.0, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: completion)
    }
}


extension UIView {
    
    func screenshotForCroppingRect(croppingRect:CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(croppingRect.size, false, UIScreen.main.scale);
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: -croppingRect.origin.x, y: -croppingRect.origin.y)
        self.layoutIfNeeded()
        self.layer.render(in: context)
        
        let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshotImage
    }
    
    var screenshot: UIImage? {
        return screenshotForCroppingRect(croppingRect: bounds)
    }
}
