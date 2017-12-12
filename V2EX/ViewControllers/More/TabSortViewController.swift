import UIKit

class TabSortViewController: UITableViewController, NodeService {

    // MARK: - UI

    private lazy var saveItem: UIBarButtonItem = {
        let view = UIBarButtonItem(barButtonSystemItem: .save)
        view.isEnabled = false
        return view
    }()

    // MARK: - Propertys
    
    private var nodes: [NodeModel] = []

    // MARK: - View Life Cycle

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        nodes = homeNodes().filter { $0.title != "关注" }
        title = "节点排序"

        tableView.backgroundColor = ThemeStyle.style.value.bgColor
        tableView.separatorColor = ThemeStyle.style.value.borderColor
        tableView.register(cellWithClass: BaseTableViewCell.self)
        tableView.setEditing(true, animated: false)

        navigationItem.rightBarButtonItem = saveItem

        saveItem.rx.tap
            .subscribeNext { [weak self] in
                guard let `self` = self else { return }
                if let error = self.updateHomeNodes(nodes: self.nodes) {
                    HUD.showError(error)
                } else {
//                    NotificationCenter.default.post(name: Notification.Name.V2.HomeTabSortFinishName, object: self.nodes)
                    HUD.showSuccess("保存成功，设置将在App下次启动时生效", duration: 1.5, completionBlock: {
                        self.navigationController?.popViewController(animated: true)
                    })
                }
        }.disposed(by: rx.disposeBag)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }
}

extension TabSortViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
        cell.textLabel?.text = nodes[indexPath.row].title
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "长按拖动改变排序"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "排序完成后请按 \"存储\" 按钮，该设置将在App下次启动时生效"
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        saveItem.isEnabled = true
        guard sourceIndexPath != destinationIndexPath else { return }
        nodes.move(from: sourceIndexPath.row, to : destinationIndexPath.row)
    }
}

extension Array {
    mutating func move(from sourceIndex: Int, to destinationIndex: Int) {
        let item = self.remove(at: sourceIndex)
        self.insert(item, at: destinationIndex)
    }
}
