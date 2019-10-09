import UIKit

class AppearanceViewController: BaseTableViewController {
    
    private struct RowItem {
        var title: String
        var type: RowItemType
        var rightType: RightType
    }
    
    private enum RowItemType {
        case switchThemeForBrightness, switchThemeForTime, switchThemeForSystem
    }
    
    private enum Section {
        case icons
        case sample
        case adjustFont
        case theme([Theme])
        case autoSwitchTheme([RowItem])
        
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
        
        var footerTitle: String? {
            switch self {
            case .autoSwitchTheme:
                return "在 \(defaults[.fromTime].timeString) - \(defaults[.toTime].timeString) 时间段内，自动切换到夜间模式\n注意：根据时间切换主题时，需要从后台重新进入前台。"
            default:
                return nil
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
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        tableView.estimatedRowHeight = 80
       
        interactivePopDisabled = true
        
        NotificationCenter.default.rx
            .notification(UIScreen.brightnessDidChangeNotification)
            .subscribeNext { [weak self] noti in
                self?.tableView.reloadData()
            }.disposed(by: rx.disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    init() {
        
        var sections: [Section]  = [
            .sample,
            .adjustFont,
            .theme(Theme.allCases)
        ]
        
        var switchThemeRows = [
            RowItem(title: "屏幕变暗时自动开启夜间模式", type: .switchThemeForBrightness, rightType: .switch),
            RowItem(title: "根据时间自动切换夜间模式", type: .switchThemeForTime, rightType: .switch)
        ]
        if #available(iOS 13.0, *) {
            switchThemeRows.insert(RowItem(title: "跟随系统", type: .switchThemeForSystem, rightType: .switch), at: 0)
        }
        sections.append(Section.autoSwitchTheme(switchThemeRows))
        
        if #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons {
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
        case .autoSwitchTheme(let items):
            return items.count
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
                (tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.section - 1)) as? AppearanceSampleCell)?.adjustFont()
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
        case .autoSwitchTheme(let items):
            let item = items[indexPath.row]
            let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
            cell.textLabel?.text = item.title
            cell.rightType = .switch
            cell.selectionStyle = .none
            
            var isOn = false
            switch item.type {
            case .switchThemeForBrightness:
                isOn = Preference.shared.autoSwitchThemeForBrightness
            case .switchThemeForTime:
                isOn = Preference.shared.autoSwitchThemeForTime
            case .switchThemeForSystem:
                isOn = Preference.shared.autoSwitchThemeForSystem
            }
            cell.switchView.isOn = isOn
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerTitle
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

        case .autoSwitchTheme(let items):
            
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            
            switch items[indexPath.row].type {
            case .switchThemeForBrightness:

                if cell.switchView.isOn.not {
                    
                    let callback: ((Theme) -> Void) = { [weak tableView] theme in
                        Preference.shared.nightTheme = theme
                        cell.switchView.setOn(true, animated: true)
                        Preference.shared.autoSwitchThemeForBrightness = true
                        Preference.shared.theme = UIScreen.main.brightness > 0.25 ? .day : theme

                        // 互斥
                        Preference.shared.autoSwitchThemeForSystem = false
                        tableView?.reloadSections(IndexSet(integer: indexPath.section), with: .none)
                    }
                    
                    let alertC = UIAlertController(title: "当您的设备屏幕变暗时自动切换主题", message: "选择一个主题，当您的设备屏幕亮度低于 25% 时，自动切换到该模式", preferredStyle: .actionSheet)
                    alertC.addAction(UIAlertAction(title: Theme.night.description, style: .default, handler: { action in
                        callback(.night)
                    }))
                    alertC.addAction(UIAlertAction(title: Theme.black.description, style: .default, handler: { action in
                        callback(.black)
                    }))
                    alertC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    if let indexPath = tableView.indexPathForSelectedRow,
                        let cell = tableView.cellForRow(at: indexPath) {
                        alertC.popoverPresentationController?.sourceView = cell
                        alertC.popoverPresentationController?.sourceRect = cell.bounds
                    }
                    present(alertC, animated: true, completion: nil)
                } else {
                    cell.switchView.setOn(!cell.switchView.isOn, animated: true)
                    Preference.shared.autoSwitchThemeForBrightness = cell.switchView.isOn
                    
                }
                
            case .switchThemeForTime:
                cell.switchView.setOn(!cell.switchView.isOn, animated: true)
                Preference.shared.autoSwitchThemeForTime = cell.switchView.isOn
                
                if cell.switchView.isOn {
                    // 互斥
                    Preference.shared.autoSwitchThemeForSystem = false
                    tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
                    
                    GCD.delay(0.3) {
                        let datePickerVC = DatePickerViewController()
                        self.navigationController?.pushViewController(datePickerVC, animated: true)
                    }
                }
            case .switchThemeForSystem:
                guard #available(iOS 13.0, *) else { return }
                
                cell.switchView.setOn(!cell.switchView.isOn, animated: true)
                Preference.shared.autoSwitchThemeForSystem = cell.switchView.isOn
                
                if cell.switchView.isOn {
                    let callback: ((Theme) -> Void) = { [weak tableView] theme in
                        Preference.shared.nightTheme = theme
                        Preference.shared.autoSwitchThemeForTime = false
                        Preference.shared.autoSwitchThemeForBrightness = false
                        
                        switch self.traitCollection.userInterfaceStyle {
                        case .dark:
                            ThemeStyle.style.value = Preference.shared.nightTheme
                        case .light:
                            ThemeStyle.style.value = .day
                        default:
                            break
                        }
                        
                        tableView?.reloadSections(IndexSet(arrayLiteral: indexPath.section, indexPath.section - 1), with: .none)
                    }
                    
                    let alertC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alertC.addAction(UIAlertAction(title: Theme.night.description, style: .default, handler: { action in
                        callback(.night)
                    }))
                    alertC.addAction(UIAlertAction(title: Theme.black.description, style: .default, handler: { action in
                        callback(.black)
                    }))
                    alertC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    if let indexPath = tableView.indexPathForSelectedRow,
                        let cell = tableView.cellForRow(at: indexPath) {
                        alertC.popoverPresentationController?.sourceView = cell
                        alertC.popoverPresentationController?.sourceRect = cell.bounds
                    }
                    present(alertC, animated: true, completion: nil)
                }
            }
            
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
