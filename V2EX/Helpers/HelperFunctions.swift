import Foundation
import UIKit
import SKPhotoBrowser
import SafariServices

public typealias JSONArray = [[String : Any]]
public typealias JSONDictionary = [String : Any]
public typealias Action = () -> Void

//typealias L10n = R.string.localizable


func clearAccount() {
//    JPUSHService.deleteAlias({ (code, alia, seq) in }, seq: 1)
    
    if let username = AccountModel.current?.username {
        Network.request(target: API.userLogout(username: username), success: nil, failure: nil)
    }
    
    AccountModel.delete()
    HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    URLCache.shared.removeAllCachedResponses()
}

/// Present 登录
func presentLoginVC() {
    clearAccount()
    let nav = NavigationViewController(rootViewController: LoginViewController())
    AppWindow.shared.window.rootViewController?.present(nav, animated: true, completion: nil)
}

enum PhotoBrowserType {
    case image(UIImage)
    case imageURL(String)
}

/// 预览图片
func showImageBrowser(imageType: PhotoBrowserType) {

    var photo: SKPhoto?
    switch imageType {
    case .image(let image):
        photo = SKPhoto.photoWithImage(image)
    case .imageURL(let url):
        photo = SKPhoto.photoWithImageURL(url)
        photo?.shouldCachePhotoURLImage = true
    }
    guard let photoItem = photo else { return }
    SKPhotoBrowserOptions.bounceAnimation = true
    SKPhotoBrowserOptions.enableSingleTapDismiss = true
//    SKPhotoBrowserOptions.displayCloseButton = false
    SKPhotoBrowserOptions.displayStatusbar = false
    
    let photoBrowser = SKPhotoBrowser(photos: [photoItem])
    photoBrowser.initializePageIndex(0)
//    photoBrowser.showToolbar(bool: true)
    var currentVC = AppWindow.shared.window.rootViewController?.currentViewController()
    if currentVC == nil {
        currentVC = AppWindow.shared.window.rootViewController
    }
    currentVC?.present(photoBrowser, animated: true, completion: nil)
}

/// 设置状态栏背景颜色
/// 需要设置的页面需要重载此方法
/// - Parameter color: 颜色
func setStatusBarBackground(_ color: UIColor, borderColor: UIColor = .clear) {
//    guard let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIView,
//        let statusBar = statusBarWindow.value(forKey: "statusBar") as? UIView,
//        statusBar.responds(to:#selector(setter: UIView.backgroundColor)) else { return }
//    
//    if statusBar.backgroundColor == color { return }
//    
//    statusBar.backgroundColor = color
//    statusBar.layer.borderColor = borderColor.cgColor
//    statusBar.layer.borderWidth = 0.5
    
    
//    statusBar.borderBottom = Border(color: borderColor)

//    DispatchQueue.once(token: "com.v2er.statusBar") {
//        statusBar.layer.shadowColor = UIColor.black.cgColor
//        statusBar.layer.shadowOpacity = 0.09
//        statusBar.layer.shadowRadius = 3
//        // 阴影向下偏移 6
//        statusBar.layer.shadowOffset = CGSize(width: 0, height: 6)
//        statusBar.clipsToBounds = false
//    }
}

/// 打开浏览器 （内置 或 Safari）
///
/// - Parameter url: url
func openWebView(url: URL?) {
    guard let `url` = url else { return }

    var currentVC = AppWindow.shared.window.rootViewController?.currentViewController()
    if currentVC == nil {
        currentVC = AppWindow.shared.window.rootViewController
    }

    if Preference.shared.useSafariBrowser {
        let safariVC = SFHandoffSafariViewController(url: url, entersReaderIfAvailable: false)
        if #available(iOS 10.0, *) {
            safariVC.preferredControlTintColor = Theme.Color.globalColor
        } else {
            safariVC.navigationController?.navigationBar.tintColor = Theme.Color.globalColor
        }
        currentVC?.present(safariVC, animated: true, completion: nil)
        return
    }
    if let nav = currentVC?.navigationController {
        let webView = SweetWebViewController()
        webView.url = url
        nav.pushViewController(webView, animated: true)
    } else {
        let safariVC = SFHandoffSafariViewController(url: url)
        currentVC?.present(safariVC, animated: true, completion: nil)
    }
}

func openWebView(url: String) {
    guard let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let `url` = URL(string: urlString) else { return }
    openWebView(url: url)
}

func clickCommentLinkHandle(urlString: String) {
    guard let url = URL(string: urlString) else { return }
    let link = url.absoluteString

    if url.host == nil || (url.host ?? "").lowercased().contains(".v2ex.com") {
        if url.path.contains("/member/") {
            let href = url.path
            let name = href.lastPathComponent
            let member = MemberModel(username: name, url: href, avatar: "")
            let memberPageVC = MemberPageViewController(memberName: member.username)
            AppWindow.shared.window.rootViewController?.currentViewController().navigationController?.pushViewController(memberPageVC, animated: true)
        } else if url.path.contains("/t/") {
            let topicID = url.path.lastPathComponent
            let topicDetailVC = TopicDetailViewController(topicID: topicID)
//            topicDetailVC.anchor = url.fragment?.deleteOccurrences(target: "reply").int
            AppWindow.shared.window.rootViewController?.currentViewController().navigationController?.pushViewController(topicDetailVC, animated: true)
        } else if url.path.contains("/go/") {
            let nodeDetailVC = NodeDetailViewController(node: NodeModel(title: "", href: url.path))
            AppWindow.shared.window.rootViewController?.currentViewController().navigationController?.pushViewController(nodeDetailVC, animated: true)
        } else if link.hasPrefix("https://") || link.hasPrefix("http://") || link.hasPrefix("www."){
            openWebView(url: url)
        }
    } else if link.hasPrefix("https://") || link.hasPrefix("http://") || link.hasPrefix("www."){
        openWebView(url: url)
    }
}


