import UIKit
import MessageUI
import MobileCoreServices
import Kingfisher

class MoreViewController: BaseViewController, AccountService, MemberService {

    enum MoreItemType {
        case user
        case createTopic, nodeCollect, myFavorites, follow, myTopic, myReply, nightMode
        case about, setting
    }
    struct MoreItem {
        var icon: UIImage
        var title: String
        var type: MoreItemType
        var rightType: RightType
    }

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.sectionHeaderHeight = 10
        view.register(cellWithClass: MoreUserCell.self)
        view.register(cellWithClass: BaseTableViewCell.self)
        self.view.addSubview(view)
        return view
    }()

    private lazy var imagePicker: UIImagePickerController = {
        let view = UIImagePickerController()
        view.allowsEditing = true
        view.mediaTypes = [kUTTypeImage as String]
        view.delegate = self
        return view
    }()

    // MARK: - Propertys

    private var sections: [[MoreItem]] = [
        [MoreItem(icon: #imageLiteral(resourceName: "avatar"), title: "请先登录", type: .user, rightType: .arrow)],
        [
//            MoreItem(icon: #imageLiteral(resourceName: "createTopic"), title: "创作新主题", type: .createTopic),
            MoreItem(icon: #imageLiteral(resourceName: "nodeCollect"), title: "节点收藏", type: .nodeCollect, rightType: .arrow),
            MoreItem(icon: #imageLiteral(resourceName: "topicCollect"), title: "主题收藏", type: .myFavorites, rightType: .arrow),
//            MoreItem(icon: #imageLiteral(resourceName: "concern"), title: "特别关注", type: .follow, rightType: .arrow),
            MoreItem(icon: #imageLiteral(resourceName: "topic"), title: "我的主题", type: .myTopic, rightType: .arrow),
            MoreItem(icon: #imageLiteral(resourceName: "myReply"), title: "我的回复", type: .myReply, rightType: .arrow)
        ],
        [
            MoreItem(icon: #imageLiteral(resourceName: "nightMode"), title: "夜间模式", type: .nightMode, rightType: .switch),
            MoreItem(icon: #imageLiteral(resourceName: "setting"), title: "设置", type: .setting, rightType: .arrow),
            MoreItem(icon: #imageLiteral(resourceName: "about"), title: "关于", type: .about, rightType: .arrow)
        ]
    ]


    // MARK: - View Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.reloadData()
    }

    // MARK: - Setup

    override func setupSubviews() {
//        if #available(iOS 11.0, *) {
//            navigationController?.navigationBar.prefersLargeTitles = true
//        }
        navigationItem.title = "个人"
        guard AccountModel.isLogin else { return }

        let createTopicItem = UIBarButtonItem(image: #imageLiteral(resourceName: "edit"), style: .plain, action: { [weak self] in
            let viewController = CreateTopicViewController()
            self?.navigationController?.pushViewController(viewController, animated: true)
        })
        navigationItem.rightBarButtonItem = createTopicItem
    }

    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func setupRx() {
        NotificationCenter.default.rx
            .notification(Notification.Name.V2.LoginSuccessName)
            .subscribeNext { [weak self] _ in
                self?.updateUserInfo()
                self?.setupSubviews()
        }.disposed(by: rx.disposeBag)

//        212221
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
//                self?.view.backgroundColor = theme.bgColor
            }.disposed(by: rx.disposeBag)

    }
}

// MARK: - Actions
extension MoreViewController {

    /// 更新用户资料
    private func updateUserInfo() {

        guard let username = AccountModel.current?.username else {
            HUD.dismiss()
            return
        }

        memberProfile(memberName: username, success: { [weak self] member in
            AccountModel(username: member.username, url: member.url, avatar: member.avatar).save()
            self?.tableView.reloadData()
            //            self?.tableView.reloadSections(IndexSet(integer: 0), with: .none)
            HUD.dismiss()
        }) { error in
            HUD.dismiss()
            HUD.showTest(error)
            log.error(error)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MoreViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let item = sections[indexPath.section][indexPath.row]
        if indexPath.section != 0 {
            let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
            cell.textLabel?.text = item.title
            cell.imageView?.image = item.icon
            cell.selectionStyle = .none
            cell.rightType = item.rightType

            switch item.type {
            case .nightMode:
                cell.switchView.isOn = Preference.shared.nightModel
            default:
                break
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withClass: MoreUserCell.self)!
        cell.textLabel?.text = AccountModel.current?.username ?? item.title
        cell.imageView?.image = item.icon
        cell.imageView?.setImage(urlString: AccountModel.current?.avatarNormalSrc, placeholder: item.icon)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.section == 0 || indexPath.section == 1,  !AccountModel.isLogin {
            presentLoginVC()
            return
        }

        let item = sections[indexPath.section][indexPath.row]

        if item.rightType == .switch {
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
        }

        let type = item.type
        var viewController: UIViewController?
        switch type {
        case .user:
            updateAvatarHandle()
        case .createTopic:
            viewController = CreateTopicViewController()
        case .nodeCollect:
            viewController = NodeCollectViewController()
        case .myTopic:
            guard let username = AccountModel.current?.username else { return }
            viewController = MyTopicsViewController(username: username)
        case .myReply:
            guard let username = AccountModel.current?.username else { return }
            viewController = MyReplyViewController(username: username)
        case .follow:
            viewController = BaseTopicsViewController(href: API.following.path)
        case .myFavorites:
            viewController = TopicFavoriteViewController()
        case .setting:
            viewController = SettingViewController()
        case .about:
            viewController = AboutViewController()
        case .nightMode:
            guard let cell = tableView.cellForRow(at: indexPath) as? BaseTableViewCell else { return }
            cell.switchView.setOn(!cell.switchView.isOn, animated: true)
            Preference.shared.nightModel = cell.switchView.isOn
            
            if #available(iOS 10.3, *) {
                let name = cell.switchView.isOn ? "dark" : nil
                UIApplication.shared.setAlternateIconName(name) { error in
                    if let err = error {
                        HUD.showTest(err)
                    }
                }
            }
        }
        guard let vc = viewController else { return }
        
        vc.title = item.title
        navigationController?.pushViewController(vc, animated: true)
    }



    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 80 : 50
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

// MARK: - Upload Avatar
extension MoreViewController {

    private func updateAvatarHandle() {
        let alertView = UIAlertController(title: "修改头像", message: nil, preferredStyle: .actionSheet)
        alertView.addAction(UIAlertAction(title: "拍照", style: .default, handler: { action in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))

        alertView.addAction(UIAlertAction(title: "相册", style: .default, handler: { action in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))

        alertView.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
            log.info("Cancle")
        }))

        if let avatarCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            alertView.popoverPresentationController?.sourceView = avatarCell
            alertView.popoverPresentationController?.sourceRect = avatarCell.bounds
        }
        present(alertView, animated: true, completion: nil)
    }

    private func uploadAvatarHandle(_ path: String) {
        HUD.show()
        updateAvatar(localURL: path, success: { [weak self] in
            self?.updateUserInfo()
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MoreViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        guard var image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        image = image.resized(by: 0.7)
        guard let data = UIImageJPEGRepresentation(image, 0.5) else { return }

        let path = FileManager.document.appendingPathComponent("smfile.png")
        let error = FileManager.save(data, savePath: path)
        if let err = error {
            HUD.showTest(err)
            log.error(err)
        }
        uploadAvatarHandle(path)
    }
}


