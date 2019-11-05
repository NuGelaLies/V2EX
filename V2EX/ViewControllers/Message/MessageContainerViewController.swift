import UIKit
import SegementSlide

class MessageContainerViewController: DataViewController {
    
    private var config: SegementSlideSwitcherConfig = SegementSlideSwitcherConfig()
    
    private lazy var segementSlideSwitcherView: SegementSlideSwitcherView = {
        let view = SegementSlideSwitcherView()
        view.delegate = self
        self.config.horizontalMargin = 0
        view.config = self.config
        return view
    }()
    
    private var pagesController: PagesController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AccountModel.isLogin.not {
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
        }
    
        let replyViewController = MyReplyViewController(username: AccountModel.current?.username ?? "")
        
        let controllers = [MessageViewController(), replyViewController]
        
        navigationItem.titleView = segementSlideSwitcherView
        
        segementSlideSwitcherView.translatesAutoresizingMaskIntoConstraints = false
        segementSlideSwitcherView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        segementSlideSwitcherView.widthAnchor.constraint(equalToConstant: 156).isActive = true
//        segementSlideSwitcherView.centerXAnchor.constraint(equalTo: navigationController!.navigationBar.centerXAnchor).isActive = true
        
        setupSwitcherTheme()
        
        segementSlideSwitcherView.selectSwitcher(at: 0, animated: true)
        segementSlideSwitcherView.reloadData()
        
        let pagesController = PagesController(controllers)
        pagesController.pagesDelegate = self
        addChild(pagesController)
        view.addSubview(pagesController.view)
        pagesController.didMove(toParent: self)
        self.pagesController = pagesController
        
        for view in pagesController.view.subviews {
            if let subView = view as? UIScrollView {
                subView.isScrollEnabled = false
            }
        }
        
        pagesController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        NotificationCenter.default.rx.notification(Notification.Name.V2.LoginSuccessName)
            .subscribe(onNext: { [weak self] noti in
                replyViewController.username = AccountModel.current?.username ?? ""
                self?.endLoading()
            }).disposed(by: rx.disposeBag)
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.setupSwitcherTheme()
            }.disposed(by: rx.disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AccountModel.isLogin.not {
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
        }
    }
    
    override func loadData() {}
    
    override func hasContent() -> Bool {
        segementSlideSwitcherView.isUserInteractionEnabled = AccountModel.isLogin
        pagesController?.view.isHidden = segementSlideSwitcherView.isUserInteractionEnabled.not
        return AccountModel.isLogin
    }
    
    
    override func errorView(_ errorView: ErrorView, didTapActionButton _: UIButton) {
        guard status == .noAuth else { return }
        presentLoginVC()
    }
    
    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {}
}

extension MessageContainerViewController: SegementSlideSwitcherViewDelegate {
    
    private func setupSwitcherTheme() {
        config.switcherBackgroundColor = ThemeStyle.style.value.navColor
        config.selectedTitleColor = ThemeStyle.style.value.blackColor
        config.indicatorColor = ThemeStyle.style.value.blackColor
        segementSlideSwitcherView.reloadTheme()
    }
    
    func segementSwitcherView(_ segementSlideSwitcherView: SegementSlideSwitcherView, didSelectAtIndex index: Int, animated: Bool) {
        pagesController?.goTo(index)
    }
    
    func segementSwitcherView(_ segementSlideSwitcherView: SegementSlideSwitcherView, showBadgeAtIndex index: Int) -> BadgeType {
        return .none
    }
    
    var titlesInSegementSlideSwitcherView: [String] {
        return ["我的消息", "我的回复"]
    }
}

extension MessageContainerViewController: PagesControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, setViewController viewController: UIViewController, atPage page: Int) {
        segementSlideSwitcherView.selectSwitcher(at: page, animated: true)
    }
}
