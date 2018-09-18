import UIKit
import RxSwift
import RxCocoa

class OCRConfigViewController: BaseViewController {

    struct Misc {
        static let thank = "nannanziyu"
        static let baiduLink = "https://console.bce.baidu.com/ai/#/ai/ocr/overview/index"
    }
    
    
    // MARK: - UI
    
    private lazy var apiKeyTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入 API Key"
        view.backgroundColor = ThemeStyle.style.value.whiteColor
        view.addLeftTextPadding(10)
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var secretKeyField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入 Secret Key"
        view.backgroundColor = ThemeStyle.style.value.whiteColor
        view.addLeftTextPadding(10)
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var stateLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textColor = UIColor.hex(0x666666)//ThemeStyle.style.value.dateColor
        view.font = UIFont.systemFont(ofSize: 13)
        let text = "申请链接 \(Misc.baiduLink)"
        view.text = """
        验证码识别使用 <百度文字识别> 服务每天 500 条免费额度.
        目前已内置一个 API Key，所有 V2er 共享额度，正常使用额度够用.
        但建议您填写成自己的 API Key，该配置仅您自己可用。
        \(text)

        提示: 长按可复制链接
        """
        view.makeSubstringColor(text, color: ThemeStyle.style.value.linkColor)
        view.setLineHeight(8)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var thankLabel: UILabel = {
        let view = UILabel()
        view.text = "致谢 @" + Misc.thank
        view.textColor = ThemeStyle.style.value.titleColor
        view.makeSubstringColor("@" + Misc.thank, color: ThemeStyle.style.value.linkColor)
        view.isUserInteractionEnabled = true
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    private lazy var saveItem: UIBarButtonItem = {
        let view = UIBarButtonItem(barButtonSystemItem: .save)
        return view
    }()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "百度文字识别配置"

        navigationItem.rightBarButtonItem = saveItem
        
        if let appearence = BaiduAppearence.get() {
            apiKeyTextField.text = appearence.appkey
            secretKeyField.text = appearence.secretKey
        } else {
            apiKeyTextField.becomeFirstResponder()
        }
    }
    
    override func setupSubviews() {
        view.addSubviews(apiKeyTextField, secretKeyField, stateLabel, thankLabel)
    }
    
    override func setupConstraints() {
        apiKeyTextField.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.height.equalTo(50)
        }
        
        secretKeyField.snp.makeConstraints{
            $0.left.right.height.equalTo(apiKeyTextField)
            $0.top.equalTo(apiKeyTextField.snp.bottom).offset(0.5)
        }
        
        stateLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(10)
            $0.top.equalTo(secretKeyField.snp.bottom).offset(15)
        }
        
        thankLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            if #available(iOS 11.0, *) {
                $0.bottom.equalTo(view.safeAreaInsets)
            } else {
                $0.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
        }
    }
    
    override func setupRx() {
        let stateTapGesture = UITapGestureRecognizer()
        stateLabel.addGestureRecognizer(stateTapGesture)

        let stateLongPressGesture = UILongPressGestureRecognizer()
        stateLongPressGesture.minimumPressDuration = 0.25
        stateLabel.addGestureRecognizer(stateLongPressGesture)
        
        stateTapGesture.rx
            .event
            .subscribeNext { _ in
                openWebView(url: Misc.baiduLink)
            }.disposed(by: rx.disposeBag)

        stateLongPressGesture.rx
            .event
            .subscribeNext { gesture in
                guard gesture.state == .began else { return }

                UIPasteboard.general.string = Misc.baiduLink
                HUD.showSuccess("链接已复制")
            }.disposed(by: rx.disposeBag)

        let thankTapGesture = UITapGestureRecognizer()
        thankLabel.addGestureRecognizer(thankTapGesture)
        
        thankTapGesture.rx
            .event
            .subscribeNext { [weak self] _ in
                let vc = MemberPageViewController(memberName: Misc.thank)
                self?.navigationController?.pushViewController(vc, animated: true)
            }.disposed(by: rx.disposeBag)
        
        saveItem.rx
            .tap
            .subscribeNext { [weak self] in
                guard let `self` = self,
                let appKey = self.apiKeyTextField.text?.trimmed,
                let secretKey = self.secretKeyField.text?.trimmed else { return }
                
                log.info("AppKey = \(appKey) , secretKey = \(secretKey)")
                
                BaiduAppearence(appkey: appKey, secretKey: secretKey).save()
                BaiduOauthToken.remove()
                HUD.showSuccess("保存成功", duration: 2, completionBlock: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
        }.disposed(by: rx.disposeBag)
        
        // 验证输入状态
        let apiKeyTextFieldUsable = apiKeyTextField.rx
            .text
            .orEmpty
            .flatMapLatest {
                return Observable.just( $0.trimmed.count == Constants.BaiduOCR.appKey.count )
        }
        
        let secretKeyTextFieldUsable = secretKeyField.rx
            .text
            .orEmpty
            .flatMapLatest {
                return Observable.just( $0.trimmed.count == Constants.BaiduOCR.secretKey.count )
        }
        
        Observable.combineLatest(
            apiKeyTextFieldUsable,
            secretKeyTextFieldUsable) { $0 && $1}
            .distinctUntilChanged()
            .share(replay: 1)
            .bind(to: saveItem.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.apiKeyTextField.setValue(theme.dateColor, forKeyPath: "_placeholderLabel.textColor")
                self?.secretKeyField.setValue(theme.dateColor, forKeyPath: "_placeholderLabel.textColor")
                self?.apiKeyTextField.backgroundColor = theme == .day ? theme.whiteColor : theme.cellBackgroundColor
                self?.secretKeyField.backgroundColor = theme == .day ? theme.whiteColor : theme.cellBackgroundColor
                self?.secretKeyField.textColor = theme.titleColor
                self?.apiKeyTextField.textColor = theme.titleColor
        }.disposed(by: rx.disposeBag)
    }

}
