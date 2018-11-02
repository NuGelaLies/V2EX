import UIKit

class AppearanceSampleCell: BaseTableViewCell {

    private lazy var avatarView: UIImageView = {
        return UIImageView(image: #imageLiteral(resourceName: "avatarRect"))
    }()
    
    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.text = "devjoe"
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = "如果调节字体大小？"
        view.numberOfLines = 0
        view.font = UIFont.boldSystemFont(ofSize: 17)
        view.font = .preferredFont(forTextStyle: .headline)
        if #available(iOS 10, *) {
            view.adjustsFontForContentSizeCategory = true
        }
        return view
    }()
    
    private lazy var contentLabel: UILabel = {
        let view = UILabel()
        view.text = "通过滑动下方的滑块可调节主题详情的字体大小。\n通过系统内的【设置】->【显示与亮度】->【文字大小】可修改 App 整体字体大小"
        view.numberOfLines = 0
        view.setLineHeight(5)
        return view
    }()
    
    override func initialize() {
        contentView.addSubviews(avatarView, usernameLabel, titleLabel, contentLabel)
        selectionStyle = .none
        adjustFont()
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.backgroundColor = theme.cellBackgroundColor
                self?.titleLabel.textColor = theme.titleColor
                self?.usernameLabel.textColor = theme.titleColor
                self?.contentLabel.textColor = theme.titleColor
//                self?.nodeLabel.backgroundColor = theme == .day ? UIColor.hex(0xf5f5f5) : theme.bgColor
//                self?.timeLabel.textColor = theme.dateColor
            }.disposed(by: rx.disposeBag)
    }
    
    override func setupConstraints() {
        avatarView.snp.makeConstraints {
            $0.left.top.equalToSuperview().inset(15)
            $0.size.equalTo(48)
        }
        
        usernameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(10)
            $0.centerY.equalTo(avatarView)
        }
        
        titleLabel.snp.makeConstraints {
            $0.right.equalToSuperview().inset(15)
            $0.left.equalTo(avatarView)
            $0.top.equalTo(avatarView.snp.bottom).offset(15)
        }
        
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(15)
            $0.left.right.equalTo(titleLabel)
            $0.bottom.equalToSuperview().inset(15)
        }
    }
    
    public func adjustFont(for size: Float = Preference.shared.webViewFontScale) {
        contentLabel.font = UIFont.systemFont(ofSize: CGFloat(size * 0.1 + 1.05) * 13.f)
    }
    
}
