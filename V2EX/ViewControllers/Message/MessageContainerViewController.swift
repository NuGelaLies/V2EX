import UIKit

class MessageContainerViewController: DataViewController {

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = true
        view.delegate = self
        view.isScrollEnabled = false
        return view
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let view = UISegmentedControl(items: ["我的消息", "我的回复"])
        view.addTarget(self, action: #selector(segmentedControlValueChanaeAction), for: .valueChanged)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AccountModel.isLogin.not {
            endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            status = .noAuth
        }
    
        let replyViewController = MyReplyViewController(username: AccountModel.current?.username ?? "")
        
        view.addSubview(scrollView)
        let controllers = [MessageViewController(), replyViewController]
        controllers.forEach { addChild($0) }
        scrollViewDidEndScrollingAnimation(scrollView)
        
        scrollView.contentSize = CGSize(width: view.width * controllers.count.f, height: scrollView.bounds.height)
        
        navigationItem.titleView = segmentedControl
        
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 适配屏幕旋转
        NotificationCenter.default.rx
            .notification(UIDevice.orientationDidChangeNotification)
            .subscribe(onNext: { [weak self] noti in
                self?.rotationAdaptation()
            }).disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name.V2.LoginSuccessName)
            .subscribe(onNext: { [weak self] noti in
                replyViewController.username = AccountModel.current?.username ?? ""
                self?.endLoading()
            }).disposed(by: rx.disposeBag)
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
        scrollView.isHidden = segmentedControl.isEnabled.not
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
    
    private func rotationAdaptation() {
        guard children.count.boolValue else { return }
        
        for (index, showVC) in children.enumerated() {
            guard showVC.isViewLoaded else { continue }
            showVC.view.x = index.f * scrollView.width
        }
        
        var offset = scrollView.contentOffset
        offset.x = scrollView.width * segmentedControl.selectedSegmentIndex.f
        scrollView.setContentOffset(offset, animated: false)
    }
    
    @objc private func segmentedControlValueChanaeAction() {
        
        let index = segmentedControl.selectedSegmentIndex
        var offset = scrollView.contentOffset
        let offsetX = scrollView.bounds.width * CGFloat(index)
        offset.x = offsetX
        self.scrollView.setContentOffset(offset, animated: true)
        
        print(offsetX)
    }
}

// MARK: - UIScrollViewDelegate
extension MessageContainerViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let index = Int(offsetX / view.bounds.width)
        
        segmentedControl.selectedSegmentIndex = index
        
        let willShowVC = children[index]
        if willShowVC.isViewLoaded { return }
        willShowVC.view.frame = scrollView.bounds
        willShowVC.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        scrollView.addSubview(willShowVC.view)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(scrollView)
    }
}
