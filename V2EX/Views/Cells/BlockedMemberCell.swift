import UIKit

class BlockedMemberCell: BaseTableViewCell {

    struct Metric {
        static let avatarWH: CGFloat = 60
        static let labelMargin: CGFloat = 5
    }
    
    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.textColor = ThemeStyle.style.value.titleColor
        return view
    }()
    
    private lazy var taglineLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 13)
        view.textColor = ThemeStyle.style.value.dateColor
        return view
    }()
    
    private lazy var createdTimeLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = ThemeStyle.style.value.dateColor
        return view
    }()
    
    override func initialize() {
        contentView.addSubviews(avatarView, usernameLabel, taglineLabel, createdTimeLabel)
        
        avatarView.layer.cornerRadius = Metric.avatarWH * 0.5
        avatarView.layer.masksToBounds = true
    }
    
    override func setupConstraints() {
        avatarView.snp.makeConstraints {
            $0.size.equalTo(Metric.avatarWH)
            $0.centerY.equalToSuperview()
            $0.left.equalTo(15)
        }
        
        usernameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(10)
            $0.top.equalTo(avatarView)
        }
        
        taglineLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLabel)
            $0.top.equalTo(usernameLabel.snp.bottom).offset(Metric.labelMargin)
            $0.right.equalToSuperview().inset(15)
        }
        
        createdTimeLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLabel)
            $0.top.equalTo(taglineLabel.snp.bottom).offset(Metric.labelMargin)
        }
    }
    
    public var account: AccountModel? {
        didSet {
            guard let `account` = account else { return }
            let avatarUrl = "\(Constants.Config.URIScheme)\(account.avatarLarge ?? "")"
            avatarView.setImage(urlString: avatarUrl)
            usernameLabel.text = account.username
            taglineLabel.text = (account.tagline ?? "").isNotEmpty ? account.tagline : "暂无简介"
            createdTimeLabel.text = "第 \(account.id ?? 0) 号会员，加入于 " + Date(timeIntervalSince1970: TimeInterval(account.created ?? 0)).YYYYMMDDHHMMSSDateString
        }
    }
}
