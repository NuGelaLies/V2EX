import UIKit
import RxSwift
import RxCocoa


class DarkWindow: UIWindow {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard
            Preference.shared.autoSwitchThemeForSystem,
            #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)
            else { return
        }
        
        switch self.traitCollection.userInterfaceStyle {
        case .dark:
            ThemeStyle.style.value = Preference.shared.nightTheme
        case .light:
            ThemeStyle.style.value = .day
        default:
            break
        }
    }
}

public final class AppWindow {
    
    static let shared = AppWindow()
    
    private var bag = DisposeBag()
    
    var window: DarkWindow
    
    private init() {
        window = DarkWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
    }
    
    func prepare() {
        window.rootViewController = TabBarViewController()
        window.makeKeyAndVisible()
        
        // YYText 切换 KeyWindow 在混编情况下会奔溃，换成通知 App 自处理
        NotificationCenter.default.rx
            .notification(Notification.Name("YYTextEffectWindowBecomeKeyWindowNotification"))
            //            .takeUntil(window.rx.deallocating)
            .subscribeNext { [weak self] _ in
                self?.window.makeKeyAndVisible()
        }.disposed(by: bag)
    }
    
    func makeRootViewController(_ viewController: UIViewController) {
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            if let rootViewController = self.window.rootViewController {
                rootViewController.view.alpha = 0.2
            }
        }) { (_) -> Void in
            self.window.rootViewController = viewController
            
            if let rootViewController = self.window.rootViewController {
                rootViewController.view.alpha = 0.2
            }
            
            UIView.animate(withDuration: 0.5) { () -> Void in
                if let rootViewController = self.window.rootViewController {
                    rootViewController.view.alpha = 1
                }
            }
        }
    }
}
