import UIKit

class TabSortViewController: BaseTableViewController, NodeService {

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

        tableView.register(cellWithClass: BaseTableViewCell.self)
        tableView.setEditing(true, animated: false)

        navigationItem.rightBarButtonItem = saveItem

        setupRx()
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
        }
    }
}

extension TabSortViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!

        if indexPath.row < nodes.count {
            cell.textLabel?.text = nodes[indexPath.row].title
        } else {
            cell.textLabel?.text = "添加节点"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "长按拖动改变排序"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "编辑完成后请按 \"存储\" 按钮，该设置将在App下次启动时生效\n最少保留 \(Constants.Config.MinShowNodeCount) 个节点"
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row < nodes.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            saveItem.isEnabled = true
            nodes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .insert:
            addNodeHandle()
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.row < nodes.count ? nodes.count <= Constants.Config.MinShowNodeCount ? .none : .delete : .insert
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
