import UIKit

class TabSortViewController: UITableViewController, NodeService {

    // MARK: - UI

    private lazy var saveItem: UIBarButtonItem = {
        let view = UIBarButtonItem(barButtonSystemItem: .save)
        view.isEnabled = false
        return view
    }()

    private lazy var addItem: UIBarButtonItem = {
        let view = UIBarButtonItem(title: "添加")
        view.isEnabled = self.nodes.count < Constants.Config.MaxShowNodeCount
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

        navigationItem.rightBarButtonItems = [saveItem, addItem]

        setupRx()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }
    
    private func setupRx() {
        
        saveItem.rx.tap
            .subscribeNext { [weak self] in
                guard let `self` = self else { return }
                if let error = self.updateHomeNodes(nodes: self.nodes) {
                    HUD.showError(error)
                } else {
                    //                    NotificationCenter.default.post(name: Notification.Name.V2.HomeTabSortFinishName, object: self.nodes)
                    HUD.showSuccess("保存成功，该设置将在App下次启动时生效")
                }
            }.disposed(by: rx.disposeBag)
        
        addItem.rx.tap
            .subscribeNext { [weak self] in
                self?.addNodeHandle()
            }.disposed(by: rx.disposeBag)
    }
    
    private func addNodeHandle() {
        let allNodeVC = AllNodesViewController()
        allNodeVC.title = "添加节点"
        let nav = NavigationViewController(rootViewController: allNodeVC)
        present(nav, animated: true, completion: nil)
        
        allNodeVC.didSelectedNodeHandle = { [weak self] node in
            guard let `self` = self else { return }
            self.saveItem.isEnabled = true

            if let oldIndex = self.nodes.index(of: node) {
                self.nodes.move(from: oldIndex, to: self.nodes.count - 1)
                self.tableView.reloadData()
                return
            }
            self.nodes.append(node)
            self.tableView.reloadData()
            self.addItem.isEnabled = self.nodes.count < Constants.Config.MaxShowNodeCount
        }
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
        return "排序完成后请按 \"存储\" 按钮，该设置将在App下次启动时生效\n\n\n点击 \"添加\" 可以添加任意您感兴趣的节点\n目前最多添加 \(Constants.Config.MaxShowNodeCount), 最少保留 \(Constants.Config.MinShowNodeCount) 个节点"
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        addItem.isEnabled = self.nodes.count <= Constants.Config.MaxShowNodeCount
        saveItem.isEnabled = true
        nodes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return nodes.count <= Constants.Config.MinShowNodeCount ? .none : .delete
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath != destinationIndexPath else { return }
        saveItem.isEnabled = true
        nodes.move(from: sourceIndexPath.row, to : destinationIndexPath.row)
    }
}

extension Array {
    mutating func move(from sourceIndex: Int, to destinationIndex: Int) {
        let item = self.remove(at: sourceIndex)
        self.insert(item, at: destinationIndex)
    }
}
