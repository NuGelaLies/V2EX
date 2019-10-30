import UIKit
import SegementSlide

class BaseTopicsViewController: DataViewController, TopicService, NodeService, SegementSlideContentScrollViewDelegate {

    private struct Misc {
        static let allHrefName = "/?tab=all"
    }
    
    /// MARK: - UI
    
    internal lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.register(cellWithClass: TopicCell.self)
        view.keyboardDismissMode = .onDrag
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 80
        view.hideEmptyCells()
        self.view.addSubview(view)
        return view
    }()
    
    /// MARK: - Propertys

    var topics: [TopicModel] = []

    public var href: String
    
    public var node: NodeModel?

    internal var page = 1, maxPage = 1

    /// MARK: - View Life Cycle
    
    init(href: String) {
        self.href = href
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(node: NodeModel) {
        self.init(href: node.href.contains("/?tab=") ? node.href : node.path)
        self.node = node
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    
    override func setupSubviews() {
        if traitCollection.forceTouchCapability != .unavailable {
            registerForPreviewing(with: self, sourceView: tableView)
        }

        setupRefresh()
    }
    
    @objc var scrollView: UIScrollView {
        return tableView
    }
    
    func setupRefresh() {
        setupHeaderRefresh()
        setupFooterRefresh()
    }
    
    func setupHeaderRefresh() {
        tableView.addHeaderRefresh { [weak self] in
            self?.fetchTopic()
        }
    }
    
    func setupFooterRefresh() {
        tableView.addFooterRefresh { [weak self] in
            self?.fetchMoreTopic()
        }
    }

    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(0.5).priority(.high)
        }
    }

    override func setupTheme() {
        super.setupTheme()

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
                self?.setupHeaderRefresh()
            }.disposed(by: rx.disposeBag)
    }
    
    // MARK: State Handle

    override func loadData() {
        fetchData()
    }

    override func hasContent() -> Bool {
        return topics.count.boolValue
    }

    func fetchData() {
        startLoading()
        fetchTopic()
    }
    
    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {
        fetchData()
    }

    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
        fetchData()
    }

    func fetchTopic() {

        topics(href: href, success: { [weak self] topic, maxPage in
            if self?.href != Misc.allHrefName {
                self?.maxPage = maxPage
            }
//            self?.topics = SQLiteDatabase.instance?.setReadHistory(topics: topic) ?? topic
            self?.topics = topic
            self?.endLoading()
            self?.tableView.endHeaderRefresh()
            self?.tableView.reloadData()
            }, failure: { [weak self] error in
                self?.tableView.endHeaderRefresh()
                self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
                self?.errorMessage = error
        })
    }

    private func fetchMoreTopic() {
        let isAllHref = href.hasPrefix(Misc.allHrefName)
        let nodeDetailRefreshable = href.contains("/?tab=").not && node != nil
        // 不是全部节点 或者 不包含 "/?tab=" 支持加载更多
        let isAllowRefresh = isAllHref || nodeDetailRefreshable
        if isAllowRefresh == false {
            tableView.endFooterRefresh(showNoMore: !isAllowRefresh)
        }

        guard isAllowRefresh else { return }
        
        if isAllHref {
            fetchRecentTopic()
            return
        }
        
        fetchMoreNodeTopic()
    }

    private func fetchRecentTopic() {

        recentTopics(page: page, success: { [weak self] topics, maxPage in
            guard let `self` = self else { return }
            self.page += 1
            self.maxPage = maxPage
            
            // 数据去重
            let ts = topics.filter({ rhs -> Bool in
                !self.topics.contains(where: { lhs -> Bool in
                    return lhs.title == rhs.title
                })
            })
            self.topics.append(contentsOf: ts)
            self.tableView.endFooterRefresh(showNoMore: self.page >= maxPage)
            self.tableView.reloadData()
        }) { [weak self] error in
            self?.tableView.endFooterRefresh()
            HUD.showError(error)
        }
    }
    
    public func fetchMoreNodeTopic() {
        guard let node = node else { return }
        
        if page >= maxPage {
            self.tableView.endRefresh(showNoMore: true)
            return
        }
        page += 1
        nodeDetail(
            page: page,
            node: node,
            success: { [weak self] _, topics, maxPage in
                guard let `self` = self else { return }
                
                self.maxPage = maxPage
                // 数据去重
                let ts = topics.filter({ rhs -> Bool in
                    !self.topics.contains(where: { lhs -> Bool in
                        return lhs.title == rhs.title
                    })
                })
                self.topics.append(contentsOf: ts)
                self.tableView.reloadData()
                self.tableView.endRefresh(showNoMore: self.page >= maxPage)
        }) { [weak self] error in
            self?.page -= 1
            self?.tableView.endFooterRefresh()
            self?.errorMessage = error
            self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
        }
    }

    /// MARK: - Actions
    
    public func tapHandle(_ type: TapType) {
        switch type {
        case .member(let member):
            let memberPageVC = MemberPageViewController(memberName: member.username)
            navigationController?.pushViewController(memberPageVC, animated: true)
        case .node(let node):
            let nodeDetailVC = NodeDetailViewController(node: node)
            navigationController?.pushViewController(nodeDetailVC, animated: true)
        default:
            break
        }
    }
    
    private func makeAsRead(indexPath: IndexPath) {
//        let topic = topics[indexPath.row]
//        guard let topicID = topic.topicID?.int else { return }
        
        topics[indexPath.row].readStatus = .read
        self.tableView.reloadRows(at: [indexPath], with: .none)
//        guard let member = topic.member else { return }
//        GCD.runOnBackgroundThread {
//            SQLiteDatabase.instance?.addHistory(tid: topicID, title: topic.title, username: member.username, avatarURL: member.avatarSrc, replyCount: topic.replyCount.int)
//        }
    }
}

extension BaseTopicsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topics.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: TopicCell.self)!
        cell.topic = topics[indexPath.row]
        cell.tapHandle = { [weak self] type in
            self?.tapHandle(type)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
        
//        let webViewVC = SweetWebViewController()
//        webViewVC.url = URL(string: API.currency(href: "").defaultURLString)
//        webViewVC.webViewdidFinish = { [weak self] webView, url in
//
//            webView.evaluateJavaScript("document.getElementsByTagName('html')[0].innerHTML") { blocked, error in
//                log.info(blocked, error)
//            }
//        }
//        self.navigationController?.pushViewController(webViewVC, animated: true)
//
//        return
        
        let topic = topics[indexPath.row]
        guard let topicId = topic.topicID else {
            HUD.showError("操作失败，无法解析主题 ID")
            return
        }
        let topicDetailVC = TopicDetailViewController(topicID: topicId)
        topicDetailVC.replyCount = topic.replyCount.int
        self.navigationController?.pushViewController(topicDetailVC, animated: true)
        makeAsRead(indexPath: indexPath)
    }
}

extension BaseTopicsViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        (viewControllerToCommit as? TopicDetailViewController)?.showInputView = true
        show(viewControllerToCommit, sender: self)
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        guard let topicID = topics[indexPath.row].topicID else { return nil }
        makeAsRead(indexPath: indexPath)
        
        let viewController = TopicDetailViewController(topicID: topicID)
        viewController.showInputView = false
        previewingContext.sourceRect = cell.frame
        return viewController
    }
}
