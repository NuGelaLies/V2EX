//
//  ShadowSegementSlideViewController.swift
//  Example
//
//  Created by Jiar on 2018/12/13.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit
import SegementSlide

class ConfigManager {
    static let shared = ConfigManager()
    
    var switcherConfig: SegementSlideSwitcherConfig
    
    init() {
        switcherConfig = SegementSlideSwitcherConfig()
    }
}

internal extension CALayer {
    
    func applySketchShadow(
        color: UIColor = .black,
        alpha: Float = 0.25,
        x: CGFloat = 0,
        y: CGFloat = 3,
        blur: CGFloat = 6,
        spread: CGFloat = 0)
    {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
    
}

class BaseSegementSlideViewController: SegementSlideViewController {
    
    override var switcherConfig: SegementSlideSwitcherConfig {
        return ConfigManager.shared.switcherConfig
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView, isParent: Bool) {
        super.scrollViewDidScroll(scrollView, isParent: isParent)
        guard isParent else { return }
        updateNavigationBarStyle(scrollView)
    }
    
    private func updateNavigationBarStyle(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > headerStickyHeight {
            slideSwitcherView.layer.applySketchShadow(color: .black, alpha: 0.03, x: 0, y: 2.5, blur: 5)
            slideSwitcherView.layer.add(generateFadeAnimation(), forKey: "reloadSwitcherView")
        } else {
            slideSwitcherView.layer.applySketchShadow(color: .clear, alpha: 0, x: 0, y: 0, blur: 0)
            slideSwitcherView.layer.add(generateFadeAnimation(), forKey: "reloadSwitcherView")
        }
    }
    
    private func generateFadeAnimation() -> CATransition {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = 0.25
        fadeTextAnimation.type = .fade
        return fadeTextAnimation
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        debugPrint("\(type(of: self)) - \(String(format: "%p", self)) - \(#function)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        debugPrint("\(type(of: self)) - \(String(format: "%p", self)) - \(#function)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debugPrint("\(type(of: self)) - \(String(format: "%p", self)) - \(#function)")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        debugPrint("\(type(of: self)) - \(String(format: "%p", self)) - \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint("\(type(of: self)) - \(String(format: "%p", self)) - \(#function)")
    }
    
}
