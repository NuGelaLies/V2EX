import UIKit
import WebKit
import SnapKit

enum TapType {
    case member(MemberModel)
    case memberAvatarLongPress(MemberModel)
    case reply(CommentModel)
    case node(NodeModel)
    case imageURL(String)
    case image(UIImage)
    case webpage(URL)
    case topic(String)
    case foreword(CommentModel)
}

class TopicDetailHeaderView: UIView {


    enum HTMLTag: EnumCollection {
        case h1, h2, h3, pre, bigger, small, subtle, topicContent
        var key: String {
            switch self {
            case .h1: return "{h1FontSize}"
            case .h2: return "{h2FontSize}"
            case .h3: return "{h3FontSize}"
            case .pre: return "{preFontSize}"
            case .bigger: return "{biggerFontSize}"
            case .small: return "{smallFontSize}"
            case .subtle: return "{subtleFontSize}"
            case .topicContent: return "{topicContentFontSize}"
            }
        }

        var fontSize: Int {
            switch self {
            case .h1: return 16
            case .h2: return 16
            case .h3: return 16
            case .pre: return 13
            case .bigger: return 16
            case .small: return 11
            case .subtle: return 12
            case .topicContent: return 13
            }
        }
    }

    struct Metric {
        static let replyLabelHeight: CGFloat = 45
        static let margin: CGFloat = 15
    }

    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.setCornerRadius = 5
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var timeLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 11)
        view.textColor = UIColor.hex(0xCCCCCC)
        return view
    }()
    
    private lazy var nodeLabel: UIInsetLabel = {
        let view = UIInsetLabel()
        view.font = UIFont.systemFont(ofSize: 13)
        view.textColor = UIColor.hex(0x999999)
        view.backgroundColor = UIColor.hex(0xf5f5f5)
        view.contentInsets = UIEdgeInsets(top: 2, left: 3, bottom: 2, right: 3)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = UIFont.boldSystemFont(ofSize: 17)
        view.clickCopyable = true
        view.isUserInteractionEnabled = true
        view.font = .preferredFont(forTextStyle: .headline)
        if #available(iOS 10, *) {
            view.adjustsFontForContentSizeCategory = true
        }
        return view
    }()
    
    private lazy var webView: WKWebView = {
        let view = WKWebView()
        view.scrollView.isScrollEnabled = false
        view.isOpaque = false
        view.navigationDelegate = self
        return view
    }()

    private lazy var replyLabel: UIInsetLabel = {
        let view = UIInsetLabel()
        view.text = "全部回复"
        view.contentInsetsLeft = Metric.margin
        view.contentInsetsTop = Metric.margin
        view.font = UIFont.systemFont(ofSize: 13)
        view.backgroundColor = ThemeStyle.style.value.bgColor
        view.textColor = #colorLiteral(red: 0.5333333333, green: 0.5333333333, blue: 0.5333333333, alpha: 1)
        return view
    }()

    private var htmlHeight: CGFloat = 0 {
        didSet {
            updateWebViewHeight()
        }
    }

    private var webViewConstraint: Constraint?

    public var webLoadComplete: Action?

    public var tapHandle: ((_ type: TapType) -> Void)?
    
    public var userAvatar: UIImage? {
        return avatarView.image
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: Constants.Metric.screenWidth, height: 130))
        backgroundColor = .white
        
        addSubviews(
            avatarView,
            usernameLabel,
            timeLabel,
            nodeLabel,
            titleLabel,
            webView,
            replyLabel
        )
        
        setupConstraints()
        setupAction()

        webView.scrollView.rx
            .observe(CGSize.self, "contentSize")
            .filterNil()
            .distinctUntilChanged()
            .filter { $0.height >= 100 }
            .subscribeNext { [weak self] size in
                self?.htmlHeight = size.height
        }.disposed(by: rx.disposeBag)

        NotificationCenter.default.rx
            .notification(.UIContentSizeCategoryDidChange)
            .subscribeNext { [weak self] _ in
                self?.updateWebViewHeight()
        }.disposed(by: rx.disposeBag)
    }

    private func updateWebViewHeight() {
        webViewConstraint?.update(offset: htmlHeight)
        height = titleLabel.bottom + htmlHeight + Metric.margin + Metric.replyLabelHeight
        webLoadComplete?()
    }

    private func setupAction() {
        let avatarTapGesture = UITapGestureRecognizer()
        avatarView.addGestureRecognizer(avatarTapGesture)

        let nodeTapGesture = UITapGestureRecognizer()
        nodeLabel.addGestureRecognizer(nodeTapGesture)

        avatarTapGesture.rx
            .event
            .subscribeNext { [weak self] _ in
                guard let member = self?.topic?.member else { return }
                self?.tapHandle?(.member(member))
            }.disposed(by: rx.disposeBag)

        nodeTapGesture.rx
            .event
            .subscribeNext { [weak self] _ in
                guard let node = self?.topic?.node else { return }
                self?.tapHandle?(.node(node))
            }.disposed(by: rx.disposeBag)

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.backgroundColor = theme.cellBackgroundColor
                self?.titleLabel.textColor = theme.titleColor
                self?.usernameLabel.textColor = theme.titleColor
                self?.nodeLabel.backgroundColor = theme == .day ? UIColor.hex(0xf5f5f5) : theme.bgColor
                self?.timeLabel.textColor = theme.dateColor
            }.disposed(by: rx.disposeBag)
        
//        UIMenuController.shared.menuItems = [UIMenuItem(title: "Base64 解码", action: #selector(self.base64Decode))]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConstraints() {
        avatarView.snp.makeConstraints {
            $0.left.top.equalToSuperview().inset(Metric.margin)
            $0.size.equalTo(35)
        }
        
        usernameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(10)
            $0.top.equalTo(avatarView).offset(1)
        }
        
        timeLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLabel)
            $0.right.equalTo(nodeLabel).priority(.high)
            $0.bottom.equalTo(avatarView).inset(1)
        }
        
        nodeLabel.snp.makeConstraints {
            $0.top.right.equalToSuperview().inset(Metric.margin)
        }
        
        titleLabel.snp.makeConstraints {
            $0.right.equalTo(timeLabel)
            $0.left.equalTo(avatarView)
            $0.top.equalTo(avatarView.snp.bottom).offset(Metric.margin)
        }

        webView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Metric.margin)
            $0.left.right.equalToSuperview()
            webViewConstraint = $0.height.equalTo(0).constraint
        }

        replyLabel.snp.makeConstraints {
            $0.top.equalTo(webView.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(Metric.replyLabelHeight)
        }
    }

    var topic: TopicModel? {
        didSet {
            guard let `topic` = topic else { return }
            guard let user = topic.member else { return }
            avatarView.setImage(urlString: user.avatarSrc, placeholder: #imageLiteral(resourceName: "avatarRect"))
            usernameLabel.text = user.username
            titleLabel.text = topic.title
            timeLabel.text = topic.publicTime
            timeLabel.isHidden = topic.publicTime.isEmpty

            do {
                let fileName = ThemeStyle.style.value == .day ? "day.css" : "night.css"
                if let filePath = Bundle.main.path(forResource: "style", ofType: "css"),
                    let themeFilePath = Bundle.main.path(forResource: fileName, ofType: "") {
                    var cssString = try String(contentsOfFile: filePath)

                    let scale = Preference.shared.webViewFontScale * 0.1 + 1.05
                    for tag in HTMLTag.allValues {
                        let fontpx = scale * Float(tag.fontSize)
                        cssString = cssString.replacingOccurrences(of: tag.key, with: "\(fontpx)px")
                    }
                    let themeCssString = try String(contentsOfFile: themeFilePath)
                    cssString += themeCssString
                    let head = "<head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\"><style>\(cssString)</style></head>"
                    let body = "<body><div id=\"Wrapper\">\(topic.content)</div></body>"
                    let html = "<html>\(head)\(body)</html>"
                    
                    webView.loadHTMLString(html, baseURL: URL(string: "https://"))
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            } catch {
                HUD.showTest(error.localizedDescription)
                log.error("CSS 加载失败")
            }
            
            guard let node = topic.node else { return }
            nodeLabel.text = node.title
            nodeLabel.isHidden = node.title.isEmpty
        }
    }
    
    @objc func base64Decode() {
        webView.evaluateJavaScript("window.getSelection().toString();") { res, err in
            if let error = err {
                HUD.showError(error)
            }
            guard let selectionText = (res as? String)?.trimmed else { return }
            
            let matchResult = selectionText.isMatch(regEx: "(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)")
            guard matchResult else {
                HUD.showError("所选内容不是 Base64")
                return
            }
            
            guard let base64Data = Data(base64Encoded: selectionText),
                let result = String(data: base64Data, encoding: .utf8) else {
                    HUD.showError("解码失败")
                    return
            }
            
            let alertC = UIAlertController(title: "Base64 解码结果", message: result, preferredStyle: .alert)
            alertC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alertC.addAction(UIAlertAction(title: "复制", style: .default, handler: { action in
                UIPasteboard.general.string = result
                HUD.showSuccess("已复制到剪切板")
            }))
            AppWindow.shared.window.rootViewController?.show(alertC, sender: nil)
        }
    }

    var replyTitle: String = "全部回复" {
        didSet {
            replyLabel.text = replyTitle
        }
    }
}

extension TopicDetailHeaderView: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // 定位到因 YYText 的 bug, 链接长按事件, 会导致白屏, 禁止链接 Touch Callout 事件
        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';")
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, error in
            guard let htmlHeight = result as? CGFloat else { return }
            self?.htmlHeight = htmlHeight
        }
        let script = """
            var imgs = document.getElementsByTagName('img');
            for (var i = 0; i < imgs.length; ++i) {
                var img = imgs[i];
                if (img.parentNode.tagName != "A") {
                    img.onclick = function () {
                        window.location.href = 'v2ex-image:' + this.src;
                    }
                }
            }
            """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == "v2ex-image" {
            let src = url.absoluteString.deleteOccurrences(target: "v2ex-image:")
            tapHandle?(.imageURL(src))
            decisionHandler(.cancel)
            return
        }
        
        guard navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
        }
        
        let urlString = url.absoluteString
        
        log.info(url, urlString)
        
        clickCommentLinkHandle(urlString: urlString)
        
        decisionHandler(.cancel)
    }
}
