import UIKit

class NotificationViewController: BaseViewController, AccountService {
    
    private lazy var explainLabel: UILabel = {
        let view = UILabel()
        view.text =
        """
        启用 "消息推送" 推送服务，当您的账号有未读提醒时，App 将消息推送给您的设备。
        
        在启用该服务前，请知悉以下内容：
        
        • 该服务目前属于测试期间，目前它是免费的.
        • App 会收集您的 "Access Token"，以获取新消息。但是请放心我们不会收集您的任何隐私，更不会存储您的个人消息.
        • 您可以随时在 "V2EX PC端-消息提醒" 中重置 Token，重置后将无法享用该服务，但您可以随时重新提交更新 Token
        • 消息推送并非实时推送，目前是每十五分钟轮询一次。
        
        """
        view.numberOfLines = 0
        view.font = UIFont.preferredFont(forTextStyle: .body)//UIFont.systemFont(ofSize: 15)
        view.setLineHeight(5)
        return view
    }()
    
    private lazy var confirmBtn: LoadingButton = {
        let view = LoadingButton()
        view.backgroundColor = Theme.Color.globalColor
        view.setTitle("我已了解并启用", for: .normal)
        view.clipsToBounds = true
        view.layer.cornerRadius = 7
        view.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        view.addTarget(self, action: #selector(confirmBtnTap), for: .touchUpInside)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "消息推送"
        view.backgroundColor = .white
        confirmBtn.isLoading = true
        queryUserStatus()
    }
    
    override func setupSubviews() {
        view.addSubviews(explainLabel, confirmBtn)
    }
    
    override func setupConstraints() {
        explainLabel.snp.makeConstraints {
            $0.left.top.right.equalToSuperview().inset(15)
        }
        
        confirmBtn.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(15)
            $0.height.equalTo(44)
            // $0.top.equalTo(explainLabel.snp.bottom).offset(30)
            $0.bottom.equalTo(view.snp.bottomMargin)
        }
    }
    
    @objc private func confirmBtnTap() {
        guard let username = AccountModel.current?.username else {
            HUD.showError("无法获取用户信息")
            return
        }
        HUD.show()
        
        atomFeed(success: { [weak self] feedURL in
            log.info(feedURL)
            self?.addUser(feedURL: feedURL, name: username, success: { [weak self] msg in
                HUD.dismiss()
                HUD.showSuccess(msg)
                JPUSHService.setAlias(username, completion: { (resCode, alia, seq) in
                    log.info(resCode, alia ?? "None", seq)
                }, seq: 2)
                self?.navigationController?.popViewController(animated: true)
            }, failure: { error in
                HUD.dismiss()
                HUD.showError(error)
            })
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }
    
    private func queryUserStatus() {
        guard let username = AccountModel.current?.username else {
            HUD.showError("无法获取用户信息")
            confirmBtn.isEnabled = false
            confirmBtn.isLoading = false
            confirmBtn.alpha = 0.5
            return
        }
        userStatus(username: username, success: { [weak self] isOpen in
            self?.confirmBtn.isLoading = false
            if isOpen {
                self?.confirmBtn.setTitle("已开启，更新 Token", for: .normal)
            }
            log.info(isOpen)
        }) {  [weak self] error in
            self?.confirmBtn.isEnabled = false
            self?.confirmBtn.isLoading = false
            self?.confirmBtn.alpha = 0.5
            HUD.showError(error)
        }
    }
}
