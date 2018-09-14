import Foundation
import UIKit
import YYText
import SnapKit

let KcommentInputViewHeight: CGFloat = 55

class CommentInputView: UIView {

     public lazy var textView: YYTextView = {
        let view = YYTextView()
        view.placeholderAttributedText = NSAttributedString(
            string: "添加一条新回复",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.6)])

//        view.placeholder = "添加一条新回复"  // 奔溃 。。。
        view.setCornerRadius = 17.5
        view.font = UIFont.systemFont(ofSize: 15)
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.Color.borderColor.cgColor
        view.scrollsToTop = false
        view.textContainerInset = UIEdgeInsets(top: 8, left: 14, bottom: 5, right: 14)
        view.backgroundColor = Theme.Color.bgColor
        view.delegate = self
        view.textParser = MentionedParser()
        view.tintColor = Theme.Color.globalColor
        var contentInset = view.contentInset
        contentInset.right = -35
        view.contentInset = contentInset
        self.addSubview(view)
        return view
    }()

    private lazy var uploadPictureBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "uploadPicture"), for: .normal)
        view.setImage(#imageLiteral(resourceName: "uploadPicture"), for: .selected)
        self.addSubview(view)
        return view
    }()

    private lazy var sendBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "send"), for: .normal)
        view.setImage(#imageLiteral(resourceName: "send"), for: .selected)
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        self.addSubview(view)
        return view
    }()

    public var inputViewHeight: CGFloat {
        if #available(iOS 11.0, *) {
            return KcommentInputViewHeight + AppWindow.shared.window.safeAreaInsets.bottom
        } else {
            return KcommentInputViewHeight
        }
    }

    private struct Misc {
        static let maxHeight = (UIScreen.main.bounds.height / 5).rounded(.down)// 200
        static let textViewContentHeight: CGFloat = KcommentInputViewHeight - 22
    }

    public var sendHandle: Action?
    public var atUserHandle: Action?
    public var uploadPictureHandle: Action?
    public var updateHeightHandle: ((CGFloat) -> Void)?

    private var uploadPictureRightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {

        clipsToBounds = true
        backgroundColor = .white
        
        textView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10).priority(.high)
            $0.right.equalToSuperview().inset(15).priority(.high)
            $0.left.equalTo(uploadPictureBtn.snp.right).inset(-15)

            if #available(iOS 11.0, *) {
                $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(10)
            } else {
                $0.bottom.equalToSuperview().inset(10)
            }
        }

        sendBtn.snp.makeConstraints {
            $0.centerY.size.equalTo(uploadPictureBtn)
            $0.right.equalTo(textView.snp.right).inset(5)
        }

        uploadPictureBtn.snp.makeConstraints {
            uploadPictureRightConstraint = $0.right.equalTo(snp.left).constraint
//            $0.bottom.equalTo(textView.bottom).offset(5)
            if #available(iOS 11.0, *) {
                $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(12.5)
            } else {
                $0.bottom.equalToSuperview().inset(12.5)
            }
            $0.size.equalTo(30)
        }

        uploadPictureBtn.rx
            .tap
            .subscribeNext { [weak self] in
                self?.uploadPictureHandle?()
        }.disposed(by: rx.disposeBag)

        sendBtn.rx
            .tap
            .subscribeNext { [weak self] in
                guard let `self` = self else { return }
                self.sendHandle?()
                self.calculateHeight(defaultHeight: self.inputViewHeight)
            }.disposed(by: rx.disposeBag)

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.backgroundColor = theme.navColor
                self?.borderTop = Border(size: 1 ,color: theme == .day ? theme.borderColor : UIColor.hex(0x19171A))
                self?.textView.backgroundColor = theme.bgColor
                self?.textView.layer.borderColor = (theme == .day ? theme.borderColor : UIColor.hex(0x19171A)).cgColor
                self?.textView.keyboardAppearance = theme == .day ? .default : .dark
                self?.textView.textColor = theme.titleColor
                self?.sendBtn.tintColor = theme == .day ? theme.tintColor : .white
            }.disposed(by: rx.disposeBag)
    }

}

extension CommentInputView: YYTextViewDelegate {

    func textViewShouldBeginEditing(_ textView: YYTextView) -> Bool {

        calculateHeight()

        UIView.animate(withDuration: 1) {
            self.uploadPictureRightConstraint?.update(offset: 45)
            self.uploadPictureBtn.layoutIfNeeded()
        }

        return true
    }

    func textViewShouldEndEditing(_ textView: YYTextView) -> Bool {
        calculateHeight(defaultHeight: inputViewHeight)
        uploadPictureRightConstraint?.update(offset: 0)
        return true
    }

    func textViewDidChange(_ textView: YYTextView) {
        if textView.text.trimmed.isEmpty.boolValue {
            sendBtn.fadeOut(0.2)
        } else if textView.text.trimmed.isNotEmpty.boolValue && sendBtn.alpha < .ulpOfOne {
            self.sendBtn.fadeIn(0.2)
            UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.2, options: .curveLinear, animations: {
                self.sendBtn.transform = .identity
            }, completion: nil)
        }

        calculateHeight()
    }

    func textView(_ textView: YYTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        if text == "@" {
            GCD.delay(0.2, block: {
                self.atUserHandle?()
            })
        }
        return true
    }

    /// 计算文字高度
    ///
    /// - Parameter defaultHeight: 默认的高度
    ///                            针对 iPhone X 做的特殊处理
    ///                            默认55，iPhone X = 55 + safeAreaInsets.bottom
    ///                            编辑时默认高度再次变成 55
    private func calculateHeight(defaultHeight: CGFloat = KcommentInputViewHeight) {
//        guard let lineHeight = textView.font?.lineHeight else { return }
//
//        // 调用代理方法
//        let contentHeight = (textView.contentSize.height - textView.textContainerInset.top - textView.textContainerInset.bottom)
//        let rows =  Int(contentHeight / lineHeight)
//
//        guard rows <= Misc.maxLine else { return }
//
//        var height = Misc.textViewContentHeight * rows.f
//        height = height < defaultHeight ? defaultHeight : height

        let maxTextViewSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        var height = textView.sizeThatFits(maxTextViewSize).height.rounded(.down)
        height = height + textView.textContainerInset.top + textView.textContainerInset.bottom + 8
        height = height < defaultHeight ? defaultHeight : height
        height = height > Misc.maxHeight ? Misc.maxHeight : height
        updateHeightHandle?(height)
    }
}
