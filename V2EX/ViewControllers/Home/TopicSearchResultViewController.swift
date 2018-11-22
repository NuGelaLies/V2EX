import UIKit
import RxSwift
import RxCocoa

class SearchTitleView: UIView {
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
}

class TopicSearchResultViewController: DataViewController, TopicService {

    // MARK: - UI
    
    private lazy var searchViewContainerView: SearchTitleView = {
        let view = SearchTitleView()
        view.frame = CGRect(x: 0, y: 0, width: Constants.Metric.screenWidth - 50, height: 33)
        view.addSubview(searchTextField)
        return view
    }()

    private lazy var searchTextField: UITextField = {
        let view = UITextField()
        view.frame = CGRect(x: 0, y: 0, width: Constants.Metric.screenWidth - 50, height: 33)
        view.placeholder = "搜索主题"
        view.layer.cornerRadius = 17.5
        view.layer.masksToBounds = true
        view.font = UIFont.systemFont(ofSize: 15)
        view.leftView = UIImageView(image: UIImage(named: "search_Small"))
        view.leftViewMode = .always
        view.clearButtonMode = .always
        view.returnKeyType = .search
        view.enablesReturnKeyAutomatically = true
        view.delegate = self
        view.autoresizingMask = [.flexibleWidth]
        return view
    }()

    private lazy var segmentView: UISegmentedControl = {
        let view = UISegmentedControl(items: ["权重", "时间"])
        view.tintColor = Theme.Color.globalColor
        view.selectedSegmentIndex = 0
        self.containerView.addSubview(view)
        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.borderBottom = Border(color: ThemeStyle.style.value.borderColor)
        self.view.addSubview(view)
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(cellWithClass: TopicSearchResultCell.self)
        tableView.hideEmptyCells()
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        self.view.addSubview(tableView)
        return tableView
    }()
    
    private weak var searchHistoryVC: TopicSearchHistoryViewController?
    
    // MARK: - Propertys
    
    private var searchResults: [SearchResultModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var isSearched = false
    
    private var offset = 0
    private var size = 20
    
    private var query: String?

    private var sortType: SearchSortType = .sumup

    public var autoDisplayKeyboard: Bool = true

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11, *) {
            navigationItem.titleView = searchViewContainerView
        } else {
            navigationItem.titleView = searchTextField
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, action: { [weak self] in
            self?.dismiss()
        })
        navigationItem.rightBarButtonItem?.tintColor = ThemeStyle.style.value.tintColor
        status = .noSearchResult
        
        definesPresentationContext = true
        
        if autoDisplayKeyboard {
            searchTextField.becomeFirstResponder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = false
    }

    // MARK: - Setup

    override func setupSubviews() {

        tableView.addFooterRefresh { [weak self] in
            self?.fecthResult()
        }
        
        let searchHistoryVC = TopicSearchHistoryViewController()
        addChild(searchHistoryVC)
        view.addSubview(searchHistoryVC.view)
        searchHistoryVC.view.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }
        self.searchHistoryVC = searchHistoryVC
        
        searchHistoryVC.didSelectItemHandle = { [weak self] query in
            self?.searchTextField.text = query
            self?.search(query: query)
        }
    }
    
    override func setupConstraints() {
        
        if #available(iOS 11, *) {
            searchViewContainerView.snp.makeConstraints {
                $0.left.right.centerY.equalToSuperview()
                $0.height.equalTo(33)
            }
            
            searchTextField.snp.makeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.left.equalToSuperview().offset(5)
                $0.right.equalToSuperview().inset(8)
            }
        }
        
        tableView.snp.makeConstraints {
            $0.left.bottom.right.equalToSuperview()
            $0.top.equalTo(containerView.snp.bottom)
        }

        containerView.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.height.equalTo(40)
        }

        segmentView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(30)
        }
    }

    override func setupRx() {
        // 因显示搜索历史, 不再实时搜索
        //        searchTextField.rx.text.orEmpty
        //            .debounce(0.5, scheduler: MainScheduler.instance)
        //            .distinctUntilChanged()
        //            .subscribeNext { [weak self] query in
        //                guard let `self` = self else { return }
        //                self.search(query: query)
        //        }.disposed(by: rx.disposeBag)
        
        searchTextField.rx
            .text
            .map { $0?.isEmpty ?? true }
            .subscribeNext({ [weak self] isEmpty in
                guard let `self` = self else { return }
                self.tableView.isHidden = isEmpty
                // 内容为空 并且 搜索结果为空 才显示搜索历史视图
//                if isEmpty && self.searchResults.count.boolValue == false {
                // 只要搜索框没有内容 并且 有搜索历史记录 才显示搜索历史视图
                if isEmpty && (self.searchHistoryVC?.querys.count.boolValue ?? false) {
                    self.searchHistoryVC?.view.isHidden = false
                }
            })
            //            .bind(to: tableView.rx.isHidden )
            .disposed(by: rx.disposeBag)

        segmentView.rx
            .selectedSegmentIndex
            .distinctUntilChanged()
            .filter { [weak self] _ in (self?.searchTextField.text ?? "").trimmed.isNotEmpty }
            .subscribeNext { [weak self] index in
                guard let `self` = self else { return }
                guard let query = self.searchTextField.text else { return }

                self.searchTextField.resignFirstResponder()
                self.search(query: query)
            }.disposed(by: rx.disposeBag)
//
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
                self?.containerView.backgroundColor = theme.navColor
                self?.searchTextField.keyboardAppearance = theme.keyboardAppeareance
                self?.searchTextField.backgroundColor = theme.bgColor
                self?.searchTextField.textColor = theme.titleColor
                self?.containerView.borderBottom = Border(color: theme.borderColor)
                self?.searchTextField.setValue(theme.dateColor, forKeyPath: "_placeholderLabel.textColor")
                self?.segmentView.tintColor = theme.tintColor
            }.disposed(by: rx.disposeBag)
    }

    // MARK: State Handle

    override func hasContent() -> Bool {
        return isSearched ? searchResults.count.boolValue : true
    }

    override func loadData() {

    }

    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {

    }

    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {

    }
}

// MARK: - Actions
extension TopicSearchResultViewController {

    /// 获取搜索结果
    private func fecthResult() {
        guard let `query` = query else { return }
            
        startLoading()

        search(query: query, offset: offset, size: size, sortType: sortType, success: { [weak self] results in
            guard let `self` = self else { return }
            self.searchResults.append(contentsOf: results)
            self.endLoading()
            self.tableView.endFooterRefresh()

            self.offset += self.size
        }) { [weak self] error in
            self?.endLoading()
            self?.tableView.endFooterRefresh()
            HUD.showError(error)
        }
    }

    /// 搜索
    ///
    /// - Parameter query: 关键字
    public func search(query: String?) {
        guard let `query` = query?.trimmed, query.isNotEmpty else { return }
        
        searchTextField.resignFirstResponder()
        
        if query.hasPrefix("https://www.v2ex.com/t/") {
            let topicID = query.lastPathComponent
            let vc = TopicDetailViewController(topicID: topicID)
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        searchHistoryVC?.view.isHidden = true
        tableView.isHidden = false

        offset = 0
        searchResults.removeAll()
        isSearched = true

        self.query = query
        self.sortType = segmentView.selectedSegmentIndex == 0 ? .sumup : .created

        fecthResult()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TopicSearchResultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: TopicSearchResultCell.self)!
        cell.query = query
        cell.topic = searchResults[indexPath.row].topic
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = searchResults[indexPath.row]
        guard let id = item.id else { return }
        let topicDetailVC = TopicDetailViewController(topicID: id)
//        presentingViewController?.navigationController?.pushViewController(topicDetailVC, animated: true)
        navigationController?.pushViewController(topicDetailVC, animated: true)
        
        guard let topidID = id.int,
            let title = item.topic?.title,
            let memberName = item.topic?.member else { return }
        SQLiteDatabase.instance?.addHistory(tid: topidID, title: title, username: memberName, avatarURL: "", replyCount: item.topic?.replies)
    }
}

extension TopicSearchResultViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text, query.isNotEmpty else { return false }
        
        search(query: query.trimmed)
        searchHistoryVC?.appendLocal(query)
        searchHistoryVC?.view.isHidden = true
        return true
    }
}
