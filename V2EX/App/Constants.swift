import Foundation
import UIKit

struct Closure {
    typealias Completion = () -> Void
    typealias Failure = (NSError?) -> Void
}

struct Constants {

    struct Config {
        // App
        static var baseURL = "https://www.v2ex.com"

        static var URIScheme = "https:"
        
        static var receiverEmail = "aidevjoe@gmail.com"

        static var AppID = "1308118507"
        
        static var MaxShowNodeCount = 20
        static var MinShowNodeCount = 6
        
        static let JPushAppKey = "dc6ab72dc79c94580329988f"
    }

    struct Keys {
        // User 登录时的用户名
        static let loginAccount = "loginAccount"
        
        // User 持久化
        static let username = "usernameKey"
        static let avatarSrc = "avatarSrcKey"
        static let accountAvatar = "accountAvatar"

        // 创建主题的草稿
        static let createTopicTitleDraft = "createTopicTitleDraft"
        static let createTopicBodyDraft = "createTopicBodyDraft"
        static let createTopicNodenameDraft = FileManager.caches.appendingPathComponent("createTopicNodenameDraft")

        // Once
        static let once = "once"

        static let nodeGroupCache = FileManager.caches.appendingPathComponent("nodeGroup")

        // 主题
        static let themeStyle = "themeStyle"

        // 同意协议
        static let agreementOfConsent = "agreementOfConsent"

        // 是否使用 App 内置浏览器打开
        static let openWithSafariBrowser = "openWithSafariBrowser"

        // 阅读字体大小的比例
        static let webViewFontScale = "webViewFontScale"

        // 全屏返回手势
        static let fullScreenBack = "fullScreenBack"

        // At 用户时添加楼层
        static let atMemberAddFloor = "atMemberAddFloor"
        
        static let autoSwitchThemeForBrightness = "autoSwitchTheme"
        
        static let autoSwitchThemeForTime = "autoSwitchThemeForTime"
        
        static let nightTheme = "nightTheme"

        // 摇一摇
        static let shareFeedback = "shareFeedback"

        // 识别剪切板链接
        static let recognizeClipboardLink = "recognizeClipboardLink"
        
        // 主题搜索历史
        static let topicSearchHistory = "topicSearchHistory"
        
        static let isBackgroundEnable = "isBackgroundEnable"
        
        static let readMark = "readMark"
        
        static let newReadReset = "newReadReset"
        
        // 屏蔽关键字
        static let ignoreWords = "ignoreWords"

        static let baiduOauthToken = FileManager.document.appendingPathComponent("BaiduOauthToken")
        
        static let baiduAppearence = FileManager.document.appendingPathComponent("BaiduAppearence")

        static let homeNodes = FileManager.document.appendingPathComponent("homeNodes")
        
        static let dbFile = FileManager.document.appendingPathComponent("database/v2er.db")
    }

    struct Metric {
        static let navigationHeight: CGFloat = 64
        static let tabbarHeight: CGFloat = 49

        // 兼容分屏模式， UIScreen.main.bounds 取的是屏幕高度， 此时拿 Windows.bounds
        static let screenWidth: CGFloat = UIDevice.current.isPad ? AppWindow.shared.window.width : UIScreen.main.bounds.width
        static let screenHeight: CGFloat = UIDevice.current.isPad ? AppWindow.shared.window.height : UIScreen.main.bounds.height
    }
    
    struct BaiduOCR {
        static let appKey = "TIOmh950EUreugo3yfiFgUAD"
        static let secretKey = "bxGa5PRFj536csUnO9FhACxUorRgqxcA"
    }
}

// MARK: - 通知
extension Notification.Name {
    
    /// 自定义的通知
    struct V2 {

        /// 解析到 未读提醒 时的通知
        static let UnreadNoticeName = Notification.Name("UnreadNoticeName")

        /// 登录成功通知
        static let LoginSuccessName = Notification.Name("LoginSuccessName")

        /// 点击富文本中的链接通知
        static let HighlightTextClickName = Notification.Name("HighlightTextClickName")

        /// 两步验证通知
        static let TwoStepVerificationName = Notification.Name("TwoStepVerificationName")

        /// 选择了 Home TabbarItem
        static let DidSelectedHomeTabbarItemName = Notification.Name("DidSelectedHomeTabbarItemName")
        
        /// 领取每日奖励通知
        static let DailyRewardMissionName = Notification.Name("DailyRewardMissionName")

        /// 保存节点排序通知
        static let HomeTabSortFinishName = Notification.Name("HomeTabSortFinishName")
        
        /// 远程消息推送
        static let ReceiveRemoteNewMessageName = Notification.Name("ReceiveRemoteNewMessageName")
    }
}


