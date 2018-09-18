import Crashlytics
import UIKit

enum LoginType: String {
    case app = "App"
    case google = "Google"
}

struct AnswersEvents {
    
    static func logError(_ error: String) {
        Answers.logCustomEvent(withName: "Error Log", customAttributes: [
            "Error Info": error,
            "App Info": "\(UIDevice.phoneModel)(\(UIDevice.current.systemVersion))-\(UIApplication.appVersion())(\(UIApplication.appBuild()))"])
    }
    static func logWarning(_ info: String) {
        Answers.logCustomEvent(withName: "Warning Log", customAttributes: [
            "Warning Info": info,
            "App Info": "\(UIDevice.phoneModel)(\(UIDevice.current.systemVersion))-\(UIApplication.appVersion())(\(UIApplication.appBuild()))"])
    }
}
