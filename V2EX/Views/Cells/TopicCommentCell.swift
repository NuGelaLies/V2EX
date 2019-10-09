import UIKit
import SnapKit
import YYText

class TopicCommentCell: BaseTableViewCell {

    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.setCornerRadius = 5
        return view
    }()

    private lazy var usernameLaebl: UILabel = {
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

    private lazy var floorLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 11)
        view.textColor = UIColor.hex(0xCCCCCC)
        return view
    }()

    private lazy var hostLabel: UIInsetLabel = {
        let view = UIInsetLabel()
        view.text = "楼主"
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = ThemeStyle.style.value == .day ? ThemeStyle.style.value.cellBackgroundColor : UIColor.hex(0x999999)
        view.layer.cornerRadius = 3
        view.contentInsets = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    
    private lazy var thankLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 13)
        view.textColor = UIColor.hex(0xcccccc)
        return view
    }()

    private lazy var forewordLabel: UIInsetLabel = {
        let view = UIInsetLabel()
        view.numberOfLines = 0
        view.contentInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.backgroundColor = ThemeStyle.style.value.bgColor
        view.textColor = ThemeStyle.style.value.titleColor
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var contentLabel: YYLabel = {
        let view = YYLabel()
        view.numberOfLines = 0
        view.preferredMaxLayoutWidth = Constants.Metric.screenWidth - 30;
        view.displaysAsynchronously = true
        return view
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Color.borderColor
        return view
    }()
    
    
    private lazy var replyContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeStyle.style.value.bgColor
        return view
    }()
    
    private lazy var replyImageView: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "reply")
        view.contentMode = .center
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        view.backgroundColor = ThemeStyle.style.value.bgColor
        return view
    }()

    private var thankLabelLeftConstraint: Constraint?
    private var contentLabelTopConstraint: Constraint?
    
    public var tapHandle: ((_ type: TapType) -> Void)?

    public var hostUsername: String?
    
    private var replyPanOffset: CGFloat = 0
    
    private var initCenterX: CGFloat = 0

    private let activationOffset: CGFloat = 70
    
    public var forewordComment: CommentModel? {
        didSet {
            guard let comment = forewordComment else {
                forewordLabel.text = nil
                return
            }
            
            let username = comment.member.username + ":"
            forewordLabel.text = username + "  " + comment.content
            forewordLabel.makeSubstringColor(username, color: ThemeStyle.style.value.linkColor)
        }
    }
    
    public var comment: CommentModel? {
        didSet {
            guard let `comment` = comment else { return }

            avatarView.setImage(urlString: comment.member.avatarSrc, placeholder: #imageLiteral(resourceName: "avatarRect"))
            usernameLaebl.text = comment.member.username
            floorLabel.text = comment.floor + " 楼"
            timeLabel.text = comment.publicTime
            
            if let textLayout = comment.textLayout {
                let mutableAttr = NSMutableAttributedString(attributedString: textLayout.text)
                mutableAttr.removeAttribute(.foregroundColor, range: mutableAttr.yy_rangeOfAll())
                mutableAttr.addAttribute(.foregroundColor, value: ThemeStyle.style.value.titleColor, range: mutableAttr.yy_rangeOfAll())
                let layout = YYTextLayout(container: textLayout.container, text: mutableAttr)
                contentLabel.textLayout = layout
            } else {
                contentLabel.textLayout = comment.textLayout
            }
            
            forewordLabel.isHidden = forewordComment == nil
            contentLabelTopConstraint?.update(offset: forewordLabel.isHidden ? -20 : 10)

            hostLabel.isHidden = (hostUsername ?? "")  != comment.member.username
            
            if let thankCount = comment.thankCount {
                var thankText: String = "♥ \(thankCount)"
                
                if comment.isThank {
                    thankText.append("  已感谢")
                }
                thankLabel.text = thankText
            } else {
                thankLabel.text = nil
            }
            
            thankLabelLeftConstraint?.update(offset: hostLabel.isHidden ? -35 : 10)
            backgroundColor = ThemeStyle.style.value.cellBackgroundColor
        }
    }

    override func initialize() {
//        contentView.clipsToBounds = true
        clipsToBounds = true
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.hex(0xB3DBE8).withAlphaComponent(0.3)
        selectedBackgroundView = bgColorView
        
        let avatarTapGesture = UITapGestureRecognizer()
        avatarView.addGestureRecognizer(avatarTapGesture)

        let avatarLongPressGesture = UILongPressGestureRecognizer()
        avatarLongPressGesture.minimumPressDuration = 0.25
        avatarView.addGestureRecognizer(avatarLongPressGesture)
        
        let replyPanGesture = UIPanGestureRecognizer(target: self, action: #selector(replyPanGestureRecognizerHandle))
        replyPanGesture.delegate = self
        contentView.addGestureRecognizer(replyPanGesture)

        avatarTapGesture.rx
            .event
            .subscribeNext { [weak self] _ in
                guard let member = self?.comment?.member else { return }
                self?.tapHandle?(.member(member))
            }.disposed(by: rx.disposeBag)

        avatarLongPressGesture.rx
            .event
            .subscribeNext { [weak self] gesture in
                guard gesture.state == .began else { return }
                guard let member = self?.comment?.member else { return }
                self?.tapHandle?(.memberAvatarLongPress(member))
        }.disposed(by: rx.disposeBag)
        
        forewordLabel.rx.tapGesture
            .subscribeNext { [weak self] _ in
                guard let `self` = self, let comment = self.forewordComment else { return }
                self.tapHandle?(.foreword(comment))
        }.disposed(by: rx.disposeBag)
        
        contentView.addSubviews(
            avatarView,
            usernameLaebl,
            timeLabel,
            floorLabel,
            hostLabel,
            thankLabel,
            forewordLabel,
            contentLabel,
            lineView,
            replyContainerView
        )
        replyContainerView.addSubview(replyImageView)
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.forewordLabel.textColor = theme.titleColor
                self?.usernameLaebl.textColor = theme.titleColor
                self?.lineView.backgroundColor = theme.borderColor
                self?.timeLabel.textColor = theme.dateColor
                self?.floorLabel.textColor = theme.dateColor
                self?.hostLabel.backgroundColor = theme == .day ? theme.globalColor.withAlphaComponent(0.3) : theme.bgColor
            }.disposed(by: rx.disposeBag)
    }
    
    override func setupConstraints() {
        avatarView.snp.makeConstraints {
            $0.left.top.equalToSuperview().inset(15)
            $0.size.equalTo(32)
        }

        usernameLaebl.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(10)
            $0.top.equalTo(avatarView)
        }

        hostLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLaebl.snp.right).offset(10)
            $0.centerY.equalTo(usernameLaebl)
        }

        floorLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLaebl)
            $0.bottom.equalTo(avatarView)
        }

        timeLabel.snp.makeConstraints {
            $0.left.equalTo(floorLabel.snp.right).offset(10)
            $0.centerY.equalTo(floorLabel)
        }
        
        thankLabel.snp.makeConstraints {
            thankLabelLeftConstraint = $0.left.equalTo(hostLabel.snp.right).offset(10).constraint
            $0.centerY.equalTo(usernameLaebl)
        }

        forewordLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView.snp.bottom).offset(10)
        }
        
        contentLabel.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview().inset(15)
            contentLabelTopConstraint = $0.top.equalTo(forewordLabel.snp.bottom).offset(10).constraint
        }

        lineView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        
        replyContainerView.snp.makeConstraints {
//            $0.right.equalToSuperview().inset(-activationOffset)
            $0.left.equalTo(contentView.snp.right)
            $0.width.equalTo(activationOffset)
            $0.height.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        
        replyImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let vel = panGesture.velocity(in: contentView)
            return abs(vel.x) > abs(vel.y) && vel.x < 0
        }
        return true
    }
    
    @objc private func replyPanGestureRecognizerHandle(gesture: UIPanGestureRecognizer) {
        guard let gestureView = gesture.view else { return }
        
        let directionP = gesture.velocity(in: gesture.view)
        var translationX = gesture.translation(in: gesture.view).x
        
        switch gesture.state {
        case .changed:

            if abs(directionP.y) < abs(directionP.x) {
                if -translationX > activationOffset {
                    translationX = -activationOffset
                } else if translationX > 0 {
                    translationX = 0
                    resetState()
                }
                gestureView.centerX = center.x + translationX
            }
            if -translationX >= activationOffset * 0.85 {
                replyImageView.fadeIn(0.1)
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.2, options: .curveLinear, animations: {
                    if #available(iOS 10.0, *) {
                        if self.replyImageView.transform != .identity {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                        }
                    }
                    self.replyImageView.transform = .identity
                    
                }, completion: nil)
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.2, animations: {
                gestureView.centerX = self.center.x
            }, completion: { _ in
                self.resetState()
                guard -translationX >= self.activationOffset else { return }
                guard let comment = self.comment else { return }
                self.tapHandle?(.reply(comment))
            })
        default:
            break
        }
    }
    
    private func resetState() {
        replyImageView.fadeOut()
        replyImageView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    }
    
    // 选中cell时背景颜色会同化, 重新覆盖
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
        
        forewordLabel.backgroundColor = ThemeStyle.style.value.bgColor
        hostLabel.backgroundColor = ThemeStyle.style.value == .day ? ThemeStyle.style.value.globalColor.withAlphaComponent(0.3) : ThemeStyle.style.value.bgColor
    }
}
