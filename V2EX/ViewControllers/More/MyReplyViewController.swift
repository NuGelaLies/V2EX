import UIKit
import Aquaman

class MyReplyViewController: DataViewController, MemberService, AquamanChildViewController{
    func aquamanChildScrollView() -> UIScrollView {
        return tableView
    }
    

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.estimatedRowHeight = 120
        view.rowHeight = UITableView.automaticDimension
        view.backgroundColor = .clear
        view.hideEmptyCells()
        view.register(cellWithClass: ReplyCell.self)
        self.view.addSubview(view)
        return view
    }()

    // MARK: - Propertys

    public var scrollViewDidScroll: ((UIScrollView) -> Void)?
    
    public var username: String

    private var page = 1, maxPage = 1

    private var replys: [MessageModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - View Life Cycle

    init(username: String) {
        self.username = username
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
        }.disposed(by: rx.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard AccountModel.isLogin else {
            replys.removeAll()
            tableView.reloadData()
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
            return
        }
    }
    
    // MARK: - Setup

    override func setupSubviews() {
        setupRefresh()
    }

    private func setupRefresh() {
        tableView.addFooterRefresh { [weak self] in
            self?.fetchMoreReplys()
        }
    }

    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: State Handle

    override func loadData() {
        fetchReplys()
    }

    override func hasContent() -> Bool {
        return replys.count.boolValue
    }

    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {
        fetchReplys()
    }

    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
        fetchReplys()
    }
}

// MARK: - Actions
extension MyReplyViewController {

    /// 获取回复
    private func fetchReplys() {
        page = 1
        startLoading()
        memberReplys(username: username, page: page, success: { [weak self] replys, maxPage in
            self?.replys = replys
            self?.maxPage = maxPage
            self?.endLoading()
        }) { [weak self] error in
            self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            self?.errorMessage = error
        }
    }

    /// 获取更多回复
    private func fetchMoreReplys() {
        if self.page >= maxPage {
            tableView.endRefresh(showNoMore: true)
            return
        }
        page += 1

        memberReplys(username: username, page: page, success: { [weak self] replys, maxPage in
            guard let `self` = self else { return }
            self.replys.append(contentsOf: replys)
            self.tableView.reloadData()
            self.tableView.endRefresh(showNoMore: maxPage < self.page)
        }) { [weak self] error in
            self?.tableView.endFooterRefresh()
            self?.page -= 1
        }
    }
}

extension MyReplyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return replys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ReplyCell.self)!
        cell.message = replys[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topic = replys[indexPath.row].topic

        guard let topicId = topic.topicID else {
            HUD.showError("操作失败，无法解析主题 ID")
            return
        }
        
        let topicDetailVC = TopicDetailViewController(topicID: topicId)
        self.navigationController?.pushViewController(topicDetailVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDidScroll?(scrollView)

    }
}
