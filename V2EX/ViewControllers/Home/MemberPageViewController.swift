import UIKit
import SnapKit
import Aquaman

class MemberPageViewController: AquamanPageViewController, MemberService, AccountService {

    // MARK: - UI

    private lazy var headerView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = 0.6
        return blurView
    }()

    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.setCornerRadius = 40
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.boldSystemFont(ofSize: 20)
        view.textColor = .white
        return view
    }()
    
    private lazy var joinTimeLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()
    
    private lazy var followBtn: LoadingButton = {
        let view = LoadingButton()
        view.setTitle("关注", for: .normal)
        view.setTitle("已关注", for: .selected)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setCornerRadius = 17.5
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.isHidden = true
        return view
    }()
    
    private lazy var blockBtn: LoadingButton = {
        let view = LoadingButton()
        view.setTitle("屏蔽", for: .normal)
        view.setTitle("已屏蔽", for: .selected)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setCornerRadius = 17.5
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.isHidden = true
        return view
    }()
    
    private lazy var segmentViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeStyle.style.value.cellBackgroundColor
        return view
    }()

    private lazy var segmentView: UISegmentedControl = {
        let view = UISegmentedControl(items: [
            "发布的主题",
            "最近的回复"
            ])
//        view.tintColor = ThemeStyle.style.value.tintColor
        view.selectedSegmentIndex = 0
        view.sizeToFit()
        view.tintColor = .clear
        
        if #available(iOS 13.0, *) {
            view.ensureiOS12Style()
        }
        view.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor.gray
            ], for: .normal)
        view.setTitleTextAttributes(
            [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15),
             NSAttributedString.Key.foregroundColor: Theme.Color.globalColor
            ], for: .selected)
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.alpha = 0
        return view
    }()
    
    // MARK: - Propertys

    public var memberName: String

    private var member: MemberModel? {
        didSet {
            guard let `member` = member else { return }

            avatarView.setImage(urlString: member.avatarSrc, placeholder: #imageLiteral(resourceName: "avatar"))
            usernameLabel.text = member.username
            titleLabel.text = usernameLabel.text
            titleLabel.sizeToFit()
            joinTimeLabel.text = member.joinTime
            headerView.setImage(urlString: member.avatarSrc, placeholder: #imageLiteral(resourceName: "avatar"))
            blockBtn.isSelected = member.isBlock
            followBtn.isSelected = member.isFollow
            
            followBtn.isHidden = !AccountModel.isLogin
            blockBtn.isHidden = followBtn.isHidden
        }
    }

    private var topics: [TopicModel] = []
    private var replys: [MessageModel] = []


    // MARK: - View Life Cycle

    init(memberName: String) {
        self.memberName = memberName
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        setupConstraints()
        setupRx()
        
        loadData()
        
        if #available(iOS 11.0, *) {
            mainScrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        navigationItem.leftBarButtonItem?.tintColor = .white
        
         navigationItem.titleView = titleLabel
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        navigationController?.navigationBar.shadowImage = UIImage()
        navBarBgAlpha = 0
        navigationController?.navigationBar.isTranslucent = true
        //        navBarTintColor = UIColor.defaultNavBarTintColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navBarBgAlpha = 0
        navigationController?.navigationBar.isTranslucent = true
        //        navBarTintColor = UIColor.defaultNavBarTintColor
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navBarBgAlpha = 1
        navigationController?.navigationBar.isTranslucent = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navBarBgAlpha = 1
        navigationController?.navigationBar.isTranslucent = false
    }
    // MARK: - Setup
    
    func setupSubviews() {
        segmentViewContainer.addSubview(segmentView)
        headerView.addSubviews(blurView, avatarView, usernameLabel, joinTimeLabel, followBtn, blockBtn)
    }

    func setupConstraints() {

        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        avatarView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(15)
            $0.top.equalTo(navigationController?.navigationBar.bottom ?? 64)
            $0.size.equalTo(80)
        }

        usernameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView)
            $0.top.equalTo(avatarView.snp.bottom).offset(10)
        }

        followBtn.snp.makeConstraints {
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView.snp.top)
            $0.width.equalTo(75)
            $0.height.equalTo(35)
        }

        blockBtn.snp.makeConstraints {
            $0.right.equalTo(followBtn)
            $0.top.equalTo(followBtn.snp.bottom).offset(10)
            $0.size.equalTo(followBtn)
        }

        joinTimeLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView)
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(usernameLabel.snp.bottom).offset(10)
        }

        segmentView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.top.bottom.equalToSuperview().inset(8)
        }
    }

    func setupRx() {
        segmentView.rx
            .controlEvent(.valueChanged)
            .subscribeNext { [weak self] in
                guard let `self` = self else { return }
                self.setSelect(index: self.segmentView.selectedSegmentIndex, animation: true)
            }.disposed(by: rx.disposeBag)

        blockBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.blockUserHandle()
            }.disposed(by: rx.disposeBag)

        followBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.followUserHandle()
            }.disposed(by: rx.disposeBag)
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.view.backgroundColor = theme.bgColor
                self?.segmentViewContainer.borderBottom = Border(color: theme.borderColor)
        
                self?.segmentView.setTitleTextAttributes(
                    [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15),
                     NSAttributedString.Key.foregroundColor: theme == .day ? Theme.Color.globalColor : .white
                    ], for: .selected)
                self?.segmentViewContainer.backgroundColor = theme.cellBackgroundColor
            }.disposed(by: rx.disposeBag)
    }
    
    override func headerViewFor(_ pageController: AquamanPageViewController) -> UIView {
        return headerView
    }
    
    override func headerViewHeightFor(_ pageController: AquamanPageViewController) -> CGFloat {
        return 260
    }
    
    override func numberOfViewControllers(in pageController: AquamanPageViewController) -> Int {
        return 2
    }
    
    override func pageController(_ pageController: AquamanPageViewController, viewControllerAt index: Int) -> (UIViewController & AquamanChildViewController) {
        return index == 0 ? MyTopicsViewController(username: memberName) : MyReplyViewController(username: memberName)
    }
    
    override func menuViewFor(_ pageController: AquamanPageViewController) -> UIView {
        return segmentViewContainer
    }
    
    override func menuViewHeightFor(_ pageController: AquamanPageViewController) -> CGFloat {
        return 44
    }

    override func menuViewPinHeightFor(_ pageController: AquamanPageViewController) -> CGFloat {
        return UIApplication.shared.statusBarFrame.height + 44.0
    }
    
    override func pageController(_ pageController: AquamanPageViewController, mainScrollViewDidScroll scrollView: UIScrollView) {
        let rate = (UIApplication.shared.statusBarFrame.height * 3.0)
        let alpha = min(scrollView.contentOffset.y / rate, 1.0)
        joinTimeLabel.alpha = 1 - alpha
        usernameLabel.alpha = joinTimeLabel.alpha
        titleLabel.alpha = alpha
    }
    
    override func pageController(_ pageController: AquamanPageViewController,
                                 contentScrollViewDidEndScroll scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let index = Int(offsetX / scrollView.width)
        
        segmentView.selectedSegmentIndex = index
    }
}


// MARK: - Actions
extension MemberPageViewController {

    func loadData() {
        memberHome(memberName: memberName, success: { [weak self] member, topics, replys in
            self?.topics = topics
            self?.replys = replys
            self?.member = member
        }) { error in
            log.info(error)
        }
    }

    private func blockUserHandle() {
        guard let member = member, let href = member.blockOrUnblockHref else { return }
        blockBtn.isLoading = true
        block(href: href, success: { [weak self] in
            self?.member?.isBlock = !member.isBlock
            HUD.showSuccess("已成功\(!member.isBlock ? "屏蔽" : "取消屏蔽")用户 \(member.username)")
            self?.blockBtn.isLoading = false
        }) { [weak self] error in
            self?.blockBtn.isLoading = false
            HUD.showError(error)
        }
    }

    private func followUserHandle() {
        guard let member = member, let href = member.followOrUnfollowHref else { return }
        followBtn.isLoading = true
        follow(href: href, success: { [weak self] in
            self?.member?.isFollow = !member.isFollow
            HUD.showSuccess("已成功\(!member.isFollow ? "关注" : "取消关注")用户 \(member.username)")
            self?.followBtn.isLoading = false
        }) { [weak self] error in
            self?.followBtn.isLoading = false
            HUD.showError(error)
        }
    }
}


extension UISegmentedControl {
    /// Tint color doesn't have any effect on iOS 13.
    func ensureiOS12Style() {
        if #available(iOS 13, *) {
            let tintColorImage = UIImage(color: tintColor)
            // Must set the background image for normal to something (even clear) else the rest won't work
            setBackgroundImage(UIImage(color: backgroundColor ?? .clear), for: .normal, barMetrics: .default)
            setBackgroundImage(tintColorImage, for: .selected, barMetrics: .default)
            setBackgroundImage(UIImage(color: tintColor.withAlphaComponent(0.2)), for: .highlighted, barMetrics: .default)
            setBackgroundImage(tintColorImage, for: [.highlighted, .selected], barMetrics: .default)
            setTitleTextAttributes([.foregroundColor: tintColor ?? .clear, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .regular)], for: .normal)
            setDividerImage(tintColorImage, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
            layer.borderWidth = 1
            layer.borderColor = tintColor.cgColor
        }
    }
}
