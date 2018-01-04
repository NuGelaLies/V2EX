import Crashlytics
import UIKit

enum LoginType: String {
    case app = "App"
    case google = "Google"
}

struct AnswersEvents {
    
    static func logInvite() {
        Answers.logInvite(withMethod: nil, customAttributes: ["username": AccountModel.current?.username ?? ""])
    }

    static func logSearch(for query: String) {
        Answers.logSearch(withQuery: query, customAttributes: nil)
    }

    static func logLogin(for loginType: LoginType, succeeded: Bool = true) {
        Answers.logLogin(withMethod: loginType.rawValue, success: succeeded as NSNumber, customAttributes: nil)
    }
    
    static func logConfigOCR() {
        Answers.logCustomEvent(withName: "Config Baidu OCR", customAttributes: nil)
    }
    
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
