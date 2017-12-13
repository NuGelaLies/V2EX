import UIKit


class SettingViewController: UITableViewController {

    enum SettingItemType {
        case accounts
        case browser, nightMode, fontSize, baiduOCRConfig, logout, fullScreenBack, shakeFeedback
        case tabSort
        case floor
    }
    struct SettingItem {
        var title: String
        var type: SettingItemType
        var rightType: RightType
    }

    // MARK: - Propertys

    private var sections: [[SettingItem]] = [
        [
            SettingItem(title: "使用 Safari 浏览网页", type: .browser, rightType: .switch),
            SettingItem(title: "全屏返回手势", type: .fullScreenBack, rightType: .switch),
            SettingItem(title: "夜间模式", type: .nightMode, rightType: .switch),
            SettingItem(title: "摇一摇反馈", type: .shakeFeedback, rightType: .switch)
        ],
        [
            SettingItem(title: "节点排序", type: .tabSort, rightType: .arrow),
            SettingItem(title: "调节字体", type: .fontSize, rightType: .arrow),
            SettingItem(title: "@用户时带楼层号(@devjoe #1)", type: .floor, rightType: .switch),
        ],
        [
            SettingItem(title: "OCR 配置", type: .baiduOCRConfig, rightType: .arrow),
        ],
        [
            SettingItem(title: "退出账号", type: .logout, rightType: .none)
        ]
    ]

    // MARK: - View Life Cycle

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cellWithClass: BaseTableViewCell.self)

        ThemeStyle.style
            .asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.backgroundColor = theme.bgColor
                self?.tableView.separatorColor = theme.borderColor
        }.disposed(by: rx.disposeBag)

//        if AccountModel.isLogin {
//            let section = [SettingItem(title: "账号管理", type: .accounts, rightType: .arrow)]
//            sections.insert(section, at: 0)
//        }
    }

}

// MARK: - UITableViewDelegate
extension SettingViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return AccountModel.isLogin ? sections.count : sections.count - 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
        cell.selectionStyle = .none
        
        let item = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = item.title
        cell.rightType = item.rightType
        cell.textLabel?.textAlignment = item.type == .logout ? .center : .left
        cell.textLabel?.textColor = item.type == .logout ? .red : ThemeStyle.style.value.titleColor
        switch item.type {
        case .browser:
            cell.switchView.isOn = Preference.shared.useSafariBrowser
        case .fullScreenBack:
            cell.switchView.isOn = Preference.shared.enableFullScreenGesture
        case .nightMode:
            cell.switchView.isOn = Preference.shared.nightModel
        case .shakeFeedback:
            cell.switchView.isOn = Preference.shared.shakeFeedback
        case .floor:
            cell.switchView.isOn = Preference.shared.atMemberAddFloor
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? BaseTableViewCell else { return }
        cell.switchView.setOn(!cell.switchView.isOn, animated: true)
        let item = sections[indexPath.section][indexPath.row]

        if item.rightType == .switch {
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            } else {
                // Fallback on earlier versions
            }
        }
        
        switch item.type {
        case .accounts:
            navigationController?.pushViewController(AccountsViewController(), animated: true)
        case .browser:
            Preference.shared.useSafariBrowser = cell.switchView.isOn
        case .fullScreenBack:
            Preference.shared.enableFullScreenGesture = cell.switchView.isOn
        case .nightMode:
            Preference.shared.nightModel = cell.switchView.isOn
        case .shakeFeedback:
            Preference.shared.shakeFeedback = cell.switchView.isOn
        case .fontSize:
            let adjustFontVC = AdjustFontViewController()
            navigationController?.pushViewController(adjustFontVC, animated: true)
        case .tabSort:
            let sortVC = TabSortViewController()
            navigationController?.pushViewController(sortVC, animated: true)
        case .baiduOCRConfig:
            let vc = OCRConfigViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .logout:
            AccountModel.delete()
            HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
            presentLoginVC()
            tableView.reloadData()
        case .floor:
            Preference.shared.atMemberAddFloor = cell.switchView.isOn
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
