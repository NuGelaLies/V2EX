import UIKit

class AppearanceViewController: BaseTableViewController {

    private enum Section {
        case icons
        case sample
        case adjustFont
        case theme([Theme])
        case autoSwitchTheme(String)
        
        var title: String? {
            switch self {
            case .icons:
                return "图标"
            case .sample:
                return "预览"
            case .adjustFont:
                return "字体大小"
            case .theme:
                return "主题"
            case .autoSwitchTheme:
                return "切换主题"
            }
        }
    }
    
    private let sections: [Section]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cellWithClass: BaseTableViewCell.self)
        tableView.register(cellWithClass: AppearanceSampleCell.self)
        tableView.register(cellWithClass: AppearanceSliderCell.self)
        tableView.register(nib: UINib(nibName: "AppearanceIconsCell", bundle: nil), withCellClass: AppearanceIconsCell.self)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
       
        interactivePopDisabled = true
        
        NotificationCenter.default.rx
            .notification(UIScreen.brightnessDidChangeNotification)
            .subscribeNext { [weak self] noti in
                self?.tableView.reloadData()
            }.disposed(by: rx.disposeBag)
    }
    
    init() {
        
        var sections: [Section]  = [
            .sample,
            .adjustFont,
            .theme(Theme.allCases),
            .autoSwitchTheme("屏幕变暗时自动开启夜间模式")
        ]
        if #available(iOS 10.3, *) {
            sections.insert(.icons, at: 0)
        }
        self.sections = sections
        
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension AppearanceViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .theme(let themes):
            return themes.count
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        switch section {
        case .icons:
            let cell = tableView.dequeueReusableCell(withClass: AppearanceIconsCell.self)!
            return cell
        case .sample:
            let cell = tableView.dequeueReusableCell(withClass: AppearanceSampleCell.self)!
            return cell
        case .adjustFont:
            let cell = tableView.dequeueReusableCell(withClass: AppearanceSliderCell.self)!
            cell.fontSizeDidChangeCallback = { _ in
                (tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AppearanceSampleCell)?.adjustFont()
                tableView.reloadData()
            }
            return cell
        case .theme(let themes):
            let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
            let theme = themes[indexPath.row]
            cell.textLabel?.text = theme.description
            cell.selectionStyle = .none
            cell.accessoryType = Preference.shared.theme == theme ? .checkmark : .none
            return cell
        case .autoSwitchTheme(let title):
            let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
            cell.textLabel?.text = title
            cell.rightType = .switch
            cell.selectionStyle = .none
            cell.switchView.isOn = Preference.shared.autoSwitchTheme
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? BaseTableViewCell else { return }
        
        let section = sections[indexPath.section]
        switch section {
        case .theme(let themes):
            tableView.reloadData()
            
            let theme = themes[indexPath.row]
            Preference.shared.theme = theme

            cell.accessoryType = .checkmark

        case .autoSwitchTheme:
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            
            if cell.switchView.isOn.not {
                let alertC = UIAlertController(title: "当您的设备屏幕变暗时自动切换主题", message: "选择一个主题，当您的设备屏幕亮度低于 25% 时，自动切换到该模式", preferredStyle: .actionSheet)
                alertC.addAction(UIAlertAction(title: Theme.night.description, style: .default, handler: { action in
                    Preference.shared.nightTheme = .night
                    cell.switchView.setOn(true, animated: true)
                    Preference.shared.autoSwitchTheme = true
                    Preference.shared.theme = UIScreen.main.brightness > 0.25 ? .day : .night
                }))
                alertC.addAction(UIAlertAction(title: Theme.black.description, style: .default, handler: { action in
                    Preference.shared.nightTheme = .black
                    cell.switchView.setOn(true, animated: true)
                    Preference.shared.autoSwitchTheme = true
                    Preference.shared.theme = UIScreen.main.brightness > 0.25 ? .day : .black
                }))
                alertC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                present(alertC, animated: true, completion: nil)
            } else {
                cell.switchView.setOn(!cell.switchView.isOn, animated: true)
                Preference.shared.autoSwitchTheme = cell.switchView.isOn
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
