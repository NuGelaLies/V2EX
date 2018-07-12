import UIKit

class NotificationViewController: BaseViewController, AccountService {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let username = AccountModel.current?.username else {
            HUD.showError("无法获取用户信息")
            return
        }
        
        atomFeed(success: { [weak self] feedURL in
            log.info(feedURL)
            self?.addUser(feedURL: feedURL, name: username, success: {
                HUD.showSuccess("操作成功")
                JPUSHService.setAlias(username, completion: { (resCode, alia, seq) in
                    log.info(resCode, alia ?? "None", seq)
                }, seq: 2)
            }, failure: { error in
                HUD.showError(error)
            })
        }) { error in
            HUD.showError(error)
        }
    }
}
