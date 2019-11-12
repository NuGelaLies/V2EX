import UIKit
import SnapKit
import SegementSlide

class MemberPageViewController: TransparentSlideViewController, MemberService, AccountService, InteractivePopProtocol {

    // MARK: - UI

    private lazy var headerContainerView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 260).isActive = true
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
    
    // 禁止全屏返回手势
    var disabled: Bool {
        return true
    }
    
    override var headerView: UIView {
        return headerContainerView
    }

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
            headerContainerView.setImage(urlString: member.avatarSrc, placeholder: #imageLiteral(resourceName: "avatar"))
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
        
        reloadData()
        scrollToSlide(at: 0, animated: false)
        setupSwitcherTheme()
        
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        navigationItem.titleView = titleLabel
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navBarBgAlpha = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navBarBgAlpha = 1
        navigationController?.navigationBar.isTranslucent = false
    }
    
    // MARK: - Setup
    
    func setupSubviews() {
        headerContainerView.addSubviews(blurView, avatarView, usernameLabel, joinTimeLabel, followBtn, blockBtn)
    }

    func setupConstraints() {

        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        avatarView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(15)
            $0.top.equalTo(88)
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
    }

    func setupRx() {

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
                self?.setupSwitcherTheme()
            }.disposed(by: rx.disposeBag)
    }
    
    private func setupSwitcherTheme() {
        config.switcherBackgroundColor = ThemeStyle.style.value.navColor
        config.selectedTitleColor = ThemeStyle.style.value.blackColor
        config.indicatorColor = ThemeStyle.style.value.blackColor
        reloadThemeInSwitcher()
    }
    
    override var titlesInSwitcher: [String] {
        return  ["发布的主题","最近的回复"]
    }
    
    override var bouncesType: BouncesType {
        return .parent
    }
    
    private var config: SegementSlideSwitcherConfig = SegementSlideSwitcherConfig()
    
    override var switcherConfig: SegementSlideSwitcherConfig {
        config.type = .tab
        return config
    }
    
    override func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        return index == 0 ? MyTopicsViewController(username: memberName) : MyReplyViewController(username: memberName)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView, isParent: Bool) {
        super.scrollViewDidScroll(scrollView, isParent: isParent)
        guard isParent else { return }
        updateNavigationBarStyle(scrollView)
    }
    
    private func updateNavigationBarStyle(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > headerStickyHeight {
            slideSwitcherView.layer.applySketchShadow(color: .black, alpha: 0.03, x: 0, y: 2.5, blur: 5)
            slideSwitcherView.layer.add(generateFadeAnimation(), forKey: "reloadSwitcherView")
        } else {
            slideSwitcherView.layer.applySketchShadow(color: .clear, alpha: 0, x: 0, y: 0, blur: 0)
            slideSwitcherView.layer.add(generateFadeAnimation(), forKey: "reloadSwitcherView")
        }
        
        let rate = (UIApplication.shared.statusBarFrame.height * 3.0)
        let alpha = min(scrollView.contentOffset.y / rate, 1.0)
        joinTimeLabel.alpha = 1 - alpha
        usernameLabel.alpha = joinTimeLabel.alpha
        titleLabel.alpha = alpha
    }
    
    private func generateFadeAnimation() -> CATransition {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = 0.25
        fadeTextAnimation.type = .fade
        return fadeTextAnimation
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
