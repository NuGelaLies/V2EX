import UIKit
import RxSwift
import RxCocoa
import PasswordExtension
import WebKit
import Kanna

class LoginViewController: BaseViewController, AccountService, TopicService, OCRService {
    
    // MARK: - UI
    
    private lazy var logoView: UIImageView = {
        let view = UIImageView(image: #imageLiteral(resourceName: "site_logo"))
        //        view.contentMode = .center
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var introLabel: UILabel = {
        let view = UILabel()
        view.text = "Way to explore"
        return view
    }()
    
    private lazy var accountTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入用户名或电子邮箱"
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        //        view.setCornerRadius = 5
        view.textColor = Theme.Color.globalColor
        view.font = UIFont.systemFont(ofSize: 16)
        view.addLeftTextPadding(10)
        view.clearButtonMode = .whileEditing
        view.keyboardType = .emailAddress
        view.delegate = self
        view.autocapitalizationType = .none
        view.autocorrectionType = .no
        return view
    }()
    
    private lazy var passwordTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入密码"
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        //        view.setCornerRadius = 5
        view.textColor = Theme.Color.globalColor
        view.font = UIFont.systemFont(ofSize: 16)
        view.addLeftTextPadding(10)
        view.clearButtonMode = .whileEditing
        view.keyboardType = .asciiCapable
        view.isSecureTextEntry = true
        view.delegate = self
        return view
    }()
    
    private lazy var captchaTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入验证码"
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        //        view.setCornerRadius = 5
        view.textColor = Theme.Color.globalColor
        view.font = UIFont.systemFont(ofSize: 16)
        view.addLeftTextPadding(10)
        view.clearButtonMode = .whileEditing
        view.keyboardType = .asciiCapable
        view.delegate = self
        view.returnKeyType = .go
        view.autocapitalizationType = .none
        return view
    }()
    
    private lazy var captchaBtn: LoadingButton = {
        let view = LoadingButton()
        view.setTitle("重新加载验证码", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setTitleColor(Theme.Color.globalColor, for: .normal)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        return view
    }()
    
    private lazy var loginBtn: UIButton = {
        let view = UIButton()
        view.setTitle("登录", for: .normal)
        view.backgroundColor = Theme.Color.globalColor
        view.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        //        view.setCornerRadius = 5
        return view
    }()
    
    private lazy var forgetBtn: UIButton = {
        let view = UIButton()
        view.setTitle("忘记密码?", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return view
    }()
    
    private lazy var registerBtn: UIButton = {
        let view = UIButton()
        view.setTitle("创建一个新账号", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return view
    }()
    
    private lazy var googleLoginBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "googleLogin"), for: .normal)
        view.setImage(#imageLiteral(resourceName: "googleLogin"), for: .selected)
        view.backgroundColor = Theme.Color.globalColor.withAlphaComponent(0.8)
        view.setTitle("    Sign in with Google", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }()
    
    private lazy var onePasswordBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "onepassword-button-light"), for: .normal)
        view.setImage(#imageLiteral(resourceName: "onepassword-button-light"), for: .selected)
        view.sizeToFit()
        view.width = 50
        return view
    }()
    
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.style = .white
        activityIndicator.color = .gray
        return activityIndicator
    }()
    
    // MARK: - Propertys
    
    private var loginForm: LoginForm?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchCode()
        
        if #available(iOS 11.0, *) {
            accountTextField.textContentType = .username
            passwordTextField.textContentType = .password
        }
        
        let isFirstOpen = UserDefaults.get(forKey: self.className) as? Bool ?? false
        if !isFirstOpen {
            UserDefaults.save(at: true, forKey: self.className)
            HUD.showInfo("""
                        验证码自动识别中，如识别失败或结果不准确，可通过摇一摇（或点击验证码图片）重新识别。如多次不准确，建议您手动输入。
                        """, duration: 7)
        }
        
        guard PasswordExtension.shared.isAvailable() else { return }
        
        accountTextField.rightView = onePasswordBtn
        accountTextField.rightViewMode = .always
        
        onePasswordBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.findOnePassword()
            }.disposed(by: rx.disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isTranslucent = true
        //        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        //        navigationController?.navigationBar.shadowImage = UIImage()
        navBarBgAlpha = 0
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // TODO: 清除 UserAgent , 会导致打开网页是pc版
        //        let dictionaty = ["UserAgent" : "Mozilla/5.0 (iPhone; CPU iPhone OS 10_2_1 like Mac OS X) AppleWebKit/602.4.6 (KHTML, like Gecko) Version/10.0 Mobile/14D27 Safari/602.1"]
        //        UserDefaults.standard.register(defaults: dictionaty)
    }
    
    // MARK: - Setup
    
    override func setupTheme() {
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.view.backgroundColor = theme == .day ? UIColor(patternImage: #imageLiteral(resourceName: "bj")) : theme.bgColor
            }.disposed(by: rx.disposeBag)
    }
    
    override func setupSubviews() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close"), style: .plain) { [weak self] in
            self?.dismiss()
        }
        
        view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "bj"))
        
        view.addSubviews(
            blurView,
            logoView,
            introLabel,
            accountTextField,
            passwordTextField,
            captchaTextField,
            captchaBtn,
            loginBtn,
            registerBtn,
            forgetBtn,
            googleLoginBtn
        )
        
        captchaTextField.addSubview(activityIndicatorView)
    }
    
    override func setupConstraints() {
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        logoView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(view.height * 0.16)
        }
        
        introLabel.snp.makeConstraints {
            $0.top.equalTo(logoView.snp.bottom).offset(5)
            $0.centerX.equalToSuperview()
        }
        
        accountTextField.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.top.equalToSuperview().offset(view.height * 0.36)
            //            $0.top.equalTo(introLabel.snp.bottom).offset(120)
        }
        
        passwordTextField.snp.makeConstraints {
            $0.left.right.height.equalTo(accountTextField)
            $0.top.equalTo(accountTextField.snp.bottom).offset(1)
        }
        
        captchaTextField.snp.makeConstraints {
            $0.left.height.equalTo(accountTextField)
            $0.right.equalTo(captchaBtn.snp.left)
            $0.top.equalTo(passwordTextField.snp.bottom).offset(1)
        }
        
        activityIndicatorView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(5)
        }
        
        captchaBtn.snp.makeConstraints {
            $0.top.bottom.equalTo(captchaTextField)
            $0.right.equalTo(accountTextField)
            $0.width.equalTo(164)
        }
        
        loginBtn.snp.makeConstraints {
            $0.left.right.height.equalTo(accountTextField)
            $0.top.equalTo(captchaTextField.snp.bottom).offset(20)
        }
        
        forgetBtn.snp.makeConstraints {
            $0.top.equalTo(googleLoginBtn.snp.bottom).offset(8)
            $0.left.equalTo(loginBtn)
        }
        
        registerBtn.snp.makeConstraints {
            $0.top.equalTo(forgetBtn)
            $0.right.equalTo(loginBtn)
        }
        
        googleLoginBtn.snp.makeConstraints {
            $0.left.right.height.equalTo(loginBtn)
            $0.top.equalTo(loginBtn.snp.bottom).offset(10)
        }
    }
    
    override func setupRx() {
        
        // 获得焦点
        Observable.just(UserDefaults.get(forKey: Constants.Keys.loginAccount))
            .map { $0 as? String}
            .doOnNext({ [weak self] text in
                _ = text.isNilOrEmpty ?
                    self?.accountTextField.becomeFirstResponder() :
                    self?.passwordTextField.becomeFirstResponder()
            })
            .bind(to: accountTextField.rx.text)
            .disposed(by: rx.disposeBag)
        
        // 上次登录成功的账号名
        if let loginName = UserDefaults.get(forKey: Constants.Keys.loginAccount) as? String {
            accountTextField.text = loginName
            accountTextField.rx.value.onNext(loginName)
        }
        
        // 验证输入状态
        let accountTextFieldUsable = accountTextField.rx
            .text
            .orEmpty
            .flatMapLatest {
                return Observable.just( $0.isNotEmpty )
        }
        
        let passwordTextFieldUsable = passwordTextField.rx
            .text
            .orEmpty
            .flatMapLatest {
                return Observable.just( $0.isNotEmpty )
        }
        
        let captchaTextFieldUsable = captchaTextField.rx
            .text
            .orEmpty
            .flatMapLatest {
                return Observable.just( $0.isNotEmpty )
        }
        
        Observable.combineLatest(
            accountTextFieldUsable,
            passwordTextFieldUsable,
            captchaTextFieldUsable) { $0 && $1 && $2}
            .distinctUntilChanged()
            .share(replay: 1)
            .bind(to: loginBtn.rx.isEnableAlpha)
            .disposed(by: rx.disposeBag)
        
        // 点击处理
        loginBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.loginHandle()
            }.disposed(by: rx.disposeBag)
        
        captchaBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.fetchCode()
            }.disposed(by: rx.disposeBag)
        
        forgetBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
            }.disposed(by: rx.disposeBag)
        
        registerBtn.rx
            .tap
            .subscribeNext { [weak self] in
                // Optimize: - 获取网页内容, 判断如果登录成功dismiss, 并记录用户信息
                self?.navBarBgAlpha = 1
                let webView = SweetWebViewController()
                webView.url = API.signup(dict: [:]).url
                self?.navigationController?.pushViewController(webView, animated: true)
                //                self?.navigationController?.pushViewController(RegisterViewController(), animated: true)
                
            }.disposed(by: rx.disposeBag)
        
        googleLoginBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.googleLoginHandle()
            }.disposed(by: rx.disposeBag)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - Action
extension LoginViewController {
    
    /// 获取第三方密码工具的账号信息
    private func findOnePassword() {
        PasswordExtension.shared.findLoginDetails(
            for: Constants.Config.baseURL.lastPathComponent,
            viewController: self,
            sender: onePasswordBtn) { [weak self] detail, error in
                guard let detail = detail else { return }
                
                self?.accountTextField.text = detail.username
                self?.passwordTextField.text = detail.password
                
                // Rx 主动发送事件
                self?.accountTextField.becomeFirstResponder()
                self?.passwordTextField.becomeFirstResponder()
                
                // 如果填写了验证码 直接登录
                if (self?.captchaTextField.text ?? "").count >= 4 {
                    self?.loginHandle()
                } else {
                    self?.captchaTextField.becomeFirstResponder()
                }
                return
        }
    }
    
    /// Google 登录
    private func googleLoginHandle() {
        
        guard let once = AccountModel.getOnce() else {
            HUD.showError("无法获取 once")
            return
        }
        
        HUD.showInfo(
            """
            请确保能正常访问 Google
            如没有自动跳转到 Google 登录页面，请手动点击 "Sign in with Google"
            输入完账号密码后请勿关闭网页, 加载成功后会自动关闭
            """,
            duration: 5.5)
        
        let dictionaty = ["UserAgent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.91 Safari/537.36"]
        UserDefaults.standard.register(defaults: dictionaty)
        
        navBarBgAlpha = 1
        let webViewVC = SweetWebViewController()
        webViewVC.url = URL(string: API.googleSignin(once: once).defaultURLString)
        webViewVC.webViewdidFinish = { [weak self] webView, url in
            log.info("webView.webViewdidFinish url", url)
            
            guard ["https://www.v2ex.com/#", "https://www.v2ex.com/"].contains(url.absoluteString) else { return }
            
            self?.analysisLoginResult(webView)
        }
        navigationController?.pushViewController(webViewVC, animated: true)
    }
    
    private func analysisLoginResult(_ webView: WKWebView) {
        
        // Google 登录后，本地 Cookie 时有时无，所以直接获取 Cookie 手动存储
        webView.evaluateJavaScript("document.cookie") { cookie, error in
            guard let `cookie` = cookie as? String else { return }
            let cookieString = cookie.components(separatedBy: ";").filter { $0.trimmed.hasPrefix("A2") }.first
            guard let a2CookieStr = cookieString else { return }
            let a2Cookie = a2CookieStr.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
            guard let key = a2Cookie.first,
                let value = a2Cookie.last else { return }
            
            // 过期时间1年
            let expires: TimeInterval = 60 * 60 * 24 * 365
            let properties: [HTTPCookiePropertyKey: Any] = [
                .path: "/",
                .name: String(key).trimmed,
                .value: String(value).trimmed,
                .domain: ".v2ex.com",
                .expires: Date(timeIntervalSinceNow: expires),
                .version: 0
            ]
            guard let httpCookie = HTTPCookie(properties: properties) else { return }
            HTTPCookieStorage.shared.setCookie(httpCookie)
        }
        
        webView.evaluateJavaScript("document.body.outerHTML") { [weak self] html, error in
            guard let `self` = self else { return }
            if let error = error {
                log.error(error)
                return
            }
            
            guard let htmlString = html as? String,
                let html = try? HTML(html: htmlString, encoding: .utf8),
                let innerHTML = html.innerHTML else {
                    HUD.showError("登录失败, 请尝试重启 App")
                    return
            }
            
            guard innerHTML.contains("notifications") else {
                HUD.showError("登录失败, 请重试")
                return
            }
            self.accountParse(html)
        }
    }
    
    /// 解析账号
    private func accountParse(_ html: HTMLDocument) {
        if let avatarNode = html.xpath("//*[@id='Rightbar']/div[2]/div[1]/table[1]/tbody/tr/td/a[1]/img[1]").first,
            
            let avatarPath = avatarNode["src"],
            let href = avatarNode.parent?["href"] {
            let username = href.lastPathComponent
            AccountModel(username: username, url: href, avatar: avatarPath).save()
            NotificationCenter.default.post(.init(name: Notification.Name.V2.LoginSuccessName))
            self.dismiss()
        } else {
            HUD.showError("登录失败, 请重试")
        }
    }
    
    /// 获取验证码
    @objc func fetchCode() {
        captchaBtn.isLoading = true
        captchaBtn.setImage(UIImage(), for: .normal)
        
        captcha(type: .signin,
                success: { [weak self] loginForm in
                    self?.captchaBtn.setImage(UIImage(data: loginForm.captchaImageData), for: .normal)
                    self?.loginForm = loginForm
                    self?.captchaBtn.isLoading = false
                    
//                    GCD.runOnBackgroundThread {
//                        self?.ocrRecognize()
//                    }
        }) { [weak self] error in
            self?.captchaBtn.isLoading = false
            HUD.showError(error)
        }
    }
    
    /// OCR 识别
    ///
    /// - Parameter updateCaptchaImg: 是否更新当前验证码的图片
    private func ocrRecognize(updateCaptchaImg: Bool = false) {
        
        guard let once = loginForm?.once,
            let url = API.captchaImageData(once: once).url
            else { return }
        
        GCD.runOnMainThread {
            self.captchaTextField.text = nil
            self.activityIndicatorView.startAnimating()
        }
        
        let returnHandle: Action = {
            GCD.runOnMainThread {
                self.activityIndicatorView.stopAnimating()
                return
            }
        }
        
        // 获取多张图片
        var imgs: [UIImage] = []
        for index in 0...12 {
            guard let data = try? Data(contentsOf: url),
                let img = UIImage(data: data) else { continue }
            
            if index == 0 {
                GCD.runOnMainThread {
                    // 更新当前验证码图片
                    if updateCaptchaImg {
                        self.captchaBtn.setImage(UIImage(data: data), for: .normal)
                    } else if let currentCaptchaImg = self.captchaBtn.currentImage {
                        // 加入当前显示的图片
                        imgs.append(currentCaptchaImg)
                    }
                }
            }
            imgs.append(img)
        }
        
        let imgW = 200
        let imgH = 50
        
        // 将多张图片绘制成一张图片
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imgW, height: imgH * imgs.count), false, UIScreen.main.scale);
        for (index, img) in imgs.enumerated() {
            let y = index * imgH
            img.draw(in: CGRect(x: 0, y: y, width: imgW, height: imgH))
        }
        let bigImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let captchaImg = bigImage,
            let captchaImgData = captchaImg.pngData() else { returnHandle(); return  }
        
        //        UIImageWriteToSavedPhotosAlbum(captchaImg, nil, nil, nil)
        
        // 将绘制成的图片调用接口进行识别
        recognize(imgBase64: captchaImgData.base64EncodedString(), success: { [weak self] captcha in
            GCD.runOnMainThread {
                self?.captchaTextField.text = captcha
                self?.captchaTextField.sendActions(for: .valueChanged)
                self?.activityIndicatorView.stopAnimating()
            }
        }) { [weak self] error in
            GCD.runOnMainThread {
                HUD.showError(error)
                log.error(error)
                self?.activityIndicatorView.stopAnimating()
            }
        }
    }
    
    /// 登录处理
    private func loginHandle() {
        view.endEditing(true)
        
        guard var form = loginForm else {
            HUD.showError("登录失败, 无法获取表单数据, 请尝试重启 App", duration: 1.5)
            return
        }
        
        guard let username = accountTextField.text?.trimmed, username.isNotEmpty else {
            HUD.showError("请正确输入用户名或邮箱", duration: 1.5)
            return
        }
        
        guard let password = passwordTextField.text?.trimmed, password.isNotEmpty else {
            HUD.showError("请输入用户名或邮箱密码", duration: 1.5)
            return
        }
        guard let captcha = captchaTextField.text?.trimmed, captcha.isNotEmpty else {
            HUD.showError("请输入验证码", duration: 1.5)
            return
        }
        
        HUD.show()
        
        form.username = username
        form.password = password
        form.captcha = captcha
        signin(loginForm: form, success: { [weak self] in
            HUD.dismiss()
            NotificationCenter.default.post(.init(name: Notification.Name.V2.LoginSuccessName))
            
            AnswersEvents.logLogin(for: .app)
            self?.dismiss()
        }) { [weak self] error, form, is2Fa in
            HUD.dismiss()
            
            // 两步验证
            if is2Fa {
                AccountModel(username: username, url: API.memberHome(username: username).path, avatar: "").save()
                let twoSetpV = TwoStepVerificationViewController()
                self?.navigationController?.pushViewController(twoSetpV, animated: true)
                return
            }
            HUD.showError(error)
            self?.captchaTextField.becomeFirstResponder()
            self?.captchaTextField.text = ""
            if let `form` = form {
                //                self?.captchaBtn.setImage(UIImage(data: form.captchaImageData), for: .normal)
                self?.loginForm = form
                self?.ocrRecognize(updateCaptchaImg: true)
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        switch textField {
        case accountTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            if let captcha = captchaTextField.text, captcha.isV2EXCaptcha() {
                loginHandle()
            } else {
                captchaTextField.becomeFirstResponder()
            }
        default:
            loginHandle()
            return true
        }
        return false
    }
}


extension LoginViewController {
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        
        ocrRecognize(updateCaptchaImg: true)
    }
}

