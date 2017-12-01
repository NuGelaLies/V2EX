import UIKit
import RxSwift
import RxCocoa

class TopicSearchResultViewController: DataViewController, TopicService {

    // MARK: - UI

    private lazy var searchTextField: UITextField = {
        let view = UITextField()
//        view.frame = CGRect(x: 0, y: 0, width: Constants.Metric.screenWidth - 30, height: 35)
        view.placeholder = "搜索主题"
//        view.backgroundColor = UIColor.groupTableViewBackground
        view.layer.cornerRadius = 17.5
        view.layer.masksToBounds = true
        view.font = UIFont.systemFont(ofSize: 15)
        view.leftView = UIImageView(image: #imageLiteral(resourceName: "searchSmall"))
        view.leftViewMode = .always
        view.clearButtonMode = .whileEditing
        view.returnKeyType = .search
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
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(cellWithClass: TopicSearchResultCell.self)
        tableView.hideEmptyCells()
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0)
        self.view.addSubview(tableView)
        return tableView
    }()

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


    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = searchTextField
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, action: { [weak self] in
            self?.dismiss()
        })
        status = .noSearchResult
        
        definesPresentationContext = true
        searchTextField.becomeFirstResponder()

//        searchBar.becomeFirstResponder()
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
    }
    
    override func setupConstraints() {

        searchTextField.snp.makeConstraints {
            $0.left.right.centerY.equalToSuperview()
            $0.height.equalTo(35)
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

        searchTextField.rx.text.orEmpty
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribeNext { [weak self] query in
                guard let `self` = self else { return }
                self.search(query: query)
        }.disposed(by: rx.disposeBag)

        segmentView.rx
            .selectedSegmentIndex
            .distinctUntilChanged()
            .filter { _ in (self.searchTextField.text ?? "").trimmed.isNotEmpty }
            .subscribeNext { [weak self] index in
                guard let `self` = self else { return }
                guard let query = self.searchTextField.text else { return }

                self.searchTextField.resignFirstResponder()
                self.search(query: query)
            }.disposed(by: rx.disposeBag)

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
                self?.containerView.backgroundColor = theme.whiteColor
                self?.searchTextField.keyboardAppearance = theme == .day ? .default : .dark
                self?.searchTextField.backgroundColor = theme.bgColor
                self?.searchTextField.textColor = theme.titleColor
                self?.containerView.borderBottom = Border(color: theme.borderColor)
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
            HUD.showText(error)
        }
    }

    /// 搜索
    ///
    /// - Parameter query: 关键字
    public func search(query: String?) {
        guard let `query` = query?.trimmed, query.isNotEmpty else { return }

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
        guard let id = searchResults[indexPath.row].id else { return }
        let topicDetailVC = TopicDetailViewController(topicID: id)
//        presentingViewController?.navigationController?.pushViewController(topicDetailVC, animated: true)
        navigationController?.pushViewController(topicDetailVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension TopicSearchResultViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
