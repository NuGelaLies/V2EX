import UIKit
import RxSwift
import RxCocoa
import MobileCoreServices
import SnapKit
import YYText

class CreateTopicViewController: BaseViewController, TopicService {
    
    // MARK: Constants
    fileprivate struct Limit {
        static let titleMaxCharacter = 120
        static let bodyMaxCharacter = 20000
    }

    // MARK: - UI

    private lazy var titleLabel: UILabel = {
        let view = UIInsetLabel()
        view.text = "主题标题"
        view.contentInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        view.textAlignment = .left
        view.backgroundColor = .white
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()
    
    private lazy var titleFieldView: UITextField = {
        let view = UITextField()
        view.addLeftTextPadding(15)
        view.font = UIFont.systemFont(ofSize: 15)
        view.backgroundColor = .white
        view.attributedPlaceholder = NSAttributedString(
            string: "请输入主题标题(0~120)",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.6)]
        )
        return view
    }()
    
    private lazy var bodyLabel: UIInsetLabel = {
        let view = UIInsetLabel()
        view.text = "正文"
        view.contentInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        view.textAlignment = .left
        view.backgroundColor = .white
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()

    private lazy var markdownToolbar: MarkdownInputAccessoryView = {
        let view = MarkdownInputAccessoryView()
        return view
    }()

    private lazy var markdownParser: YYTextSimpleMarkdownParser = {
        let view = YYTextSimpleMarkdownParser()
        return view
    }()

    private lazy var bodyTextView: YYTextView = {
        let view = YYTextView()
        view.placeholderAttributedText = NSAttributedString(
            string: "请输入正文，如果标题能够表达完整内容，则正文可以为空(0~20000)",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.6),
                         NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
        view.textContainerInset = UIEdgeInsets(top: 10, left: 15, bottom: 15, right: 5)
        view.returnKeyType = .done
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.systemFont(ofSize: 15)
        view.keyboardDismissMode = .onDrag
        view.textParser = markdownParser
        view.isEditable = true
        view.delegate = self
        view.inputAccessoryView = markdownToolbar
        return view
    }()
    
    private lazy var postTopicBarButton: UIBarButtonItem = {
        let view = UIBarButtonItem(title: "发布")
        return view
    }()

    private lazy var previewBarButton: UIBarButtonItem = {
        let view = UIBarButtonItem(title: "预览")
        return view
    }()

    private lazy var imagePicker: UIImagePickerController = {
        let view = UIImagePickerController()
        view.mediaTypes = [kUTTypeImage as String]
        view.sourceType = .photoLibrary
        view.delegate = self
        return view
    }()

    private lazy var selectNodeBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "selectNode"), for: .normal)
        view.setImage(#imageLiteral(resourceName: "selectNode"), for: .selected)
        view.setTitle("选择节点", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        view.setTitleColor(.black, for: .normal)
        view.sizeToFit()
        view.backgroundColor = .white
        view.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        view.setCornerRadius = 15
        view.layer.borderColor = Theme.Color.globalColor.cgColor
        view.layer.borderWidth = 0.5
        return view
    }()

    // MARK: - Propertys

    public var node: NodeModel? {
        didSet {
            guard let `node` = node else { return }
            selectNodeBtn.setTitle("  " + node.title, for: .normal)
        }
    }

    private var selectNodeBtnBottomConstranit: Constraint?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "创建新主题"
        titleFieldView.becomeFirstResponder()

        /// 恢复草稿
        if let title = UserDefaults.get(forKey: Constants.Keys.createTopicTitleDraft) as? String {
            titleFieldView.text = title
            titleFieldView.rx.value.onNext(title)
        }

        if let body = UserDefaults.get(forKey: Constants.Keys.createTopicBodyDraft) as? String {
            bodyTextView.text = body
//            bodyTextView.rx.value.onNext(body)
        }

        if self.node == nil, let `node` = NodeModel.getDraft() {
            self.node = node
        }

        markdownToolbar.didSelectedItemHandle = { [weak self] type in
            self?.toolbarClickHandle(type)
        }

        EULAHandle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectNodeBtnBottomConstranit?.update(offset: -20)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    deinit {
        UserDefaults.save(at: titleFieldView.text, forKey: Constants.Keys.createTopicTitleDraft)
        UserDefaults.save(at: bodyTextView.text, forKey: Constants.Keys.createTopicBodyDraft)

        if titleFieldView.text.isNotNilNotEmpty || bodyTextView.text.isNotEmpty,
            let `node` = node {
            NodeModel.saveDraft(node)
        }

        log.verbose("DEINIT: \(className)")
    }

    // MARK: - Setup

    override func setupSubviews() {
        view.addSubviews(
            titleLabel,
            titleFieldView,
            bodyLabel,
            bodyTextView,
            selectNodeBtn
        )
        navigationItem.rightBarButtonItems = [postTopicBarButton, previewBarButton]
    }

    override func setupConstraints() {
        titleLabel.snp.makeConstraints {
            if #available(iOS 11.0, *) {
                $0.top.equalTo(view.safeAreaInsets.top)
            } else {
                $0.top.equalTo(self.topLayoutGuide.snp.bottom)
            }
            $0.left.right.equalToSuperview()
            $0.height.equalTo(40)
        }
        
        titleFieldView.snp.makeConstraints {
            $0.left.right.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(0.5)
            $0.height.equalTo(50)
        }
        
        bodyLabel.snp.makeConstraints {
            $0.left.right.height.equalTo(titleLabel)
            $0.top.equalTo(titleFieldView.snp.bottom).offset(0.5)
        }
        
        bodyTextView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(bodyLabel.snp.bottom).offset(0.5)
        }

        selectNodeBtn.snp.makeConstraints {
            $0.left.equalToSuperview().inset(20)
            selectNodeBtnBottomConstranit = $0.bottom.equalToSuperview().inset(20).constraint
        }
    }

    override func setupRx() {
        
        // 验证输入状态
        titleFieldView.rx
            .text
            .orEmpty
            .flatMapLatest {
                return Observable.just( $0.trimmed.isNotEmpty && $0.trimmed.count <= Limit.titleMaxCharacter )
            }.bind(to: postTopicBarButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)

//        bodyTextView.rx
//            .text
//            .orEmpty
//            .map { $0.trimmed.isNotEmpty }
//            .bind(to: previewBarButton.rx.isEnabled)
//            .disposed(by: rx.disposeBag)

        postTopicBarButton.rx
            .tap
            .subscribeNext { [weak self] in
                self?.postTopicHandle()
            }.disposed(by: rx.disposeBag)

        selectNodeBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.selectNodeHandle()
        }.disposed(by: rx.disposeBag)


        previewBarButton.rx
            .tap
            .subscribeNext { [weak self] in
                guard let markdownString = self?.bodyTextView.text else {
                    HUD.showError("预览失败，无法读取到正文内容")
                    return
                }
                let previewVC = MarkdownPreviewViewController(markdownString: markdownString)
                let nav = NavigationViewController(rootViewController: previewVC)
                self?.present(nav, animated: true, completion: nil)
            }.disposed(by: rx.disposeBag)

        Observable.of(NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification),
                      NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification),
                      NotificationCenter.default.rx.notification(UIResponder.keyboardDidHideNotification)).merge()
            .subscribeNext { [weak self] notification in
                guard let `self` = self else { return }
                guard var userInfo = notification.userInfo,
                    let keyboardRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                let convertedFrame = self.view.convert(keyboardRect, from: nil)
                let heightOffset = self.view.bounds.size.height - convertedFrame.origin.y
                let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                self.selectNodeBtnBottomConstranit?.update(offset: -(heightOffset + 20))

                UIView.animate(withDuration: duration!) {
                    self.view.layoutIfNeeded()
                }
            }.disposed(by: rx.disposeBag)
    }

    override func setupTheme() {
        super.setupTheme()

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.titleLabel.textColor = theme.titleColor
                self?.bodyLabel.textColor = theme.titleColor
                self?.titleLabel.backgroundColor = theme.whiteColor
                self?.titleFieldView.backgroundColor = theme.whiteColor
                self?.titleFieldView.textColor = theme == .day ? theme.titleColor : .white
                self?.bodyLabel.backgroundColor = theme.whiteColor
                self?.bodyTextView.backgroundColor = theme.whiteColor
                self?.bodyTextView.keyboardAppearance = theme == .day ? .default : .dark
                self?.titleFieldView.keyboardAppearance = theme == .day ? .default : .dark
                self?.selectNodeBtn.setTitleColor(theme.titleColor, for: .normal)
                self?.selectNodeBtn.backgroundColor = theme.whiteColor
                theme == .day ? self?.markdownParser.setColorWithBrightTheme() : self?.markdownParser.setColorWithDarkTheme()
                self?.view.backgroundColor = theme == .day ? theme.borderColor : UIColor.black.withAlphaComponent(0.5)
            }.disposed(by: rx.disposeBag)
    }
}

// MARK: - Actions
extension CreateTopicViewController {

    /// 发布主题
    func postTopicHandle() {

        guard bodyTextView.text.count <= Limit.bodyMaxCharacter else {
            HUD.showError("正文内容不能超过 \(Limit.bodyMaxCharacter) 个字符")
            return
        }
        guard let title = titleFieldView.text else {
            HUD.showError("标题不能为空")
            return
        }

        guard let selectedNodename = node?.name else {
            selectNodeHandle()
            return
        }

        HUD.show()
        let bodyText = bodyTextView.text.replacingOccurrences(of: "\n", with: "<br>").replacingOccurrences(of: "\r", with: "<br>")
        createTopic(nodename: selectedNodename, title: title, body: bodyText, success: { [weak self] in
            HUD.dismiss()
            HUD.showSuccess("发布成功")
            self?.titleFieldView.text = nil
            self?.bodyTextView.text = nil
            self?.node = nil
            UserDefaults.remove(forKey: Constants.Keys.createTopicTitleDraft)
            UserDefaults.remove(forKey: Constants.Keys.createTopicBodyDraft)
            NodeModel.deleteDraft()
            self?.navigationController?.popViewController(animated: true)
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }

    /// 工具栏点击
    private func toolbarClickHandle(_ type: MarkdownItemType) {

        if let mark = type.mark {
            bodyTextView.insertText(mark)
        }

        var range = bodyTextView.selectedRange
        if let location = type.location {
            range.location -= location
        }

        switch type {
        case .closeKeyboard:
            bodyTextView.resignFirstResponder()
        case .undo:
            bodyTextView.undoManager?.undo()
        case .redo:
            bodyTextView.undoManager?.redo()
        case .leftMove:
            range.location -= 1
        case .rightMove:
            range.location += 1
        case .image:
            present(imagePicker, animated: true, completion: nil)
        case .clear:
            bodyTextView.text = nil
        default:
            break
        }
        bodyTextView.selectedRange = range
    }

    // 上传配图请求
    private func uploadPictureHandle(_ fileURL: String) {
        HUD.show()
        uploadPicture(localURL: fileURL, success: { [weak self] url in
            self?.bodyTextView.insertText("![V2er](\(url))")
            self?.bodyTextView.becomeFirstResponder()
            HUD.dismiss()
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }

    /// 选择节点
    private func selectNodeHandle() {

        let allNodeVC = AllNodesViewController()
        allNodeVC.title = "请选择主题节点"
        let nav = NavigationViewController(rootViewController: allNodeVC)
        present(nav, animated: true, completion: nil)

        allNodeVC.didSelectedNodeHandle = { [weak self] node in
            self?.selectNodeBtn.setTitle("  " + node.title, for: .normal)
            self?.node = node
            self?.bodyTextView.becomeFirstResponder()
        }
    }

    /// 遵守社区指导原则 （审核使用）
    private func EULAHandle() {

        if Preference.shared.agreementOfConsent { return }

        let alert = UIAlertController(title: "社区指导原则", message:
            """
            尊重原创
            请不要在 V2EX 发布任何盗版下载链接，包括软件、音乐、电影等等。V2EX 是创意工作者的社区，我们尊重原创。
            禁止发布黄色、暴力内容。
            友好互助
            保持对陌生人的友善。用知识去帮助别人。
            """, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "同意", style: .default, handler: { _ in
            Preference.shared.agreementOfConsent = true
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension CreateTopicViewController: YYTextViewDelegate {
    func textViewDidBeginEditing(_ textView: YYTextView) {
        self.selectNodeBtn.isHidden = true
    }
    
    func textViewDidEndEditing(_ textView: YYTextView) {
        self.selectNodeBtn.isHidden = false
    }
}

extension CreateTopicViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        guard var image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        image = image.resized(by: 0.7)
        guard let data = image.jpegData(compressionQuality: 0.5) else { return }

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
            self.bodyTextView.becomeFirstResponder()
        }
    }
}
