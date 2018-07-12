import UIKit
import UserNotifications

final class BackgroundFetchService: NSObject, AccountService {
    
    static let shared = BackgroundFetchService()
    var isAskAuthorization: Bool?
    
    fileprivate override init() {
        super.init()
        setup()
    }
    
    public func setup() {
        let isEnable = Preference.shared.isBackgroundEnable

        if isEnable {
            turnOn()
        } else {
            turnOff()
        }
    }
    
    public func turnOn() {
        Preference.shared.isBackgroundEnable = true
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    }
    
    public func turnOff() {
        Preference.shared.isBackgroundEnable = false
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
    }
    
    private func push(messageCount: Int) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = "您有 \(messageCount) 条未读提醒"
//            content.body = String.messageTodayGank
            content.sound = UNNotificationSound.default()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let requestIdentifier = "v2ex now message"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    public func initAuthorization() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                GCD.runOnMainThread { [weak self] in
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        self?.isAskAuthorization = false
                    case .authorized:
                        self?.isAskAuthorization = true
                    case .denied:
                        self?.isAskAuthorization = true
                    }
                }
            })
        }
    }
    
    public func checkAuthorization() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                GCD.runOnMainThread { [weak self] in
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        self?.authorize()
                    case .authorized:
                        log.verbose("UserNotifications authorized")
                    case .denied:
                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                    }
                }
            })
        }
    }
    
    public func authorize() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                GCD.runOnMainThread { [weak self] in
                    self?.initAuthorization()
                    if granted {
                        self?.turnOn()
                    } else {
                        log.verbose("UserNotifications denied")
                    }
                }
            }
        }
    }
    
    public func performFetchWithCompletionHandler(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
    
        guard AccountModel.isLogin else {
            completionHandler(.noData)
            return
        }
        
        queryNewMessage(success: { [weak self] noticeCount in
            guard noticeCount.boolValue else {
                completionHandler(.noData)
                return
            }
            self?.push(messageCount: noticeCount)
            completionHandler(.newData)
        }) { error in
            completionHandler(.failed)
        }
    }
    
}
