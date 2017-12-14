import UIKit
import StoreKit
import MessageUI

class AboutViewController: UITableViewController {

    enum AbountItemType {
        case grade, sourceCode, clearCache, feedback, libs, about, share
    }
    struct AbountItem {
        var title: String
        var type: AbountItemType
    }

    // MARK: - UI

    private lazy var headerContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var logoView: UIImageView = {
        return UIImageView(image: #imageLiteral(resourceName: "logo"))
    }()

    private lazy var versionLabel: UILabel = {
        let view = UILabel()
        view.text = "\(UIApplication.appDisplayName()) v\(UIApplication.appVersion()) (\(UIApplication.appBuild()))"
        view.textColor = UIColor.hex(0x666666)
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()

    // MARK: - Propertys

    private var sections: [[AbountItem]] = [
        [
            AbountItem(title: "意见反馈", type: .feedback),
            AbountItem(title: "清除缓存", type: .clearCache),
            AbountItem(title: "开源库", type: .libs),
            AbountItem(title: "项目源码", type: .sourceCode),
            AbountItem(title: "给我评分", type: .grade),
            AbountItem(title: "推荐给朋友", type: .share),
        ],
        [
            AbountItem(title: "关于 V2EX", type: .about)
        ]
    ]

    // MARK: - View Life Cycle

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Status Bar Style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cellWithClass: BaseTableViewCell.self)

        headerContainerView.height = 170
        headerContainerView.addSubviews(logoView, versionLabel)
        tableView.tableHeaderView = headerContainerView
        tableView.backgroundColor = ThemeStyle.style.value.bgColor
        tableView.separatorColor = ThemeStyle.style.value.borderColor

        setupConstraints()
    }

    // MARK: - Setup

    private func setupConstraints() {
        logoView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(40)
        }

        versionLabel.snp.makeConstraints {
            $0.top.equalTo(logoView.snp.bottom).offset(20)
            $0.centerX.equalTo(logoView)
        }
    }
}

// MARK: - UITableViewDelegate
extension AboutViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
        cell.rightType = .arrow
        let item = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = item.title
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = sections[indexPath.section][indexPath.row]
        switch item.type {
        case .grade:
            openAppStore()
        case .feedback:
            sendEmail()
        case .sourceCode:
            openWebView(url: API.codeRepo.url)
        case .libs:
            let viewController = LibrarysViewController()
            navigationController?.pushViewController(viewController, animated: true)
        case .clearCache:
            HUD.show()
            FileManager.clearCache(complete: { size in
                HUD.dismiss()
                HUD.showSuccess("缓存清理成功", duration: 2)
            })
        case .share:
            let controller = UIActivityViewController(
                activityItems: [
                    "\(UIApplication.appDisplayName()) - 创意工作者的社区",
                    #imageLiteral(resourceName: "logo"),
                    URL(string: "https://itunes.apple.com/cn/app/v2er/id\(Constants.Config.AppID)") ?? ""],
                applicationActivities: [])

            if let cell = tableView.cellForRow(at: indexPath) {
                controller.popoverPresentationController?.sourceView = cell
                controller.popoverPresentationController?.sourceRect = cell.bounds
            }
            currentViewController().present(controller, animated: true, completion: nil)
        case .about:
            openWebView(url: API.about.url)
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}


// MARK: - SKStoreProductViewControllerDelegate
extension AboutViewController: SKStoreProductViewControllerDelegate {

    private func openAppStore() {
        let storeProductVC = SKStoreProductViewController()
        storeProductVC.delegate = self
        storeProductVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: Constants.Config.AppID]) { [weak self] result, error in
            guard result else {
                if let err = error {
                    HUD.showError(err)
                    log.error(err)
                }
                return
            }
            self?.present(storeProductVC, animated: true, completion: nil)
        }
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}


// MARK: - MFMailComposeViewControllerDelegate
extension AboutViewController: MFMailComposeViewControllerDelegate {

    private func sendEmail() {
        
        guard MFMailComposeViewController.canSendMail() else {
            HUD.showError("操作失败，请先在系统邮件中设置个人邮箱账号。\n或直接通过邮箱向我反馈 email: \(Constants.Config.receiverEmail)", duration: 3)
            return
        }

        let mailVC = MFMailComposeViewController()
        mailVC.setSubject("\(UIApplication.appDisplayName()) iOS 反馈")
        mailVC.setToRecipients([Constants.Config.receiverEmail])
        mailVC.setMessageBody("\n\n\n\n[运行环境] \(UIDevice.phoneModel)(\(UIDevice.current.systemVersion))-\(UIApplication.appVersion())(\(UIApplication.appBuild()))", isHTML: false)
        mailVC.mailComposeDelegate = self
        present(mailVC, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)

        switch result {
        case .sent:
            HUD.showSuccess("感谢您的反馈，我会尽量给您答复。")
        case .failed:
            HUD.showError("邮件发送失败: \(error?.localizedDescription ?? "Unkown")")
        default:
            break
        }

    }
}
