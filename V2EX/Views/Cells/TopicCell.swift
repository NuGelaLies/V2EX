import UIKit
import RxSwift
import RxCocoa

class TopicCell: BaseTableViewCell {

    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.setCornerRadius = 5
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = .preferredFont(forTextStyle: .body)
        if #available(iOS 10, *) {
            view.adjustsFontForContentSizeCategory = true
        }
        return view
    }()
    
    private lazy var nodeLabel: UIInsetLabel = {
        let view = UIInsetLabel()
        view.font = UIFont.systemFont(ofSize: 13)
        view.textColor = UIColor.hex(0x999999)
        view.backgroundColor = UIColor.hex(0xf5f5f5)
        view.contentInsets = UIEdgeInsets(top: 2, left: 3, bottom: 2, right: 3)
        return view
    }()
    
    private lazy var lastReplyLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 11)
        view.textColor = UIColor.hex(0xCCCCCC)
        return view
    }()
    
    private lazy var replayCountLabel: UIButton = {
        let view = UIButton()
        view.titleLabel?.font = UIFont.systemFont(ofSize: 11)
        view.setImage(#imageLiteral(resourceName: "message"), for: .normal)
        view.setTitleColor(UIColor.hex(0xBCB8BD), for: .normal)
        view.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        return view
    }()

    public var tapHandle: ((_ type: TapType) -> Void)?

    override func initialize() {
        selectionStyle = .none
        separatorInset = .zero

        contentView.addSubviews(
            avatarView,
            usernameLabel,
            titleLabel,
            lastReplyLabel,
            nodeLabel,
            replayCountLabel
        )

        avatarView.rx
            .tapGesture
            .throttle(0.3, scheduler: MainScheduler.instance)
            .subscribeNext { [weak self] _ in
                guard let member = self?.topic?.member else { return }
                self?.tapHandle?(.member(member))
        }.disposed(by: rx.disposeBag)
    

        nodeLabel.rx
            .tapGesture
            .throttle(0.3, scheduler: MainScheduler.instance)
            .subscribeNext { [weak self] _ in
                guard let node = self?.topic?.node else { return }
                self?.tapHandle?(.node(node))
            }.disposed(by: rx.disposeBag)

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                guard let `self` = self else { return }
                let titleColor = theme.titleColor
                self.titleLabel.textColor = (self.topic?.isRead ?? false) ? titleColor.withAlphaComponent(0.4) : titleColor
//                self?.titleLabel.textColor = theme.titleColor
                self.nodeLabel.backgroundColor = theme == .day ? UIColor.hex(0xf5f5f5) : theme.bgColor
                self.usernameLabel.textColor = theme.titleColor
                self.lastReplyLabel.textColor = theme.dateColor
            }.disposed(by: rx.disposeBag)
    }
    
    override func setupConstraints() {
        
        avatarView.snp.makeConstraints {
            $0.left.top.equalToSuperview().inset(15)
            $0.size.equalTo(35)
        }
        
        usernameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(10)
            $0.top.equalTo(avatarView).offset(1)
        }
        
        lastReplyLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLabel)
            $0.bottom.equalTo(avatarView).inset(1)
        }
        
        titleLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView.snp.bottom).offset(15)
        }
        
        replayCountLabel.snp.makeConstraints {
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView)
            replayCountLabel.sizeToFit()
        }
        
        nodeLabel.snp.makeConstraints {
            $0.right.equalTo(replayCountLabel.snp.left).offset(-10)
            $0.centerY.equalTo(replayCountLabel)
        }
    }
    
    var topic: TopicModel? {
        didSet {
            guard let `topic` = topic else { return }
            guard let user = topic.member else { return }
            avatarView.setImage(urlString: user.avatarSrc, placeholder: #imageLiteral(resourceName: "avatarRect"))
            usernameLabel.text = user.username
            titleLabel.text = topic.title
            lastReplyLabel.text = topic.lastReplyTime
            replayCountLabel.setTitle(" " + topic.replyCount, for: .normal)
            nodeLabel.text = topic.node?.title
            nodeLabel.isHidden = nodeLabel.text?.isEmpty ?? true
            
            let titleColor = ThemeStyle.style.value.titleColor
            titleLabel.textColor = topic.isRead ? titleColor.withAlphaComponent(0.4) : titleColor
        }
    }

//    override var frame: CGRect {
//        didSet {
//            var newFrame = frame
//            newFrame.size.height -= 10
//            newFrame.origin.y += 10
//            super.frame = newFrame
//        }
//    }
}
