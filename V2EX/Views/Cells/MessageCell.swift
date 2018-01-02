import UIKit

class MessageCell: BaseTableViewCell {

    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.setCornerRadius = 5
        return view
    }()

    private lazy var replyLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.hex(0xD4D4D4)
        view.font = UIFont.systemFont(ofSize: 14)
        view.numberOfLines = 0
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.hex(0xCCCCCC)
        view.font = UIFont.systemFont(ofSize: 11)
        return view
    }()

    private lazy var contentLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
//        view.font = UIFont.systemFont(ofSize: 15)
        view.font = .preferredFont(forTextStyle: .body)

        if #available(iOS 10, *) {
            view.adjustsFontForContentSizeCategory = true
        }
        return view
    }()

    public var avatarTapHandle: ((MessageCell)->())?

    override func initialize() {

        separatorInset = .zero
        selectionStyle = .none

        contentView.addSubviews(
            avatarView,
            replyLabel,
            timeLabel,
            contentLabel
        )

        avatarView.rx
            .tapGesture
            .subscribeNext { [weak self] _ in
                guard let `self` = self else { return }
                self.avatarTapHandle?(self)
            }.disposed(by: rx.disposeBag)
    }

    override func setupConstraints() {
        avatarView.snp.makeConstraints {
            $0.top.left.equalToSuperview().inset(15)
            $0.size.equalTo(32)
        }

        replyLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(10)
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView).offset(2)
        }

        contentLabel.snp.makeConstraints {
            $0.left.equalTo(replyLabel)
            $0.top.equalTo(replyLabel.snp.bottom).offset(10)
            $0.right.equalToSuperview().inset(15)
        }

        timeLabel.snp.makeConstraints {
            $0.left.equalTo(contentLabel)
            $0.top.equalTo(contentLabel.snp.bottom).offset(10)
            $0.bottom.equalToSuperview().inset(12)
        }
    }

    public var message: MessageModel? {
        didSet {
            guard let `message` = message else { return }
            guard let member = message.member else { return }

            avatarView.setImage(urlString: member.avatarSrc, placeholder: #imageLiteral(resourceName: "avatarRect"))
            contentLabel.text = message.content
            timeLabel.text = message.time
            replyLabel.text = message.replyTypeStr
//            replyLabel.makeSubstringColor(member.username, color: .black)
//            replyLabel.makeSubstringColor(message.topic.title, color: Theme.Color.linkColor)

            ThemeStyle.style.asObservable()
                .subscribeNext { [weak self] theme in
                    self?.replyLabel.makeSubstringColor(member.username, color: theme.titleColor)
                    self?.replyLabel.makeSubstringColor(message.topic.title, color: theme.linkColor)
                    self?.contentLabel.textColor = theme.titleColor
                    if let username = AccountModel.current?.username {
                        self?.contentLabel.makeSubstringColor("@" + username, color: theme.linkColor)
                    }
                    self?.timeLabel.textColor = theme.dateColor
                }.disposed(by: rx.disposeBag)

        }
    }
}
