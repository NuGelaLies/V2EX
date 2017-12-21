import Foundation
import UIKit

class TopicSearchHistoryViewController: UITableViewController {
    
    // MARK: - UI
    
    private lazy var historyTableFooterView: UIButton = {
        let view = UIButton()
        view.size = CGSize(width: Constants.Metric.screenWidth, height: 44)
        view.setTitleColor(.red, for: .normal)
        view.adjustsImageWhenHighlighted = false
        view.setTitle("清除历史记录", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        view.borderTop = Border(size: 0.5, color: ThemeStyle.style.value.borderColor)
        return view
    }()
    
    // MARK: - Property
    
    private var historys: [String] = []
    
    public var querys: [String] {
        return historys
    }
    
    public var didSelectItemHandle: ((String) -> Void)?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupRx()
    }
    
    deinit {
        log.verbose(className + " Deinit")
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        
        tableView.tableFooterView = historyTableFooterView
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 50
        tableView.register(cellWithClass: BaseTableViewCell.self)
        tableView.separatorColor = ThemeStyle.style.value.cellBackgroundColor
        tableView.separatorInset = .zero
        tableView.backgroundColor = ThemeStyle.style.value.whiteColor
        readLocalSearchHistory()
    }
    
    private func setupRx() {
        
        historyTableFooterView.rx
            .tap
            .subscribeNext { [weak self] in
                self?.deleteLocalSearchHistory()
            }.disposed(by: rx.disposeBag)
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.historyTableFooterView.borderTop = Border(size: 0.5, color: theme == .day ? theme.borderColor : theme.cellBackgroundColor)
                self?.tableView.separatorColor = theme == .day ? theme.borderColor : theme.cellBackgroundColor
        }.disposed(by: rx.disposeBag)
    }
}

// MARK: - Actions
extension TopicSearchHistoryViewController {
    public func appendLocal(_ query: String) {
        self.saveToLocalSearchHistory(query: query.trimmed)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension TopicSearchHistoryViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.tableFooterView?.isHidden = historys.count.boolValue.not
        return historys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: BaseTableViewCell.self)!
        cell.backgroundColor = ThemeStyle.style.value.cellBackgroundColor
        cell.imageView?.image = #imageLiteral(resourceName: "searchHistory")
        cell.textLabel?.text = historys[indexPath.row]
        cell.textLabel?.textColor = UIColor.hex(0x6C7273)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt  indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let query = historys[indexPath.row]
        didSelectItemHandle?(query)
        saveToLocalSearchHistory(query: query)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(
            style: .destructive,
            title: "删除") { [weak self] _, indexPath in
                self?.historys.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .bottom)
                self?.saveToLocalSearchHistory()
        }
        return [deleteAction]
    }
}


// MARK: - Local
extension TopicSearchHistoryViewController {
    
    private func readLocalSearchHistory() {
        guard let history = UserDefaults.get(forKey: Constants.Keys.topicSearchHistory) as? [String] else {
            return
        }
        
        historys = history
        tableView.reloadData()
    }
    
    private func saveToLocalSearchHistory(query: String? = nil) {
        
        if let `query` = query {
            if let index = historys.index(of: query) {
                historys.remove(at: index)
            }
            historys.insert(query, at: 0)
        }
        
        UserDefaults.save(at: historys, forKey: Constants.Keys.topicSearchHistory)
        tableView.reloadData()
    }
    
    private func deleteLocalSearchHistory() {
        historys.removeAll()
        tableView.reloadData()
        UserDefaults.remove(forKey: Constants.Keys.topicSearchHistory)
    }
}
