import UIKit
import RxSwift
import RxCocoa
import MobileCoreServices

class ReplyMessageViewController: BaseViewController, TopicService {

    // MARK: - UI

    private lazy var contentView: UIView = {
        let view = UIView()
//        view.setCornerRadius = 15
        return view
    }()

    private lazy var topContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.hex(0xF1F2F1)
        return view
    }()

    private lazy var closeBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "close"), for: .normal)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()

    private lazy var uploadPictureBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "uploadPicture"), for: .normal)
        return view
    }()

    private lazy var sendBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "message_send"), for: .normal)
        return view
    }()

    private lazy var textView: UIPlaceholderTextView = {
        let view = UIPlaceholderTextView()
        view.font = UIFont.systemFont(ofSize: 15)
        view.textContainerInset = UIEdgeInsets(top: 8, left: 14, bottom: 5, right: 14)
        view.enablesReturnKeyAutomatically = true
        view.tintColor = Theme.Color.globalColor
        view.backgroundColor = .white
        view.delegate = self
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        return view
    }()

    private lazy var imagePicker: UIImagePickerController = {
        let view = UIImagePickerController()
        view.allowsEditing = true
        view.mediaTypes = [kUTTypeImage as String]
        view.sourceType = .photoLibrary
        view.delegate = self
        return view
    }()

    // MARK: - Propertys

    public var message: MessageModel? {
        didSet {
            guard let username = message?.member?.username else { return }
            let text = "正在回复 \(username)"
            titleLabel.text = text
            textView.placeholder = text as NSString
            textView.becomeFirstResponder()
        }
    }

    // MARK: - Setup

    override func setupRx() {
        closeBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.textView.resignFirstResponder()
        }.disposed(by: rx.disposeBag)

        uploadPictureBtn.rx
            .tap 
            .subscribeNext { [weak self] in
                guard let `self` = self else { return }
                self.present(self.imagePicker, animated: true, completion: nil)
        }.disposed(by: rx.disposeBag)

        sendBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.replyComment()
        }.disposed(by: rx.disposeBag)
    }

    override func setupSubviews() {
        view.backgroundColor = .clear

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowRadius = 20
        contentView.layer.shadowOpacity = 0.8
        contentView.layer.shadowOffset = CGSize(width: 10, height: 10)

        view.addSubview(contentView)
        contentView.addSubviews(topContainer, textView)
        topContainer.addSubviews(closeBtn, titleLabel, uploadPictureBtn, sendBtn)
    }

    override func setupConstraints() {
        contentView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.height.equalToSuperview().multipliedBy(0.37)
            let margin = navigationController?.navigationBar.bottom ?? 64
            $0.top.equalToSuperview().offset(margin + 20)
        }

        topContainer.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(40)
        }

        closeBtn.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(topContainer.snp.height)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        sendBtn.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview().inset(5)
            $0.width.equalTo(closeBtn)
        }

        uploadPictureBtn.snp.makeConstraints {
            $0.top.bottom.width.equalTo(sendBtn)
            $0.right.equalTo(sendBtn.snp.left)
        }

        textView.snp.makeConstraints {
            $0.top.equalTo(topContainer.snp.bottom)
            $0.left.bottom.right.equalToSuperview()
        }
    }
}

// MARK: - Actions
extension ReplyMessageViewController {

    // 上传配图请求
    private func uploadPictureHandle(_ fileURL: String) {
        HUD.show()
        uploadPicture(localURL: fileURL, success: { [weak self] url in
            log.info(url)
            self?.textView.insertText(url)
            self?.textView.becomeFirstResponder()
            HUD.dismiss()
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }

    /// 回复评论
    private func replyComment() {

        guard let `message` = message, let atUsername = message.member?.atUsername else { return }

        guard textView.text.trimmed.isNotEmpty else {
            HUD.showInfo("回复失败，您还没有输入任何内容", completionBlock: { [weak self] in
                self?.textView.becomeFirstResponder()
            })
            return
        }

        guard let once = message.once else {
            HUD.showError("无法获取 once，请尝试重新登录", completionBlock: {
                presentLoginVC()
            })
            return
        }

        guard let topicID = message.topic.topicID else {
            HUD.showError("无法获取主题 ID")
            return
        }

        HUD.show()
        comment(
            once: once,
            topicID: topicID,
            content: atUsername + textView.text, success: { [weak self] in
                HUD.showSuccess("回复成功")
                HUD.dismiss()
                self?.view.endEditing(true)
                self?.view.fadeOut()
                self?.textView.text = nil
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }
}


// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ReplyMessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        guard var image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        image = image.resized(by: 0.7)
        guard let data = UIImageJPEGRepresentation(image, 0.5) else { return }

        let path = FileManager.document.appendingPathComponent("smfile.png")
        _ = FileManager.save(data, savePath: path)
        uploadPictureHandle(path)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true) {
            self.textView.becomeFirstResponder()
        }
    }
}

// MARK: - UITextViewDelegate
extension ReplyMessageViewController: UITextViewDelegate {

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
        view.fadeOut()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        view.fadeIn()
    }
}
