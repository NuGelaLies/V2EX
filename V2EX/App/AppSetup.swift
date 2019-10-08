import Foundation
import UIKit
import IQKeyboardManagerSwift
import YYText

struct AppSetup {

    static func prepare() {
        setupKeyboardManager()
        HUD.configureAppearance()
//        setupFPS()
        setupTheme()
        setupLog()
        checkTheme()
//        UIViewController.swizzleMethod()
    }
}


// MARK: - didFinishLaunchingWithOptions
extension AppSetup {
    
    /// 键盘自处理
    private static func setupKeyboardManager() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 70
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        IQKeyboardManager.shared.disabledDistanceHandlingClasses = [
            CreateTopicViewController.self
        ]
        IQKeyboardManager.shared.disabledToolbarClasses = [
            TopicDetailViewController.self,
            CreateTopicViewController.self
        ]
        IQKeyboardManager.shared.disabledTouchResignedClasses = [
            TopicDetailViewController.self
        ]

        // 支持 YYTextView
//        IQKeyboardManager.shared.registerTextFieldViewClass(
//            YYTextView.self,
//            didBeginEditingNotificationName: NSNotification.Name.YYTextViewTextDidBeginEditing.rawValue,
//            didEndEditingNotificationName: NSNotification.Name.YYTextViewTextDidEndEditing.rawValue
//        )
    }

    private static func setupFPS() {
        #if DEBUG
            DispatchQueue.main.async {
                let label = FPSLabel(frame: CGRect(x: AppWindow.shared.window.bounds.width - 55 - 8, y: 20, width: 55, height: 20))
                label.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
                AppWindow.shared.window.addSubview(label)
            }
        #endif
    }
    
    private static func setupTheme() {
        let themeRawValue = UserDefaults.standard.integer(forKey: Constants.Keys.themeStyle)
        let theme = Theme(rawValue: themeRawValue) ?? .day
        ThemeStyle.update(style: theme)
    }

    private static func setupLog() {
        #if DEBUG
            Logger.logLevel = .debug
        #else
            Logger.logLevel = .warning
        #endif
    }
    
    public static func checkTheme() {
        
        if #available(iOS 13.0, *), Preference.shared.autoSwitchThemeForSystem {
            switch AppWindow.shared.window.traitCollection.userInterfaceStyle {
            case .dark:
                ThemeStyle.style.value = Preference.shared.nightTheme
            case .light:
                ThemeStyle.style.value = .day
            default:
                break
            }
            return
        }
        
        guard Preference.shared.autoSwitchThemeForTime else { return }
        
        let fromDate = defaults[.fromTime]
        let toDate = defaults[.toTime]
        let isBetween = Date().isBetween(from: (hour: fromDate.hour, minute: fromDate.minute), to: (hour: toDate.hour, minute: toDate.minute))
        
        log.info(isBetween)
        if !isBetween {
            Preference.shared.theme = .day
        } else if ThemeStyle.style.value == .day {
            Preference.shared.theme = Preference.shared.nightTheme
        }
    }
}
