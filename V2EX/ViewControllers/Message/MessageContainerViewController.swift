import UIKit

class MessageContainerViewController: DataViewController {

    private lazy var segmentedControl: UISegmentedControl = {
        let view = UISegmentedControl(items: ["我的消息", "我的回复"])
        view.selectedSegmentIndex = 0
        view.addTarget(self, action: #selector(segmentedControlValueChanaeAction), for: .valueChanged)
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
        
        navigationItem.titleView = segmentedControl
        
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
                if #available(iOS 13.0, *) {
                    self?.segmentedControl.selectedSegmentTintColor = theme.tintColor
                } else {
                    self?.segmentedControl.tintColor = theme.tintColor
                }
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
        segmentedControl.isEnabled = AccountModel.isLogin
        pagesController?.view.isHidden = segmentedControl.isEnabled.not
        return AccountModel.isLogin
    }
    
    
    override func errorView(_ errorView: ErrorView, didTapActionButton _: UIButton) {
        guard status == .noAuth else { return }
        presentLoginVC()
    }
    
    override func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
    }
}

extension MessageContainerViewController {
    @objc private func segmentedControlValueChanaeAction() {
        
        let index = segmentedControl.selectedSegmentIndex
        pagesController?.goTo(index)
    }
}

extension MessageContainerViewController: PagesControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, setViewController viewController: UIViewController, atPage page: Int) {
        segmentedControl.selectedSegmentIndex = page
    }
}
