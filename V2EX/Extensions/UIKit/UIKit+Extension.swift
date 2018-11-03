import UIKit
import RxOptional
import CoreGraphics
import SystemConfiguration.CaptiveNetwork



// MARK: Float、Interger

public extension IntegerLiteralType {
    public var f: CGFloat {
        return CGFloat(self)
    }
}

public extension FloatLiteralType {
    public var f: CGFloat {
        return CGFloat(self)
    }
}


extension CGFloat {

    /// 一半
    public var half: CGFloat {
        return self * 0.5
    }

    public var double: CGFloat {
        return self * 2
    }

    public static var max = CGFloat.greatestFiniteMagnitude

    public static var min = CGFloat.leastNormalMagnitude

}

// MARK: - Int
extension Int {
    public var boolValue: Bool {
        return self > 0
    }
}

extension Bool {
    public var not: Bool {
        return !self
    }

    public var intValue: Int {
        return self ? 1 : 0
    }
}




// MARK: - UserDefaults
extension UserDefaults {
    
    public subscript(key: String) -> Any? {
        get { return value(forKey: key) as Any }
        set {
            switch newValue {
            case let value as Int: set(value, forKey: key)
            case let value as Double: set(value, forKey: key)
            case let value as Bool: set(value, forKey: key)
            case let value as String: set(value, forKey: key)
            case nil: removeObject(forKey: key)
            default: assertionFailure("Invalid value type.")
            synchronize()
            }
        }
    }
    
    public func hasKey(_ key: String) -> Bool {
        return nil != object(forKey: key)
    }
    
    static func save(at value: Any?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }

    static func get(forKey key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    static func remove(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
}



// MARK: - UIApplication
public extension UIApplication {

    /// App版本
    public class func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    /// App构建版本
    public class func appBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }

    public class var iconFilePath: String {
        let iconFilename = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile")
        let iconBasename = (iconFilename as! NSString).deletingPathExtension
        let iconExtension = (iconFilename as! NSString).pathExtension
        return Bundle.main.path(forResource: iconBasename, ofType: iconExtension)!
    }

    public class func iconImage() -> UIImage? {
        guard let image = UIImage(contentsOfFile:self.iconFilePath) else {
            return nil
        }
        return image
    }

    public class func versionDescription() -> String {
        let version = appVersion()
        #if DEBUG
            return "Debug - \(version)"
        #else
            return "Release - \(version)"
        #endif
    }

    public class func appBundleName() -> String{
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    }

    public class func appDisplayName() -> String{
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }

    public class func sendEmail(toAddress address: String) {
        guard address.isNotEmpty else { return }
        UIApplication.shared.openURL(URL(string: "mailto://\(address)")!)
    }

    public class func appReviewPage(with appId: String) {
        guard appId.isNotEmpty else { return }
        var urlString = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(appId)"
        if #available(iOS 11, *) {
            //            urlString = "itms-apps://itunes.apple.com/cn/app/id\(appId)?mt=8&action=write-review"
            //            urlString = "itms-apps://itunes.apple.com/app/viewContentsUserReviews?id=\(appId)"
            urlString = "itms-apps://itunes.apple.com/cn/app/v2er/id\(appId)?mt=8&action=write-review"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.openURL(url)
        }
    }

}


// MARK: - UIDevice

import DeviceKit

extension UIDevice {

    public var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    public var isiPhoneX: Bool {
        if UIDevice.current.userInterfaceIdiom != .phone {
            return false
        }
        
        if #available(iOS 11.0, *) {
            let groupOfAllowedDevices: [Device] = [.iPhoneX, .iPhoneXs, .iPhoneXsMax, .iPhoneXr]
            let device = Device()
            
            return device.isOneOf(groupOfAllowedDevices)
        }
        return false
    }

    /// MARK: - 获取设备型号
    public static var phoneModel: String {
        return Device().description
    }

    /// 判断是不是模拟器
    public static var isSimulator: Bool {
        return UIDevice.phoneModel == "Simulator"
    }

    /// 返回当前屏幕的一个像素的点大小
    public class var onePixel: CGFloat {
        return CGFloat(1.0) / UIScreen.main.scale
    }


    /// 将浮动值返回到当前屏幕的最近像素
    static public func roundFloatToPixel(_ value: CGFloat) -> CGFloat {
        return round(value * UIScreen.main.scale) / UIScreen.main.scale
    }
}



extension NSRange {
    func range(for str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        guard let fromUTFIndex = str.utf16.index(str.utf16.startIndex, offsetBy: location, limitedBy: str.utf16.endIndex) else { return nil }
        guard let toUTFIndex = str.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: str.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: str) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: str) else { return nil }
        return fromIndex ..< toIndex
    }
}



// MARK: - 切换调试器
extension UIViewController {

    func toggleDebugger() {

        #if DEBUG
            let overlayClass = NSClassFromString("UIDebuggingInformationOverlay") as? UIWindow.Type
            _ = overlayClass?.perform(NSSelectorFromString("prepareDebuggingOverlay"))
            let overlay = overlayClass?.perform(NSSelectorFromString("overlay")).takeUnretainedValue() as? UIWindow
            _ = overlay?.perform(NSSelectorFromString("toggleVisibility"))
        #endif
    }

    /// SO: http://stackoverflow.com/questions/24825123/get-the-current-view-controller-from-the-app-delegate
    public func currentViewController() -> UIViewController {
        func findBestViewController(_ controller: UIViewController?) -> UIViewController? {
            if let presented = controller?.presentedViewController { // Presented界面
                return findBestViewController(presented)
            } else {
                switch controller {
                case is UISplitViewController: // Return right hand side
                    let split = controller as? UISplitViewController
                    guard split?.viewControllers.isEmpty ?? true else {
                        return findBestViewController(split?.viewControllers.last)
                    }
                case is UINavigationController: // Return top view
                    let navigation = controller as? UINavigationController
                    guard navigation?.viewControllers.isEmpty ?? true else {
                        return findBestViewController(navigation?.topViewController)
                    }
                case is UITabBarController: // Return visible view
                    let tab = controller as? UITabBarController
                    guard tab?.viewControllers?.isEmpty ?? true else {
                        return findBestViewController(tab?.selectedViewController)
                    }
                default: break
                }
            }
            return controller
        }
        return findBestViewController(UIApplication.shared.keyWindow?.rootViewController)! // 假定永远有
    }

}

