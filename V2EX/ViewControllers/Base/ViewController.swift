import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.applicationSupportsShakeToEdit = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake, Preference.shared.shakeFeedback else { return }

        let alertVC = UIAlertController(title: "需要帮助?", message: "你可以从 更多->设置 页面找到该功能", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "意见反馈", style: .default, handler: { alert in
            let receiverEmail = "mailto:\(Constants.Config.receiverEmail)?"
            let subject = "subject=\(UIApplication.appDisplayName()) iOS 反馈"
            let body = "body=\n\n\n\n[运行环境] \(UIDevice.phoneModel)(\(UIDevice.current.systemVersion))-\(UIApplication.appVersion())(\(UIApplication.appBuild()))"
            var content = receiverEmail + subject + "&" + body
            content = content.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? receiverEmail
            guard let url = URL(string: content) else { return }
            UIApplication.shared.openURL(url)
        }))

        let text = ThemeStyle.style.value == .day ? "开启夜间模式" : "关闭夜间模式"
        alertVC.addAction(UIAlertAction(title: text, style: .default, handler: { alert in
            Preference.shared.nightModel = !Preference.shared.nightModel
        }))

        alertVC.addAction(UIAlertAction(title: "关闭摇一摇", style: .default, handler: { alert in
            Preference.shared.shakeFeedback = !Preference.shared.shakeFeedback
        }))

        alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }

}
