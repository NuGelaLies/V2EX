import UIKit
import NSObject_Rx
import RxSwift
import RxCocoa
import UIView_Positioning

class ForgotPasswordViewController: BaseViewController, AccountService {

    // MARK: UI

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = "通过电子邮件重设密码"
        view.font = UIFont.boldSystemFont(ofSize: 25)
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.text = "24 小时内，至多可以重新设置密码 2 次。"
        view.textColor = UIColor.black.withAlphaComponent(0.7)
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()

    private lazy var accountTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入用户名"
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        //        view.setCornerRadius = 5
        view.textColor = Theme.Color.globalColor
        view.font = UIFont.systemFont(ofSize: 16)
        view.addLeftTextPadding(10)
        view.clearButtonMode = .whileEditing
        view.keyboardType = .asciiCapable
        view.delegate = self
        return view
    }()

    private lazy var emailTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "请输入注册时的电子邮箱"
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        //        view.setCornerRadius = 5
        view.textColor = Theme.Color.globalColor
        view.font = UIFont.systemFont(ofSize: 16)
        view.addLeftTextPadding(10)
        view.clearButtonMode = .whileEditing
        view.keyboardType = .emailAddress
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
        view.rightView = self.captchaBtn
        view.rightViewMode = .always
        view.keyboardType = .asciiCapable
        view.delegate = self
        view.returnKeyType = .go
        return view
    }()

    private lazy var captchaBtn: LoadingButton = {
        let view = LoadingButton()
        view.size = CGSize(width: 150, height: 50)
        view.setTitle("重新加载验证码", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setTitleColor(Theme.Color.globalColor, for: .normal)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        return view
    }()

    private lazy var nextBtn: UIButton = {
        let view = UIButton()
        view.setTitle("下一步", for: .normal)
        view.backgroundColor = Theme.Color.globalColor
        //        view.setCornerRadius = 5
        return view
    }()

    // MARK: - Propertys
    private var forgotForm: LoginForm?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchCode()

        // TODO: 优化
        // 点击忘记密码，用户名直接获取登录时输入的用户名（如果有）
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navBarBgAlpha = 0
    }

    // MARK: - Setup
    override func setupTheme() {
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.view.backgroundColor = theme == .day ? UIColor(patternImage: #imageLiteral(resourceName: "bj")) : theme.bgColor
            }.disposed(by: rx.disposeBag)
    }

    override func setupSubviews() {
        view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "bj"))

        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = CGSize(width: view.frame.width, height: view.frame.height)

        view.addSubviews(
            blurView,
            titleLabel,
            subtitleLabel,
            accountTextField,
            emailTextField,
            captchaTextField,
            nextBtn
        )
    }

    override func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(view.height * 0.2)
        }

        subtitleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
        }

        accountTextField.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.top.equalToSuperview().offset(view.height * 0.4)
            //            $0.top.equalTo(introLabel.snp.bottom).offset(120)
        }

        emailTextField.snp.makeConstraints {
            $0.left.right.height.equalTo(accountTextField)
            $0.top.equalTo(accountTextField.snp.bottom).offset(20)
        }

        captchaTextField.snp.makeConstraints {
            $0.left.right.height.equalTo(accountTextField)
            $0.top.equalTo(emailTextField.snp.bottom).offset(20)
        }

        nextBtn.snp.makeConstraints {
            $0.left.right.height.equalTo(accountTextField)
            $0.top.equalTo(captchaTextField.snp.bottom).offset(30)
        }
    }

    override func setupRx() {

        // 验证输入状态
        let accountTextFieldUsable = accountTextField.rx
            .text
            .orEmpty
            .flatMapLatest {
                return Observable.just( $0.isNotEmpty )
        }

        let emailTextFieldUsable = emailTextField.rx
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
            emailTextFieldUsable,
            captchaTextFieldUsable) { $0 && $1 && $2}
            .distinctUntilChanged()
            .share(replay: 1)
            .bind(to: nextBtn.rx.isEnableAlpha)
            .disposed(by: rx.disposeBag)

        captchaBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.fetchCode()
            }.disposed(by: rx.disposeBag)

        nextBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.nextHandle()
            }.disposed(by: rx.disposeBag)
    }
}

// MARK: - Actions
extension ForgotPasswordViewController {

    /// 找回密码
    func nextHandle() {
        view.endEditing(true)

        guard var form = forgotForm else {
            HUD.showError("无法获取表单数据, 请尝试重启 App", duration: 1.5)
            return
        }

        guard let username = accountTextField.text?.trimmed, username.isNotEmpty else {
            HUD.showError("请正确输入用户名", duration: 1.5)
            return
        }

        guard let email = emailTextField.text?.trimmed, email.isNotEmpty, email.isEmail() else {
            HUD.showError("请正确输入电子邮箱", duration: 1.5)
            return
        }

        guard let captcha = captchaTextField.text?.trimmed, captcha.isNotEmpty else {
            HUD.showError("请输入验证码", duration: 1.5)
            return
        }

        HUD.show()

        form.username = username
        form.email = email
        form.captcha = captcha

        forgot(forgotForm: form, success: { [weak self] info in
            HUD.dismiss()
            HUD.showSuccess(info, completionBlock: { [weak self] in
                self?.dismiss()
            })
        }) { [weak self] error, form in
            HUD.dismiss()
            HUD.showError(error)

            if let `form` = form {
                self?.captchaBtn.setImage(UIImage(data: form.captchaImageData), for: .normal)
                self?.forgotForm = form
            }
        }
    }

    /// 获取验证码
    @objc func fetchCode() {
        captchaBtn.isLoading = true
        captchaBtn.setImage(UIImage(), for: .normal)

        captcha(type: .forgot,
                success: { [weak self] forgotForm in
                    self?.captchaBtn.setImage(UIImage(data: forgotForm.captchaImageData), for: .normal)
                    self?.forgotForm = forgotForm
                    self?.captchaBtn.isLoading = false
        }) { [weak self] error in
            self?.captchaBtn.isLoading = false
            HUD.showError(error)
        }
    }
}

// MARK: - UITextFieldDelegate
extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        switch textField {
        case accountTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            captchaTextField.becomeFirstResponder()
        default:
            nextHandle()
            return true
        }

        return false
    }
}

