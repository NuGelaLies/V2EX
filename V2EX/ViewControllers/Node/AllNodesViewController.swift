import UIKit

class AllNodesViewController: DataViewController, NodeService {

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.sectionIndexColor = Theme.Color.globalColor
        view.sectionIndexBackgroundColor = .clear
        view.sectionIndexTrackingBackgroundColor = Theme.Color.bgColor
        view.hideEmptyCells()
        view.backgroundColor = .clear
        self.view.addSubview(view)
        return view
    }()

    private lazy var footerLabel: UILabel = {
        let footerLabel = UILabel()
        let nodeTotalCount = groups.compactMap { $0.nodes.count }.reduce(0, +)
        footerLabel.text = "\(nodeTotalCount) 个节点"
        footerLabel.sizeToFit()
        footerLabel.textColor = .gray
        footerLabel.textAlignment = .center
        footerLabel.height = 44
        return footerLabel
    }()

    private lazy var searchResultVC: NodeSearchResultViewController = {
        let view = NodeSearchResultViewController()
        return view
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchResultVC)
        searchController.searchBar.placeholder = "搜索节点"
        searchController.searchBar.tintColor = Theme.Color.globalColor
        searchController.searchBar.barTintColor = Theme.Color.bgColor
        searchController.searchResultsUpdater = searchResultVC
        // SearchBar 边框颜色
        searchController.searchBar.layer.borderWidth = 0.5
        searchController.searchBar.layer.borderColor = Theme.Color.bgColor.cgColor
        searchController.searchBar.isUserInteractionEnabled = false
        // TextField 边框颜色
//        if let searchField = searchController.searchBar.value(forKey: "_searchField") as? UITextField {
//            searchField.layer.borderWidth = 0.5
//            searchField.layer.borderColor = Theme.Color.borderColor.cgColor
//            searchField.layer.cornerRadius = 5.0
//            searchField.layer.masksToBounds = true
//        }
        return searchController
    }()

    // MARK: - Propertys

    private var groups: [NodeCategoryModel] = [] {
        didSet {
            tableView.tableHeaderView = searchController.searchBar
            tableView.reloadData()
            tableView.tableFooterView = footerLabel
            searchResultVC.originData = groups.flatMap { $0.nodes }
            
            if let _ = didSelectedNodeHandle {
                self.searchController.isActive = true
                GCD.delay(0.8) {
                    self.searchController.searchBar.becomeFirstResponder()
                }
            }
        }
    }

    private struct ReuseIdentifier {
        static let NodeCell = "NodeCell"
    }

    public var didSelectedNodeHandle:((NodeModel) -> Void)?


    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, action: { [weak self] in
            self?.dismiss()
        })

        if let callback = didSelectedNodeHandle {
            definesPresentationContext = true
            searchResultVC.didSelectedNodeHandle = { [weak self] node in
                self?.dismiss(animated: true, completion: {
                    callback(node)
                })
            }
        }
    }
    
    // MARK: - Setup

    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func setupRx() {

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
                self?.searchController.searchBar.barStyle = theme == .day ? .default : .black
                self?.searchController.searchBar.keyboardAppearance = theme == .day ? .default : .dark
                self?.searchController.searchBar.barTintColor = theme.bgColor
                self?.searchController.searchBar.layer.borderColor = theme.bgColor.cgColor
                self?.tableView.sectionIndexTrackingBackgroundColor = theme.bgColor
                self?.tableView.subviews.filter { $0.className == UIView.description() }.first?.backgroundColor = theme.bgColor
            }.disposed(by: rx.disposeBag)

        searchController.searchBar.rx
            .textDidEndEditing
            .subscribeNext { [weak self] in
                GCD.delay(0.5, block: {
                    self?.fixColor()
                })
        }.disposed(by: rx.disposeBag)
    }

    // MARK: State Handle

    override func hasContent() -> Bool {
        return groups.count.boolValue
    }

    override func loadData() {
        fetchAllNode()
    }

    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {
        fetchAllNode()
    }

    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
        fetchAllNode()
    }
}

// MARK: - Actions
extension AllNodesViewController {

    /// 获取全部节点
    private func fetchAllNode() {
        startLoading()

        nodes(success: { [weak self] groups in
            self?.groups = groups
            self?.endLoading()
            self?.searchController.searchBar.isUserInteractionEnabled = true
        }) { [weak self] error in
            self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            self?.errorMessage = error
        }
    }

    // 当 HeaderView = Search 会多出一个UIView, 在夜间模式下颜色无法适配, 故修改
    private func fixColor() {
        tableView.subviews.filter { $0.className == UIView.description() }.first?.backgroundColor = ThemeStyle.style.value.bgColor
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AllNodesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].nodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.NodeCell)
        if cell == nil {
            cell = BaseTableViewCell(style: .default, reuseIdentifier: ReuseIdentifier.NodeCell)
        }
        cell?.textLabel?.text = groups[indexPath.section].nodes[indexPath.row].title
        return cell!
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groups[section].name
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let headers = groups.map { $0.name }
        //        headers.insert(UITableViewIndexSearch, at: 0)
        return headers
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        ThemeStyle.style.asObservable()
            .subscribeNext { theme in
                view.tintColor = theme.bgColor
            }.disposed(by: rx.disposeBag)
//        view.tintColor = Theme.Color.bgColor
        //        let header = view as! UITableViewHeaderFooterView
        //        header.textLabel?.textColor = UIColor.white
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let node = groups[indexPath.section].nodes[indexPath.row]

        if let callback = didSelectedNodeHandle {
            dismiss(animated: true, completion: {
                callback(node)
            })
            return
        }

        let nodeDetailVC = NodeDetailViewController(node: node)
        navigationController?.pushViewController(nodeDetailVC, animated: true)
    }
}

