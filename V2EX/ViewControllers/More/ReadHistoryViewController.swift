import UIKit

class ReadHistoryViewController: DataViewController {

    /// MARK: - UI
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.register(cellWithClass: ReadHistoryCell.self)
        view.keyboardDismissMode = .onDrag
        view.separatorColor = ThemeStyle.style.value.borderColor
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 80
        view.hideEmptyCells()
        self.view.addSubview(view)
        return view
    }()
    
    /// MARK: - Propertys

    private var readHistorys: [TopicModel] = [] {
        didSet {
            tableView.reloadData()
            endLoading()
        }
    }
    
    
    /// MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "浏览历史"
        status = .emptyNoRetry
    }
    
    /// MARK: - Setup
    
    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(0.5).priority(.high)
        }
    }
    
    /// MARK: - Action
    
    private func clearHistoryBarButtonTtem() -> UIBarButtonItem {
        let barItem = UIBarButtonItem(barButtonSystemItem: .trash) { [weak self] in
            self?.readHistorys = []
            GCD.runOnBackgroundThread({
                try? SQLiteDatabase.instance?.clearHistory()
            })
        }
        barItem.tintColor = ThemeStyle.style.value.tintColor
        return barItem
    }
    
    // MARK: State Handle

    override func loadData() {
        startLoading()
        readHistorys = SQLiteDatabase.instance?.loadReadHistory(count: 2000) ?? []
    }
    
    override func hasContent() -> Bool {
        return readHistorys.count.boolValue
    }
}

extension ReadHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        navigationItem.rightBarButtonItem = readHistorys.count.boolValue ? clearHistoryBarButtonTtem() : nil
        return readHistorys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ReadHistoryCell.self)!
        cell.topic = readHistorys[indexPath.row]
        
        log.info(cell.topic?.replyCount)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
        
        let topic = readHistorys[indexPath.row]
        guard let topicId = topic.topicID else {
            HUD.showError("操作失败，无法解析主题 ID")
            return
        }
        let topicDetailVC = TopicDetailViewController(topicID: topicId)
        self.navigationController?.pushViewController(topicDetailVC, animated: true)
        
        guard let topicID = topicId.int, let member = topic.member else { return }
        GCD.runOnBackgroundThread {
            SQLiteDatabase.instance?.addHistory(tid: topicID, title: topic.title, username: member.username, avatarURL: member.avatarSrc, replyCount: topic.replyCount.int)
        }
    }
}
