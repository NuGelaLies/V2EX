import UIKit
import UserNotifications
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppWindow.shared.prepare()
        AppSetup.prepare()
        SQLiteDatabase.initDatabase()
        
        MSAppCenter.start("806fb492-298b-4e30-9ab1-03d990487d11", withServices:[
            MSAnalytics.self,
            MSCrashes.self
            ])
//        BackgroundFetchService.shared.checkAuthorization()
        
//        setupJPush(launchOptions: launchOptions)
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
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        AppSetup.checkTheme()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        guard url.scheme == "v2er" else { return true }
        
        let fragmemts = url.fragmemts
        if url.host?.lowercased() == "topic",
            let id = fragmemts["id"]?.trimmed,
            id.count.boolValue {
            
            let topicDetailVC = TopicDetailViewController(topicID: id)
            topicDetailVC.anchor = fragmemts["anchor"]?.int
            ((AppWindow.shared.window.rootViewController as? TabBarViewController)?.selectedViewController as? NavigationViewController)?.pushViewController(topicDetailVC, animated: true)
            
        } else if url.host?.lowercased() == "search",
            let query = fragmemts["query"]?.trimmed {
            
            let resultVC = TopicSearchResultViewController()
            resultVC.autoDisplayKeyboard = false
            let nav = NavigationViewController(rootViewController: resultVC)
            nav.modalTransitionStyle = .crossDissolve
            resultVC.search(query: query)
            (AppWindow.shared.window.rootViewController as? TabBarViewController)?.selectedViewController?.present(nav, animated: true, completion: nil)
        }

        return true
    }
    
}

// MARK: - Remote Notification
//extension AppDelegate {
//
//    func applicationWillEnterForeground(_ application: UIApplication) {
//        application.applicationIconBadgeNumber = 0
//        JPUSHService.resetBadge()
//    }
//
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // 注册APNs成功并上报DeviceToken
//        JPUSHService.registerDeviceToken(deviceToken)
//    }
//
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        log.error("Register remote notifications error ", error)
//    }
//
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
//        log.verbose("收到通知", userInfo)
//        JPUSHService.handleRemoteNotification(userInfo)
//
//        NotificationCenter.default.post(name: NSNotification.Name.V2.ReceiveRemoteNewMessageName, object: userInfo)
//    }
//}
//
// MARK: - JPUSHRegisterDelegate
//extension AppDelegate: JPUSHRegisterDelegate {
//
//    func setupJPush(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
//
//        if #available(iOS 10.0, *){
//            let entiity = JPUSHRegisterEntity()
//            entiity.types = Int(UNAuthorizationOptions.alert.rawValue |
//                UNAuthorizationOptions.badge.rawValue |
//                UNAuthorizationOptions.sound.rawValue)
//            JPUSHService.register(forRemoteNotificationConfig: entiity, delegate: self)
//        } else if #available(iOS 8.0, *) {
//            let types = UIUserNotificationType.badge.rawValue |
//                UIUserNotificationType.sound.rawValue |
//                UIUserNotificationType.alert.rawValue
//            JPUSHService.register(forRemoteNotificationTypes: types, categories: nil)
//        }else {
//            let type = UIRemoteNotificationType.badge.rawValue |
//                UIRemoteNotificationType.sound.rawValue |
//                UIRemoteNotificationType.alert.rawValue
//            JPUSHService.register(forRemoteNotificationTypes: type, categories: nil)
//        }
//
//        JPUSHService.setup(withOption: launchOptions,
//                           appKey: Constants.Config.JPushAppKey,
//                           channel: "App Store",
//                           apsForProduction: true)
//
//        JPUSHService.setLogOFF()
//    }
//
//    @available(iOS 10.0, *)
//    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
//
//        let userInfo = response.notification.request.content.userInfo
//
//        NotificationCenter.default.post(name: NSNotification.Name.V2.ReceiveRemoteNewMessageName, object: userInfo)
//
//        if response.notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self) ?? false {
//            JPUSHService.handleRemoteNotification(userInfo)
//        }
//        completionHandler()
//    }
//
//    @available(iOS 10.0, *)
//    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!,
//                                 withCompletionHandler completionHandler: ((Int) -> Void)!) {
//        // 前台收到通知
//        let userInfo = notification.request.content.userInfo
//
//        if notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self) ?? false {
//            JPUSHService.handleRemoteNotification(userInfo)
//        }
//
//        completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue))
//    }
//}
