import UIKit
import SnapKit
import RxSwift
import RxCocoa

class HomeViewController: BaseViewController, AccountService, TopicService, NodeService {

    // MARK: - UI

    private var segmentView: SegmentView?

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        //        scrollView.frame = self.view.bounds
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        return scrollView
    }()
    
    // MARK: - Propertys
    
    private var nodes: [NodeModel] = []
    
    /// 上次剪切板内容
    private var lastCopyLink: String?

    // MARK: - View Life Cycle...

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSegmentView()
        fetchData()
        switchTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        rotationAdaptation()
    }
    
    
    // MARK: - Setup

    override func setupSubviews() {
        super.setupSubviews()

        navigationItem.title = "V2EX"

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "search"), style: .plain) { [weak self] in
            let resultVC = TopicSearchResultViewController()
            let nav = NavigationViewController(rootViewController: resultVC)
            nav.modalTransitionStyle = .crossDissolve
            self?.present(nav, animated: true, completion: nil)
        }
    }

    private func setupSegmentView() {
        nodes = homeNodes()

        let segmentV = SegmentView(frame: CGRect(x: 0, y: 0, width: view.width, height: 40),
                                   titles: nodes.compactMap { $0.title })
        segmentV.backgroundColor = .white
        segmentView = segmentV
        view.addSubview(segmentV)

        segmentV.valueChange = { [weak self] index in
            guard let `self` = self else { return }
            var offset = self.scrollView.contentOffset
            let offsetX = self.scrollView.width * index.f
            offset.x = offsetX
            self.scrollView.setContentOffset(offset, animated: true)
        }

        segmentV.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.height.equalTo(40)
        }

        scrollView.width = view.width
        scrollView.snp.makeConstraints {
            $0.top.equalTo(segmentV.snp.bottom)
            $0.left.right.equalToSuperview()

            if #available(iOS 11.0, *) {
                $0.bottom.equalTo(view.safeAreaInsets)
            } else {
                $0.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
        }

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                segmentV.backgroundColor = theme.navColor
                segmentV.style = theme.segmentViewStyle
                AppWindow.shared.window.backgroundColor = theme.whiteColor
                self?.navigationItem.rightBarButtonItem?.tintColor = theme.tintColor
                self?.setNeedsStatusBarAppearanceUpdate()
            }.disposed(by: rx.disposeBag)
    }

    override func setupRx() {
        NotificationCenter.default.rx
            .notification(Notification.Name.V2.TwoStepVerificationName)
            .subscribeNext { [weak self] _ in
                let twoStepVer = TwoStepVerificationViewController()
                let nav = NavigationViewController(rootViewController: twoStepVer)
                self?.present(nav, animated: true, completion: nil)
            }.disposed(by: rx.disposeBag)

        NotificationCenter.default.rx
            .notification(Notification.Name.V2.DailyRewardMissionName)
            .subscribeNext { [weak self] _ in
                self?.dailyRewardMission()
            }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.V2.LoginSuccessName)
            .subscribeNext { [weak self] _ in
                HUD.showSuccess("登录成功")
                self?.dailyRewardMission()
                self?.loginHandle()
            }.disposed(by: rx.disposeBag)

        NotificationCenter.default.rx
            .notification(Notification.Name.V2.DidSelectedHomeTabbarItemName)
            .subscribeNext { [weak self] _ in
                guard let `self` = self, let `segmentView` = self.segmentView else { return }
                let willShowVC = self.children[segmentView.selectIndex]
                if let tableView = willShowVC.view.subviews.first as? UITableView, tableView.numberOfRows(inSection: 0) > 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    if tableView.indexPathsForVisibleRows?.first == indexPath {
                        tableView.switchRefreshHeader(to: .refreshing)
                    } else {
                        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    }
                    
                }
            }.disposed(by: rx.disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribeNext { [weak self] _ in
                guard Preference.shared.recognizeClipboardLink,
                    let content = UIPasteboard.general.string?.trimmed,
                    let url = try? content.asURL(),
                    let host = url.host,
                    host.lowercased().contains("v2ex.com"),
                    self?.lastCopyLink != content
                    else { return }
                
                self?.lastCopyLink = UIPasteboard.general.string
                
                let alertVC = UIAlertController(title: "提示", message: "检测到剪切板中 V2EX 链接，是否打开？\n\(content)", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                alertVC.addAction(UIAlertAction(title: "打开", style: .default, handler: { alert in
                    clickCommentLinkHandle(urlString: content)
                }))
                alertVC.addAction(UIAlertAction(title: "关闭该功能", style: .destructive, handler: { alert in
                    Preference.shared.recognizeClipboardLink = false
                }))
                GCD.delay(0.5, block: {
                    self?.currentViewController().present(alertVC, animated: true, completion: nil)
                })
            }.disposed(by: rx.disposeBag)

//        NotificationCenter.default.rx
//            .notification(Notification.Name.V2.HomeTabSortFinishName)
//            .subscribeNext { [weak self] notification in
//                guard let `self` = self, let nodes = notification.object as? [NodeModel] else { return }
//                self.nodes = nodes
//                self.segmentView?.titles = nodes.map { $0.title }
//                //            let d = childViewControllers.flatMap { $0 as? BaseTopicsViewController }.map { $0.href = nodes}
//
//                for (offset, node) in nodes.enumerated() {
//                    let topicVC = self.childViewControllers[offset] as? BaseTopicsViewController
//                    topicVC?.href = node.href
//                }
//            }.disposed(by: rx.disposeBag)

        // 适配屏幕旋转
        NotificationCenter.default.rx
            .notification(UIDevice.orientationDidChangeNotification)
            .subscribe(onNext: { [weak self] noti in
                self?.rotationAdaptation()
            }).disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.V2.ReceiveRemoteNewMessageName)
            .subscribeNext { [weak self] notification in
                guard let userInfo = notification.object as? [String: Any],
                    let link = userInfo["link"] as? String else { return }
                self?.tabBarController?.selectedIndex = 2
                if let action = userInfo["action"] as? String,
                    action == "msg" {
                    return
                }
                let topic = TopicModel(member: nil, node: nil, title: "", href: link)
                guard let topicID = topic.topicID else { return }
                let topicDetailVC = TopicDetailViewController(topicID: topicID)
                topicDetailVC.anchor = topic.anchor
                self?.navigationController?.pushViewController(topicDetailVC, animated: true)
            }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIScreen.brightnessDidChangeNotification)
            .throttle(0.2, scheduler: MainScheduler.instance)
            .subscribeNext { [weak self] _ in
                self?.switchTheme()
        }.disposed(by: rx.disposeBag)
    }

}

// MARK: - Actions
extension HomeViewController {

    private func switchTheme() {
        guard Preference.shared.autoSwitchTheme else { return }
        
        if UIScreen.main.brightness >= 0.25 {
            Preference.shared.theme = .day
        } else if ThemeStyle.style.value == .day {
            Preference.shared.theme = Preference.shared.nightTheme
        }
    }
    
    /// 获取所有节点
    private func fetchData() {

        scrollView.contentSize = CGSize(width: nodes.count.f * scrollView.width, height: scrollView.contentSize.height)
        for node in nodes {
            let topicVC = BaseTopicsViewController(node: node)
            addChild(topicVC)
        }

        scrollViewDidEndScrollingAnimation(scrollView)
    }

    /// 每日奖励
    private func dailyRewardMission() {
        guard AccountModel.isLogin else { return }

        dailyReward(success: { days in
            HUD.showSuccess(days)
        }) { error in
            HUD.showTest(error)
            log.error(error)
        }
    }

    private func loginHandle() {
        guard AccountModel.isLogin, let account = AccountModel.current else { return }

        userStatus(username: account.username, success: { isOpen in
            guard isOpen else { return }
//            JPUSHService.setAlias(account.username, completion: { (resCode, alia, seq) in
//                log.info(resCode, alia ?? "None", seq)
//            }, seq: 2)
        }) { error in
            log.info(error)
            HUD.showTest(error)
        }
    }

    private func rotationAdaptation() {
        guard children.count.boolValue else { return }

        for (index, showVC) in children.enumerated() {
            guard showVC.isViewLoaded else { continue }
            showVC.view.x = index.f * scrollView.width
        }

        guard let selectIndex = segmentView?.selectIndex else { return }
        var offset = scrollView.contentOffset
        offset.x = scrollView.width * selectIndex.f
        scrollView.setContentOffset(offset, animated: false)
    }
}

// MARK: - UIScrollViewDelegate
extension HomeViewController: UIScrollViewDelegate {

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let index = Int(offsetX / view.width)

        segmentView?.setSelectIndex(index: index)

        let willShowVC = children[index]
        if willShowVC.isViewLoaded { return }
        willShowVC.view.frame = scrollView.bounds
        scrollView.addSubview(willShowVC.view)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(scrollView)
    }
}

