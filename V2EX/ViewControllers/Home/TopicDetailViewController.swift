import Foundation
import UIKit
import SafariServices
import SnapKit
import RxSwift
import RxCocoa
import MobileCoreServices

class TopicDetailViewController: DataViewController, TopicService {

    /// MARK: - UI
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.rowHeight = UITableViewAutomaticDimension
        view.estimatedRowHeight = 80
        view.backgroundColor = .clear
//        view.keyboardDismissMode = .onDrag
        view.register(cellWithClass: TopicCommentCell.self)
        var inset = view.contentInset
        inset.top = navigationController?.navigationBar.height ?? 64
        view.contentInset = inset
        inset.bottom = 0
        view.scrollIndicatorInsets = inset
        self.view.addSubview(view)
        return view
    }()

    private lazy var imagePicker: UIImagePickerController = {
        let view = UIImagePickerController()
        view.mediaTypes = [kUTTypeImage as String]
        view.sourceType = .photoLibrary
        view.delegate = self
        return view
    }()

    private lazy var headerView: TopicDetailHeaderView = {
        let view = TopicDetailHeaderView()
        view.isHidden = true
        return view
    }()

    private lazy var commentInputView: CommentInputView = {
        let view = CommentInputView(frame: .zero)
        view.isHidden = true
        self.view.addSubview(view)
        return view
    }()

    private lazy var backTopBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "backTop"), for: .normal)
        view.setImage(#imageLiteral(resourceName: "backTop"), for: .selected)
        view.sizeToFit()
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 4
        self.view.addSubview(view)
        view.isHidden = true
        return view
    }()

    // MARK: Propertys

    private var topic: TopicModel? {
        didSet {
            guard let topic = topic else { return }
            title = topic.title
            headerView.topic = topic
        }
    }

    private var selectComment: CommentModel? {
        guard let selectIndexPath = tableView.indexPathForSelectedRow else {
            return nil
        }
        return dataSources[selectIndexPath.row]
    }

    public var topicID: String
    
    public var showInputView: Bool?

    // 加工数据
    private var dataSources: [CommentModel] = [] {
        didSet {
            var title = dataSources.count.boolValue ? "全部回复" : ""
            if isShowOnlyFloor {
                title = dataSources.count.boolValue ? "楼主回复" : "楼主暂无回复"
            }
            headerView.replyTitle = title
        }
    }

    // 原始数据
    private var comments: [CommentModel] = []

    private var commentText: String = ""
    private var isShowOnlyFloor: Bool = false

    private var page = 1, maxPage = 1

    private var inputViewBottomConstranit: Constraint?
    private var inputViewHeightConstraint: Constraint?

    private let isSelectedVariable = Variable(false)
    private let isShowToolBarVariable = Variable(false)

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity?.webpageURL = API.topicDetail(topicID: topicID, page: page).url
        userActivity?.becomeCurrent()
    }
    
    deinit {
        setStatusBarBackground(.clear)
        userActivity?.invalidate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let isShow = showInputView {
            if isShow == false {
                commentInputView.isHidden = true
            }
        }
     
    
        log.info(commentInputView.isHidden)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        commentInputView.textView.resignFirstResponder()
        isShowToolBarVariable.value = false
        setStatusBarBackground(.clear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        setStatusBarBackground(.clear)
        isShowToolBarVariable.value = false
    }

    init(topicID: String) {
        self.topicID = topicID

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // 如果当前 textView 是第一响应者，则忽略自定义的 MenuItemAction， 不在 Menu视图上显示自定义的 item
        if !isFirstResponder, [#selector(copyCommentAction),
                               #selector(replyCommentAction),
                               #selector(thankCommentAction),
                               #selector(viewDialogAction),
                               #selector(atMemberAction),
                               #selector(fenCiAction)].contains(action) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }

    // MARK: - Setup

    override func setupSubviews() {
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }

        tableView.tableHeaderView = headerView

        headerView.tapHandle = { [weak self] type in
            self?.tapHandle(type)
        }

        headerView.webLoadComplete = { [weak self] in
            self?.endLoading()
            self?.headerView.isHidden = false
            self?.tableView.reloadData()
            self?.setupRefresh()
        }

        commentInputView.sendHandle = { [weak self] in
            self?.replyComment()
        }

        commentInputView.uploadPictureHandle = { [weak self] in
            guard let `self` = self else { return }
            self.present(self.imagePicker, animated: true, completion: nil)
        }

        commentInputView.atUserHandle = { [weak self] in
            guard let `self` = self,
                self.comments.count.boolValue else { return }
            self.atMembers()
        }

        commentInputView.updateHeightHandle = { [weak self] height in
            self?.inputViewHeightConstraint?.update(offset: height)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: #imageLiteral(resourceName: "moreNav"),
            style: .plain,
            action: { [weak self] in
                self?.moreHandle()
        })
        title = "加载中..."
    }

    private func setupRefresh() {

        tableView.addHeaderRefresh { [weak self] in
            self?.fetchTopicDetail()
        }

        tableView.addFooterRefresh { [weak self] in
            self?.fetchMoreComment()
        }
    }

    private func interactHook(_ URL: URL) {
        let link = URL.absoluteString
        if URL.path.contains("/member/") {
            let href = URL.path
            let name = href.lastPathComponent
            let member = MemberModel(username: name, url: href, avatar: "")
            tapHandle(.member(member))
        } else if URL.path.contains("/t/") {
            let topicID = URL.path.lastPathComponent
            tapHandle(.topic(topicID))
        } else if URL.path.contains("/go/") {
            tapHandle(.node(NodeModel(title: "", href: URL.path)))
        } else if link.hasPrefix("https://") || link.hasPrefix("http://"){
            tapHandle(.webpage(URL))
        }
    }

    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            //            $0.top.equalToSuperview().offset(0.5)
            $0.top.equalToSuperview().offset(-(tableView.contentInset.top - 0.8))
        }

        var inputViewHeight = KcommentInputViewHeight

        if #available(iOS 11.0, *) {
            inputViewHeight += AppWindow.shared.window.safeAreaInsets.bottom//view.safeAreaInsets.bottom
        }

        tableView.contentInset = UIEdgeInsets(top: tableView.contentInset.top, left: tableView.contentInset.left, bottom: KcommentInputViewHeight, right: tableView.contentInset.right)

        commentInputView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            self.inputViewBottomConstranit = $0.bottom.equalToSuperview().constraint
            self.inputViewHeightConstraint = $0.height.equalTo(inputViewHeight).constraint
        }

        backTopBtn.snp.makeConstraints {
            $0.right.equalToSuperview().inset(12)
            $0.bottom.equalTo(commentInputView.snp.top).offset(-12)
        }
    }

    override func setupRx() {
        ThemeStyle.style.asObservable()
            .subscribeNext { theme in
                setStatusBarBackground(theme == .day ? .white : .black, borderColor: .clear)
            }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.UIApplicationWillEnterForeground)
            .subscribeNext { _ in
                setStatusBarBackground(.clear)
            }.disposed(by: rx.disposeBag)

        backTopBtn.rx.tap
            .subscribeNext { [weak self] in
                guard let `self` = self else { return }
                self.isShowToolBarVariable.value = false
                if self.backTopBtn.isSelected {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
                } else {
                    // 会导致UI卡顿, 原因未知
//                    if self.dataSources.count.boolValue {
//                        let indexPath = IndexPath(row: self.dataSources.count - 1, section: 0)
//                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
//                    } else {
                        self.tableView.scrollToBottom()
//                    }
                }
        }.disposed(by: rx.disposeBag)
        
        Observable.of(NotificationCenter.default.rx.notification(.UIKeyboardWillShow),
                      NotificationCenter.default.rx.notification(.UIKeyboardWillHide),
                      NotificationCenter.default.rx.notification(.UIKeyboardDidShow),
                      NotificationCenter.default.rx.notification(.UIKeyboardDidHide)).merge()
            .subscribeNext { [weak self] notification in
                guard let `self` = self else { return }
                guard var userInfo = notification.userInfo,
                    let keyboardRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                let convertedFrame = self.view.convert(keyboardRect, from: nil)
                let heightOffset = self.view.bounds.size.height - convertedFrame.origin.y
                let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double
                self.inputViewBottomConstranit?.update(offset: -heightOffset)
                UIView.animate(withDuration: duration ?? 0.25) {
                    self.view.layoutIfNeeded()
                }
            }.disposed(by: rx.disposeBag)

        isSelectedVariable.asObservable()
            .distinctUntilChanged()
            .subscribeNext { [weak self] isSelected in
                guard let `self` = self else { return }
                UIView.animate(withDuration: 0.2) {
                    self.backTopBtn.transform = isSelected ? CGAffineTransform(rotationAngle: .pi) : .identity
                    self.backTopBtn.isSelected = isSelected
                }
        }.disposed(by: rx.disposeBag)

        isShowToolBarVariable.asObservable()
            .distinctUntilChanged()
            .subscribeNext { [weak self] isShow in
                guard let `self` = self else { return }
                self.setTabBarHiddn(isShow)
            }.disposed(by: rx.disposeBag)
    }

    // MARK: States Handle

    override func hasContent() -> Bool {
        let hasContent = topic != nil

        if hasContent && (showInputView == nil || showInputView == true) {
            commentInputView.isHidden = false
        }
        return hasContent
    }

    override func loadData() {
        fetchTopicDetail()
    }

    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {
        fetchTopicDetail()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension TopicDetailViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSources.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: TopicCommentCell.self)!
        let comment = dataSources[indexPath.row]
        cell.hostUsername = topic?.member?.username ?? ""
        cell.comment = comment
        cell.tapHandle = { [weak self] type in
            self?.tapHandle(type)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // 强制结束 HeaderView 中 WebView 的第一响应者， 不然无法显示 MenuView
        if !commentInputView.textView.isFirstResponder {
            view.endEditing(true)
        }

        // 如果当前控制器不是第一响应者不显示 MenuView
        guard isFirstResponder else { return }
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        let comment = dataSources[indexPath.row]
        let menuVC = UIMenuController.shared
        var targetRectangle = cell.frame
        targetRectangle.origin.y = targetRectangle.height * 0.4
        targetRectangle.size.height = 1

        let replyItem = UIMenuItem(title: "回复", action: #selector(replyCommentAction))
        let atUserItem = UIMenuItem(title: "@TA", action: #selector(atMemberAction))
        let copyItem = UIMenuItem(title: "复制", action: #selector(copyCommentAction))
        let fenCiItem = UIMenuItem(title: "分词", action: #selector(fenCiAction))
        let thankItem = UIMenuItem(title: "感谢", action: #selector(thankCommentAction))
        let viewDialogItem = UIMenuItem(title: "对话", action: #selector(viewDialogAction))
        menuVC.setTargetRect(targetRectangle, in: cell)
        menuVC.menuItems = [replyItem, copyItem, atUserItem, viewDialogItem]
        
        if comment.content.trimmed.isNotEmpty {
            menuVC.menuItems?.insert(fenCiItem, at: 2)
        }
        
        // 不显示感谢的情况
        // 1. 已经感谢
        // 2. 当前题主是登录用户本人 && 点击的回复是题主本人
        // 3. 当前点击的回复是登录用户本人
        if comment.isThank ||
            (topic?.member?.username == comment.member.username &&
            AccountModel.current?.username == topic?.member?.username) ||
            AccountModel.current?.username == comment.member.username {
        } else {
            menuVC.menuItems?.insert(thankItem, at: 1)
        }
        
        menuVC.setMenuVisible(true, animated: true)
        
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

// MARK: - UIScrollViewDelegate
extension TopicDetailViewController {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        commentInputView.textView.resignFirstResponder()
        
        let isReachedBottom = scrollView.isReachedBottom()
        if backTopBtn.isHidden.not {
            isSelectedVariable.value = isReachedBottom// ? true : scrollView.contentOffset.y > 2000
        }

        let contentHeightLessThanViewHeight = scrollView.contentOffset.y < (navigationController?.navigationBar.height ?? 64)
        if contentHeightLessThanViewHeight || isReachedBottom || scrollView.contentOffset.y < 0 { return }

        //获取到拖拽的速度 >0 向下拖动 <0 向上拖动
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y
        if (velocity < -5) {
            //向上拖动，隐藏导航栏
            if !isShowToolBarVariable.value {
                isShowToolBarVariable.value = true
            }
        }else if (velocity > 5) {
            //向下拖动，显示导航栏
            if isShowToolBarVariable.value {
                isShowToolBarVariable.value = false
            }
        }else if (velocity == 0) {
            //停止拖拽
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        commentInputView.textView.resignFirstResponder()

        // ContentSize 大于 当前视图高度才显示， 滚动到底部/顶部按钮
        // 150 的偏差
        backTopBtn.isHidden = tableView.contentSize.height < (tableView.height + 150)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        isShowToolBarVariable.value = false
        return true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.isReachedBottom() {
            setTabBarHiddn(false, duration: 0.3)
            isShowToolBarVariable.value = false
        }
    }

    private func setTabBarHiddn(_ hidden: Bool, duration: TimeInterval = 0.1) {
        guard tableView.contentSize.height > view.height else { return }
        guard let navHeight = navigationController?.navigationBar.height else { return }

        UIView.animate(withDuration: duration, animations: {
            if hidden {
                self.inputViewBottomConstranit?.update(inset: -self.commentInputView.height)
                self.view.layoutIfNeeded()
                self.navigationController?.navigationBar.y -= navHeight
                GCD.delay(0.1, block: {
                    setStatusBarBackground(ThemeStyle.style.value.whiteColor, borderColor: ThemeStyle.style.value.borderColor)
                })
                self.tableView.height = Constants.Metric.screenHeight
            } else { //显示
                self.inputViewBottomConstranit?.update(inset: 0)
                self.view.layoutIfNeeded()
                self.navigationController?.navigationBar.y = UIApplication.shared.statusBarFrame.height
                setStatusBarBackground(.clear)
            }
        })
    }
}

// MARK: - UIImagePickerControllerDelegate && UINavigationControllerDelegate
extension TopicDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        guard var image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        image = image.resized(by: 0.7)
        guard let data = UIImageJPEGRepresentation(image, 0.5) else { return }

        let path = FileManager.document.appendingPathComponent("smfile.png")
        let error = FileManager.save(data, savePath: path)
        if let err = error {
            HUD.showTest(err)
            log.error(err)
        }
        uploadPictureHandle(path)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true) {
            self.commentInputView.textView.becomeFirstResponder()
        }
    }
}


// MARK: - 处理 Cell 内部、导航栏Item、SheetShare 的 Action
extension TopicDetailViewController {

    /// Cell 内部点击处理
    ///
    /// - Parameter type: 触发的类型
    private func tapHandle(_ type: TapType) {
        switch type {
        case .reply, .memberAvatarLongPress: break
        default: setStatusBarBackground(.clear)
        }

        switch type {
        case .webpage(let url):
            openWebView(url: url)
        case .member(let member):
            let memberPageVC = MemberPageViewController(memberName: member.username)
            self.navigationController?.pushViewController(memberPageVC, animated: true)
        case .memberAvatarLongPress(let member):
            atMember(member.atUsername)
        case .reply(let member):
            if member.atUsername == commentInputView.textView.text && commentInputView.textView.isFirstResponder { return }
            commentInputView.textView.text = ""
            atMember(member.atUsername)
        case .imageURL(let src):
            showImageBrowser(imageType: .imageURL(src))
        case .image(let image):
            showImageBrowser(imageType: .image(image))
        case .node(let node):
            let nodeDetailVC = NodeDetailViewController(node: node)
            self.navigationController?.pushViewController(nodeDetailVC, animated: true)
        case .topic(let topicID):
            let topicDetailVC = TopicDetailViewController(topicID: topicID)
            self.navigationController?.pushViewController(topicDetailVC, animated: true)
        }
    }

    /// 点击更多处理
    private func moreHandle() {
        setStatusBarBackground(.clear)
        view.endEditing(true)

        /// 切换 是否显示楼主
        let floorItem = isShowOnlyFloor ?
            ShareItem(icon: #imageLiteral(resourceName: "unfloor"), title: "查看所有", type: .floor) :
            ShareItem(icon: #imageLiteral(resourceName: "floor"), title: "只看楼主", type: .floor)
        let favoriteItem = (topic?.isFavorite ?? false) ?
            ShareItem(icon: #imageLiteral(resourceName: "favorite"), title: "取消收藏", type: .favorite) :
            ShareItem(icon: #imageLiteral(resourceName: "unfavorite"), title: "收藏", type: .favorite)

        var section1 = [floorItem, favoriteItem]

        // 如果已经登录 并且 是当前登录用户发表的主题, 则隐藏 感谢和忽略
        let username = AccountModel.current?.username ?? ""
        if username != topic?.member?.username {
            let thankItem = (topic?.isThank ?? false) ?
                ShareItem(icon: #imageLiteral(resourceName: "thank"), title: "已感谢", type: .thank) :
                ShareItem(icon: #imageLiteral(resourceName: "alreadyThank"), title: "感谢", type: .thank)

            section1.append(thankItem)
            section1.append(ShareItem(icon: #imageLiteral(resourceName: "ignore"), title: "忽略", type: .ignore))
            section1.append(ShareItem(icon: #imageLiteral(resourceName: "report"), title: "举报", type: .report))
        }

        let section2 = [
            ShareItem(icon: #imageLiteral(resourceName: "copy_link"), title: "复制链接", type: .copyLink),
            ShareItem(icon: #imageLiteral(resourceName: "safari"), title: "在 Safari 中打开", type: .safari),
            ShareItem(icon: #imageLiteral(resourceName: "share"), title: "分享", type: .share)
        ]

        let sheetView = ShareSheetView(sections: [section1, section2])
        sheetView.present()

        sheetView.shareSheetDidSelectedHandle = { [weak self] type in
            self?.shareSheetDidSelectedHandle(type)
        }
    }

    // 点击导航栏右侧的 更多
    private func shareSheetDidSelectedHandle(_ type: ShareItemType) {

        // 需要授权的操作
        if type.needAuth, !AccountModel.isLogin{
            HUD.showError("请先登录")
            return
        }

        switch type {
        case .floor:
            showOnlyFloorHandle()
        case .favorite:
            favoriteHandle()
        case .thank:
            thankTopicHandle()
        case .ignore:
            ignoreTopicHandle()
        case .report:
            reportHandle()
        case .copyLink:
            copyLink()
        case .safari:
            openSafariHandle()
        case .share:
            systemShare()
        default:
            break
        }
    }
}

// MARK: - 点击回复的相关操作
extension TopicDetailViewController {

    // 如果已经 at 的用户， 让 TextView 选中用户名
    private func atMember(_ atUsername: String?) {
        guard var `atUsername` = atUsername, atUsername.trimmed.isNotEmpty else { return }
        commentInputView.textView.becomeFirstResponder()

        if commentInputView.textView.text.contains(atUsername) {
            let range = commentInputView.textView.text.NSString.range(of: atUsername)
            commentInputView.textView.selectedRange = range
            return
        }

        if let lastCharacter = commentInputView.textView.text.last, lastCharacter != " " {
            atUsername.insert(" ", at: commentInputView.textView.text.startIndex)
        }
        atUsername = Preference.shared.atMemberAddFloor ? atUsername + "#" + (selectComment?.floor ?? "") + " " : atUsername
        commentInputView.textView.insertText(atUsername)
    }

    private func atMembers() {
        // 解层
        let members = self.comments.flatMap { $0.member }
        let memberSet = Set<MemberModel>(members)
        let uniqueMembers = Array(memberSet).filter { $0.username != AccountModel.current?.username }
        let memberListVC = MemberListViewController(members: uniqueMembers )
        let nav = NavigationViewController(rootViewController: memberListVC)
        self.present(nav, animated: true, completion: nil)

        memberListVC.callback = { [weak self] members in
            guard let `self` = self else { return }
            self.commentInputView.textView.becomeFirstResponder()

            guard members.count.boolValue else { return }

            var atsWrapper = members
                .filter{ !self.commentInputView.textView.text.contains($0.atUsername) }
                .map { $0.atUsername }
                .joined()

            if self.commentInputView.textView.text.last != " " {
                atsWrapper.insert(" ", at: self.commentInputView.textView.text.startIndex)
            }
            self.commentInputView.textView.deleteBackward()
            self.commentInputView.textView.insertText(atsWrapper)
        }
    }

    @objc private func replyCommentAction() {
        commentInputView.textView.text = ""
        atMember(selectComment?.member.atUsername)
    }

    @objc private func thankCommentAction() {
        guard let replyID = selectComment?.id,
            let token = topic?.token else {
                HUD.showError("操作失败")
                return
        }
        thankReply(replyID: replyID, token: token, success: { [weak self] in
            guard let `self` = self,
                let selectIndexPath = self.tableView.indexPathForSelectedRow else { return }
            HUD.showSuccess("已成功发送感谢")
            self.dataSources[selectIndexPath.row].isThank = true
            if let thankCount = self.dataSources[selectIndexPath.row].thankCount {
                self.dataSources[selectIndexPath.row].thankCount = thankCount + 1
            } else {
                self.dataSources[selectIndexPath.row].thankCount = 1
            }
//            self.tableView.reloadData {}
            log.info([selectIndexPath])
            self.tableView.reloadRows(at: [selectIndexPath], with: .none)
        }) { error in
            HUD.showError(error)
        }
    }

    @objc private func copyCommentAction() {
        guard let content = selectComment?.content else { return }

        let result = TextParser.extractLink(content)

        // 如果没有识别到链接, 或者 结果只有一个并且与本身内容一样
        // 则直接复制到剪切板
        if result.count == 0 || result.count == 1 && result[0] == content {
            UIPasteboard.general.string = content
            HUD.showSuccess("已复制到剪切板")
            return
        }

        let alertVC = UIAlertController(title: "提取文本", message: nil, preferredStyle: .actionSheet)

        let action: ((UIAlertAction) -> Void) = {
            UIPasteboard.general.string = $0.title;
            HUD.showSuccess("已复制到剪切板")
        }

        alertVC.addAction(
            UIAlertAction(
                title: content.deleteOccurrences(target: "\r").deleteOccurrences(target: "\n"),
                style: .default,
                handler: action)
        )

        for item in result {
            alertVC.addAction(UIAlertAction(title: item, style: .default, handler: action))
        }

        if let indexPath = tableView.indexPathForSelectedRow,
            let cell = tableView.cellForRow(at: indexPath) {
            alertVC.popoverPresentationController?.sourceView = cell
            alertVC.popoverPresentationController?.sourceRect = cell.bounds
        }

        alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        setStatusBarBackground(.clear)
        present(alertVC, animated: true, completion: nil)
    }

    @objc private func fenCiAction() {
        guard let text = selectComment?.content else { return }
        let vc = FenCiViewController(text: text)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func viewDialogAction() {
        guard let `selectComment` = selectComment else { return }
        let dialogs = CommentModel.atUsernameComments(comments: comments, currentComment: selectComment)

        guard dialogs.count.boolValue else {
            HUD.showInfo("没有找到与该用户有关的对话")
            return
        }


        let viewDialogVC = ViewDialogViewController(comments: dialogs, username: selectComment.member.username)
        let nav = NavigationViewController(rootViewController: viewDialogVC)
        present(nav, animated: true, completion: nil)
    }

    @objc private func atMemberAction() {
        atMember(selectComment?.member.atUsername)
    }
}

// MARK: - Request
extension TopicDetailViewController {

    /// 获取主题详情
    func fetchTopicDetail(complete: (() -> Void)? = nil) {
        page = 1

        startLoading()
        topicDetail(topicID: topicID, success: { [weak self] topic, comments, maxPage in
            guard let `self` = self else { return }
            self.dataSources = comments
            self.comments = comments
            self.topic = topic
            self.tableView.endHeaderRefresh()
            self.maxPage = maxPage

            complete?()
            }, failure: { [weak self] error in
                self?.errorMessage = error
                self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
                self?.tableView.endHeaderRefresh()
                self?.title = "加载失败"
        })
    }

    /// 获取更多评论
    func fetchMoreComment() {
        if page >= maxPage {
            self.tableView.endRefresh(showNoMore: true)
            return
        }

        page += 1

        topicMoreComment(topicID: topicID, page: page, success: { [weak self] comments in
            guard let `self` = self else { return }
            self.dataSources.append(contentsOf: comments)
            self.comments.append(contentsOf: comments)
            self.tableView.endFooterRefresh(showNoMore: self.page >= self.maxPage)
            self.refreshDataSource()
            }, failure: { [weak self] error in
                self?.tableView.endFooterRefresh()
                self?.page -= 1
        })
    }


    /// 回复评论
    private func replyComment() {

        guard let `topic` = self.topic else {
            HUD.showError("回复失败")
            return
        }

        guard AccountModel.isLogin else {
            HUD.showError("请先登录", completionBlock: {
                presentLoginVC()
            })
            return
        }

        guard commentInputView.textView.text.trimmed.isNotEmpty else {
            HUD.showInfo("回复失败，您还没有输入任何内容", completionBlock: { [weak self] in
                self?.commentInputView.textView.becomeFirstResponder()
            })
            return
        }

        guard let once = topic.once else {
            HUD.showError("无法获取 once，请尝试重新登录", completionBlock: {
                presentLoginVC()
            })
            return
        }

        commentText = commentInputView.textView.text
        commentInputView.textView.text = nil
        commentInputView.textView.resignFirstResponder()

        HUD.show()
        comment(
            once: once,
            topicID: topicID,
            content: commentText, success: { [weak self] in
                guard let `self` = self else { return }
                HUD.showSuccess("回复成功")
                HUD.dismiss()

                guard self.page == 1 else { return }
                self.fetchTopicDetail(complete: { [weak self] in
                    self?.tableView.reloadData {}
                })
        }) { [weak self] error in
            guard let `self` = self else { return }
            HUD.dismiss()
            HUD.showError(error)
            self.commentInputView.textView.text = self.commentText
            self.commentInputView.textView.becomeFirstResponder()
        }
    }

    // 上传配图请求
    private func uploadPictureHandle(_ fileURL: String) {
        HUD.show()

        uploadPicture(localURL: fileURL, success: { [weak self] url in
            log.info(url)
            self?.commentInputView.textView.insertText(url + " ")
            self?.commentInputView.textView.becomeFirstResponder()
            HUD.dismiss()
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }

    /// 收藏、取消收藏请求
    private func favoriteHandle() {

        guard let `topic` = topic,
            let token = topic.token else {
                HUD.showError("操作失败")
                return
        }

        // 已收藏, 取消收藏
        if topic.isFavorite {
            unfavoriteTopic(topicID: topicID, token: token, success: { [weak self] in
                HUD.showSuccess("取消收藏成功")
                self?.topic?.isFavorite = false
                }, failure: { error in
                    HUD.showError(error)
            })
            return
        }

        // 没有收藏
        favoriteTopic(topicID: topicID, token: token, success: { [weak self] in
            HUD.showSuccess("收藏成功")
            self?.topic?.isFavorite = true
        }) { error in
            HUD.showError(error)
        }
    }

    /// 感谢主题请求
    private func thankTopicHandle() {

        guard let `topic` = topic else {
            HUD.showError("操作失败")
            return
        }

        // 已感谢
        guard !topic.isThank else {
            HUD.showInfo("主题已感谢，无法重复提交")
            return
        }

        guard let token = topic.token else {
            HUD.showError("操作失败")
            return
        }

        thankTopic(topicID: topicID, token: token, success: { [weak self] in
            HUD.showSuccess("感谢已发送")
            self?.topic?.isThank = true
        }) { error in
            HUD.showError(error)
        }
    }

    /// 忽略主题请求
    private func ignoreTopicHandle() {
        guard let `topic` = topic,
            let once = topic.once else {
                HUD.showError("操作失败")
                return
        }

        ignoreTopic(topicID: topicID, once: once, success: { [weak self] in
            // 需要 pop 掉该控制器? YES
            // 需要刷新主题列表？ NO
            HUD.showSuccess("已成功忽略该主题", completionBlock: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
        }) { error in
            HUD.showError(error)
        }
    }

    /// 举报主题， 主要是过审核用
    private func reportHandle() {

        let alert = UIAlertController(title: "举报", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textView in
            textView.placeholder = "请填写举报原因"
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "确定举报", style: .destructive, handler: { _ in
            guard let text = alert.textFields?.first?.text, text.isNotEmpty else {
                HUD.showError("请输入举报原因")
                self.reportHandle()
                return
            }
            HUD.show()

            self.comment(
                once: self.topic?.once ?? "",
                topicID: self.topicID,
                content: "@Livid " + text, success: {
                    HUD.showSuccess("举报成功")
                    HUD.dismiss()
            }) { error in
                log.error(error)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Action Handle
extension TopicDetailViewController {
    
    private func copyLink() {
        UIPasteboard.general.string = API.topicDetail(topicID: topicID, page: page).defaultURLString
        HUD.showSuccess("链接已复制")
    }

    /// 打开系统分享
    func systemShare() {

        guard let url = API.topicDetail(topicID: topicID, page: page).url else { return }

        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: BrowserActivity.compatibleActivities)
        
        controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        currentViewController().present(controller, animated: true, completion: nil)
    }

    /// 是否只看楼主
    func showOnlyFloorHandle() {
        isShowOnlyFloor = !isShowOnlyFloor

        refreshDataSource()
//        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func refreshDataSource() {
        if isShowOnlyFloor {
            dataSources = comments.filter { $0.member.username == topic?.member?.username }
            if dataSources.count.boolValue.not {
                tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: true)
            }
        } else {
            dataSources = comments
        }
        tableView.reloadData()
    }

    /// 从系统 Safari 浏览器中打开
    func openSafariHandle() {
        guard let url = API.topicDetail(topicID: topicID, page: page).url,
            UIApplication.shared.canOpenURL(url) else {
                HUD.showError("无法打开网页")
                return
        }
        UIApplication.shared.openURL(url)
    }
}


// MARK: - Peek && Pop
extension TopicDetailViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        let vc = viewControllerToCommit
        let nav = NavigationViewController(rootViewController: vc)
        show(nav, sender: self)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) as? TopicCommentCell else { return nil }
        let selectComment = dataSources[indexPath.row]
        
        // 和长按头像手势冲突
        //        let loc = tableView.convert(location, to: cell)
        //        cell.avatarView.layer.contains(loc)
        // x + 50 容错点, y + 15 容错点
        //        if loc.x < cell.avatarView.right + 50 && loc.y < (cell.avatarView.bottom + 15) {
        //            let memberPageVC = MemberPageViewController(memberName: selectComment.member.username)
        //            previewingContext.sourceRect = cell.frame
        //            return memberPageVC
        //        }
        
        let dialogs = CommentModel.atUsernameComments(comments: comments, currentComment: selectComment)
        guard dialogs.count.boolValue else { return nil }

        let viewDialogVC = ViewDialogViewController(comments: dialogs, username: selectComment.member.username)
        previewingContext.sourceRect = cell.frame

        var contentSize = viewDialogVC.tableView.size
        if let lastCellBottom = viewDialogVC.tableView.visibleCells.last?.bottom {
            contentSize.height = lastCellBottom + viewDialogVC.tableView.contentInset.top
        }

        viewDialogVC.preferredContentSize = contentSize
        return viewDialogVC
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        // Bug - 如果数据没有加载完成, 此时用户上拉, 无法获取到 是否收藏
        let favoriteTitle = (topic?.isFavorite ?? false) ? "取消收藏" : "收藏"
        let favoriteAction = UIPreviewAction(
            title: favoriteTitle,
            style: .default) { [weak self] action, vc in
                self?.favoriteHandle()
        }
        
        let copyAction = UIPreviewAction(
            title: "复制链接",
            style: .default) { [weak self] action, vc in
                self?.copyLink()
        }
        
        let shareAction = UIPreviewAction(
            title: "分享",
            style: .default) { [weak self] action, vc in
                self?.systemShare()
        }
        return [favoriteAction, copyAction, shareAction]
    }
}
