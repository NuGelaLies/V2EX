import UIKit

class NodeDetailViewController: BaseTopicsViewController, AccountService {

    // MARK: - UI

    private lazy var favoriteTopicItem: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "favoriteNav"), style: .plain)
    }()

    // MARK: - Propertys


    override var node: NodeModel? {
        didSet {
            title = node?.title
            favoriteTopicItem.image = (node?.isFavorite ?? false) ? #imageLiteral(resourceName: "unfavoriteNav") : #imageLiteral(resourceName: "favoriteNav")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRightBarButtonItems()
    }

    // MARK: - Setup
    
    override func setupRefresh() {
    
        tableView.addHeaderRefresh { [weak self] in
            self?.fetchNodeDetail()
        }
        
        tableView.addFooterRefresh { [weak self] in
            self?.fetchMoreNodeTopic()
        }
    }
    
    private func setupRightBarButtonItems() {
        guard AccountModel.isLogin else { return }
        
        let newTopicItem = UIBarButtonItem(image: #imageLiteral(resourceName: "edit"), style: .plain, action: { [weak self] in
            let createTopicVC = CreateTopicViewController()
            createTopicVC.node = self?.node
            self?.navigationController?.pushViewController(createTopicVC, animated: true)
        })
        
        navigationItem.rightBarButtonItems = [newTopicItem, favoriteTopicItem]
    }

    override func setupRx() {
        
        favoriteTopicItem.rx
            .tap
            .subscribeNext { [weak self] in
                self?.favoriteHandle()
            }.disposed(by: rx.disposeBag)

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
            }.disposed(by: rx.disposeBag)
    }
    
    // MARK: State Handle

    override func loadData() {
        fetchNodeDetail()
    }

    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
        loadData()
    }

    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {
        loadData()
    }
}

// MARK: - Actions
extension NodeDetailViewController {

    /// 获取节点详情
    func fetchNodeDetail() {
        guard let node = node else { return }
        
        page = 1
        startLoading()

        nodeDetail(
            page: page,
            node: node,
            success: { [weak self] node, topics, maxPage in
                guard let `self` = self else { return }
                self.maxPage = maxPage
                self.node = node
                self.topics = topics
                self.tableView.endFooterRefresh()
                self.endLoading()
                self.tableView.endRefresh(showNoMore: self.page >= maxPage)
        }) { [weak self] error in
            self?.tableView.endFooterRefresh()
            self?.errorMessage = error
            self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
        }
    }

    /// 收藏主题
    private func favoriteHandle() {
        guard let node = node,
            let href = node.favoriteOrUnfavoriteHref else {
            HUD.showError("收藏失败，请重试")
            return
        }

        favorite(href: href, success: { [weak self] in
            guard let `self` = self else { return }
            self.node?.isFavorite = !node.isFavorite!
            HUD.showSuccess("已成功\(self.node!.isFavorite! ? "收藏" : "取消收藏") \(node.title)")
            self.favoriteTopicItem.image = self.node!.isFavorite! ? #imageLiteral(resourceName: "unfavoriteNav") : #imageLiteral(resourceName: "favoriteNav")
        }) { error in
            HUD.showError(error)
        }
    }
}
