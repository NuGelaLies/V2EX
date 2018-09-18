import UIKit
import RxSwift
import RxCocoa
import MobileCoreServices

class ReplyMessageViewController: BaseViewController, TopicService {

    // MARK: - UI
    private lazy var textView: UIPlaceholderTextView = {
        let view = UIPlaceholderTextView()
        view.font = UIFont.systemFont(ofSize: 15)
        view.textContainerInset = UIEdgeInsets(top: 8, left: 14, bottom: 5, right: 14)
        view.enablesReturnKeyAutomatically = true
        view.tintColor = Theme.Color.globalColor
        view.backgroundColor = .white
//        view.delegate = self
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

    private var tapOutsideRecognizer: UITapGestureRecognizer!

    
    // MARK: - Propertys

    public var message: MessageModel? {
        didSet {
            guard let username = message?.member?.username else { return }
            let text = "正在回复 \(username)"
            title = text
            textView.placeholder = text as NSString
            textView.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (self.tapOutsideRecognizer == nil) {
            self.tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapBehind))
            self.tapOutsideRecognizer.numberOfTapsRequired = 1
            self.tapOutsideRecognizer.cancelsTouchesInView = false
            self.tapOutsideRecognizer.delegate = self
            self.view.window?.addGestureRecognizer(self.tapOutsideRecognizer)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if(self.tapOutsideRecognizer != nil) {
            self.view.window?.removeGestureRecognizer(self.tapOutsideRecognizer)
            self.tapOutsideRecognizer = nil
        }
    }
    
    // MARK: - Gesture methods to dismiss this with tap outside
    @objc private func handleTapBehind(sender: UITapGestureRecognizer) {
        if (sender.state == UIGestureRecognizer.State.ended) {
            let location: CGPoint = sender.location(in: self.view)
            
            if (!self.view.point(inside: location, with: nil)) {
                self.view.window?.removeGestureRecognizer(sender)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Setup

    override func setupSubviews() {
        view.addSubviews(textView)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, action: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        })
        
        let replyItem = UIBarButtonItem(image: #imageLiteral(resourceName: "message_send"), style: .plain, action: { [weak self] in
            self?.replyComment()
        })
        navigationItem.rightBarButtonItem = replyItem
//            UIBarButtonItem(image: #imageLiteral(resourceName: "uploadPicture"), style: .plain, action: { [weak self] in
//                guard let `self` = self else { return }
//                self.present(self.imagePicker, animated: true, completion: nil)
//            }),
        
        textView.rx.text.orEmpty
            .map { $0.isEmpty.not }
            .bind(to: replyItem.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }

    override func setupConstraints() {
        textView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
                self?.textView.text = nil
                self?.dismiss(animated: true, completion: nil)
        }) { error in
            HUD.dismiss()
            HUD.showError(error)
        }
    }
}


// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ReplyMessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        guard var image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        image = image.resized(by: 0.7)
        guard let data = image.jpegData(compressionQuality: 0.5) else { return }

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

extension ReplyMessageViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //    return self.presentedViewController == nil
        return true
    }
    
}
