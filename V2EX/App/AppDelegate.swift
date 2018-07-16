import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Properties

    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // MARK: UI
    private var window: UIWindow {
        return AppWindow.shared.window
    }

    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AppWindow.shared.prepare()
        AppSetup.prepare()
        SQLiteDatabase.initDatabase()
        
//        BackgroundFetchService.shared.checkAuthorization()
        
        setupJPush(launchOptions: launchOptions)
        return true
    }

    
//    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//
//        if Preference.shared.isBackgroundEnable == false {
//            completionHandler(.noData)
//            return
//        }
//
//        BackgroundFetchService.shared.performFetchWithCompletionHandler { (result) in
//            GCD.runOnMainThread {
//                completionHandler(result)
//            }
//        }
//    }

    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    func applicationWillTerminate(_ application: UIApplication) {
        SQLiteDatabase.close()
    }
}

// MARK: - Remote Notification
extension AppDelegate {
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        JPUSHService.resetBadge()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 注册APNs成功并上报DeviceToken
        JPUSHService.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log.error("Register remote notifications error ", error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        log.verbose("收到通知", userInfo)
        JPUSHService.handleRemoteNotification(userInfo)
        
        NotificationCenter.default.post(name: NSNotification.Name.V2.ReceiveRemoteNewMessageName, object: userInfo)
    }
}

// MARK: - JPUSHRegisterDelegate
extension AppDelegate: JPUSHRegisterDelegate {
    
    func setupJPush(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        
        if #available(iOS 10.0, *){
            let entiity = JPUSHRegisterEntity()
            entiity.types = Int(UNAuthorizationOptions.alert.rawValue |
                UNAuthorizationOptions.badge.rawValue |
                UNAuthorizationOptions.sound.rawValue)
            JPUSHService.register(forRemoteNotificationConfig: entiity, delegate: self)
        } else if #available(iOS 8.0, *) {
            let types = UIUserNotificationType.badge.rawValue |
                UIUserNotificationType.sound.rawValue |
                UIUserNotificationType.alert.rawValue
            JPUSHService.register(forRemoteNotificationTypes: types, categories: nil)
        }else {
            let type = UIRemoteNotificationType.badge.rawValue |
                UIRemoteNotificationType.sound.rawValue |
                UIRemoteNotificationType.alert.rawValue
            JPUSHService.register(forRemoteNotificationTypes: type, categories: nil)
        }
        
        JPUSHService.setup(withOption: launchOptions,
                           appKey: Constants.Config.JPushAppKey,
                           channel: "App Store",
                           apsForProduction: true)
        
        JPUSHService.setLogOFF()
    }
    
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
        
        let userInfo = response.notification.request.content.userInfo
        
        NotificationCenter.default.post(name: NSNotification.Name.V2.ReceiveRemoteNewMessageName, object: userInfo)
        
        if response.notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self) ?? false {
            JPUSHService.handleRemoteNotification(userInfo)
        }
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!,
                                 withCompletionHandler completionHandler: ((Int) -> Void)!) {
        // 前台收到通知
        let userInfo = notification.request.content.userInfo
        
        if notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self) ?? false {
            JPUSHService.handleRemoteNotification(userInfo)
        }
        
        completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue))
    }
}
