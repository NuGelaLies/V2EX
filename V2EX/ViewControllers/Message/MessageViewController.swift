import UIKit
import SwiftMessages

class MessageViewController: DataViewController, AccountService {

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.register(cellWithClass: MessageCell.self)
        view.estimatedRowHeight = 120
        view.rowHeight = UITableViewAutomaticDimension
        view.backgroundColor = .clear
        self.view.addSubview(view)
        view.hideEmptyCells()
        return view
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.activityIndicatorViewStyle = UIDevice.isiPad ? .whiteLarge : .white
        activityIndicator.color = .gray
        return activityIndicator
    }()

    private weak var replyMessageViewController: ReplyMessageViewController?

    // MARK: - Propertys

    private var messages: [MessageModel] = []

    private var page = 1, maxPage = 1


    // MARK: - View Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard AccountModel.isLogin else {
            messages.removeAll()
            tableView.reloadData()
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
            return
        }

        /// 有未读通知, 主动刷新
        guard isLoad, let _ = tabBarItem.badgeValue else { return }

        fetchNotifications()
        activityIndicator.startAnimating()
    }

    //    override func setupSubviews() {
    //        if #available(iOS 11.0, *) {
    //            navigationController?.navigationBar.prefersLargeTitles = true
    //        }
    //    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupRefreshView()
    }

    // MARK: - Setup

    override func setupSubviews() {
        navigationItem.title = "消息"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    }

    private func setupRefreshView() {

        tableView.addHeaderRefresh { [weak self] in
            self?.fetchNotifications()
        }

        tableView.addFooterRefresh { [weak self] in
            self?.fetchMoreNotifications()
        }
    }

    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func setupRx() {

        NotificationCenter.default.rx
            .notification(Notification.Name.V2.LoginSuccessName)
            .subscribeNext { [weak self] _ in
                self?.fetchNotifications()
            }.disposed(by: rx.disposeBag)

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.separatorColor = theme.borderColor
            }.disposed(by: rx.disposeBag)
    }

    // MARK: States Handle

    override func loadData() {
        fetchNotifications()
    }

    override func errorView(_ errorView: ErrorView, didTapActionButton _: UIButton) {
        if status == .noAuth {
            presentLoginVC()
            return
        }
        fetchNotifications()
    }

    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
        fetchNotifications()
    }

    override func hasContent() -> Bool {
        return messages.count.boolValue
    }

}

// MARK: - Actions
extension MessageViewController {

    /// 新消息动画
    ///
    /// - Parameter badgeValue: badge
    private func notificationAnimation(_ badgeValue: String?) {
        guard let count = badgeValue?.int,
            count.boolValue,
            tableView.numberOfRows(inSection: 0) >= count else {
                return
        }
        tabBarItem.badgeValue = nil
        //        HUD.showText("\(count) 条新消息")
        activityIndicator.stopAnimating()
        var indexPaths: [IndexPath] = []
        for i in 0..<count {
            indexPaths.append(IndexPath(row: i, section: 0))
        }

        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveLinear,  animations: {
            indexPaths.forEach { self.tableView.cellForRow(at: $0)?.backgroundColor = UIColor.hex(0xB3DBE8).withAlphaComponent(0.3) }
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.8, options: .curveLinear,  animations: {
                indexPaths.forEach { self.tableView.cellForRow(at: $0)?.backgroundColor = ThemeStyle.style.value.cellBackgroundColor }
            })
        })
    }

    /// 获取通知
    func fetchNotifications() {
        guard AccountModel.isLogin else {
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
            return
        }

        page = 1

        startLoading()

        notifications(page: page, success: { [weak self] messages, maxPage in
            guard let `self` = self else { return }
            self.messages = messages
            self.maxPage = maxPage
            self.endLoading()
            self.tableView.reloadData()
            self.tableView.endHeaderRefresh()
            if self.status == .noAuth {
                self.status = .empty
            }
            // 目前只有在badge不为空时才有动画提示
            // 下拉刷新时, 如果有新数据, 可以根据最后一条的时间来对比
            self.notificationAnimation(self.tabBarItem.badgeValue)
        }) { [weak self] error in
            guard let `self` = self else { return }
            self.errorMessage = error
            self.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            self.tableView.endHeaderRefresh()
            self.activityIndicator.stopAnimating()
            if !self.messages.count.boolValue {
                self.status = .empty
            }
        }
    }

    /// 获取更多通知
    private func fetchMoreNotifications() {
        if self.page >= maxPage {
            tableView.endRefresh(showNoMore: true)
            return
        }

        page += 1

        startLoading()

        notifications(page: page, success: { [weak self] messages, maxPage in
            guard let `self` = self else { return }
            self.messages.append(contentsOf: messages)
            self.tableView.reloadData()
            self.tableView.endRefresh(showNoMore: maxPage < self.page)
        }) { [weak self] error in
            self?.tableView.endFooterRefresh()
            self?.page -= 1
        }
    }

    /// 删除消息
    ///
    /// - Parameter message: 模型
    private func deleteMessages(_ message: MessageModel) {
        guard let id = message.id,
            let once = message.once else {
                HUD.showError("操作失败，无法获取消息 ID 或 once")
                return
        }
        deleteNotification(notifacationID: id, once: once, success: {

        }) { error in
            HUD.showError(error)
        }
    }

    /// 回复消息
    ///
    /// - Parameter message: 消息内容
    private func replyMessage(_ message: MessageModel) {
        if replyMessageViewController == nil {
            let replyMessageVC = ReplyMessageViewController()
            replyMessageVC.view.alpha = 0
            self.replyMessageViewController = replyMessageVC
            addChildViewController(replyMessageVC)
            self.view.addSubview(replyMessageVC.view)
        }

        replyMessageViewController?.message = message
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MessageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: MessageCell.self)!
        cell.message = messages[indexPath.row]
        cell.avatarTapHandle = { [weak self] cell in
            guard let `self` = self,
                let row = tableView.indexPath(for: cell)?.row,
                let username = self.messages[row].member?.username else {
                    return
            }

            let memberVC = MemberPageViewController(memberName: username)
            self.navigationController?.pushViewController(memberVC, animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let topicID = messages[indexPath.row].topic.topicID else { return }
        let topicDetailVC = TopicDetailViewController(topicID: topicID)
        topicDetailVC.anchor = messages[indexPath.row].topic.anchor
        navigationController?.pushViewController(topicDetailVC, animated: true)
    }


    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let replyAction = UITableViewRowAction(
            style: .default,
            title: "回复") { _, indexPath in
                let message = self.messages[indexPath.row]
                self.replyMessage(message)
        }
        replyAction.backgroundColor = UIColor.hex(0x0058E5)

        let deleteAction = UITableViewRowAction(
            style: .destructive,
            title: "删除") { _, indexPath in
                let message = self.messages.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self.deleteMessages(message)
        }
        return [deleteAction, replyAction]
    }
}

