import UIKit

class MemberPageHeaderView: UIView {

    private lazy var headerView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }()
    
    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.setCornerRadius = 40
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.boldSystemFont(ofSize: 20)
        view.textColor = .white
        return view
    }()
    
    lazy var joinTimeLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var followBtn: LoadingButton = {
        let view = LoadingButton()
        view.setTitle("关注", for: .normal)
        view.setTitle("已关注", for: .selected)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setCornerRadius = 17.5
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.isHidden = true
        return view
    }()
    
    private lazy var blockBtn: LoadingButton = {
        let view = LoadingButton()
        view.setTitle("屏蔽", for: .normal)
        view.setTitle("已屏蔽", for: .selected)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.setCornerRadius = 17.5
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.isHidden = true
        return view
    }()
    
    
    public var member: MemberModel? {
        didSet {
            guard let `member` = member else { return }
            
            avatarView.setImage(urlString: member.avatarSrc, placeholder: #imageLiteral(resourceName: "avatar"))
            usernameLabel.text = member.username
            joinTimeLabel.text = member.joinTime
            headerView.image = avatarView.image
            blockBtn.isSelected = member.isBlock
            followBtn.isSelected = member.isFollow
            
            followBtn.isHidden = !AccountModel.isLogin
            blockBtn.isHidden = followBtn.isHidden
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(headerView)
        headerView.addSubviews(blurView, avatarView, usernameLabel, joinTimeLabel, followBtn, blockBtn)
        
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupConstraints() {
        
        headerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
//            $0.left.right.equalToSuperview()
//            headerViewTopConstraint = $0.top.equalToSuperview().constraint
//            $0.bottom.equalTo(joinTimeLabel).offset(15)
        }
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        avatarView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(15)
            $0.top.equalTo(20)
            $0.size.equalTo(80)
        }
        
        usernameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView)
            $0.top.equalTo(avatarView.snp.bottom).offset(15)
        }
        
        followBtn.snp.makeConstraints {
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView.snp.top)
            $0.width.equalTo(75)
            $0.height.equalTo(35)
        }
        
        blockBtn.snp.makeConstraints {
            $0.right.equalTo(followBtn)
            $0.top.equalTo(followBtn.snp.bottom).offset(10)
            $0.size.equalTo(followBtn)
        }
        
        joinTimeLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView)
            $0.right.equalToSuperview().inset(15)
            $0.top.equalTo(usernameLabel.snp.bottom).offset(15)
        }
    }

}
