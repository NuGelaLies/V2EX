import UIKit

class TopicSearchResultCell: BaseTableViewCell {
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textColor = .black
        view.font = UIFont.boldSystemFont(ofSize: 17)
        return view
    }()
    
    private lazy var contentLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 5
        view.textColor = UIColor.hex(0x333333)
//        view.font = UIFont.systemFont(ofSize: 14)
        view.font = .preferredFont(forTextStyle: .body)
        if #available(iOS 10, *) {
            view.adjustsFontForContentSizeCategory = true
        }
        return view
    }()
    
    private lazy var desLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.hex(0xDEDEDE)
        view.font = UIFont.systemFont(ofSize: 11)
        return view
    }()
    
    public var query: String?
    
    public var topic: SearchTopicModel? {
        didSet {
            guard let `topic` = topic else { return }
            titleLabel.text = topic.title
            
            contentLabel.text = topic.content?
                .deleteOccurrences(target: "\r")
                .deleteOccurrences(target: "\n")

            // TODO: 多个关键字应该都高亮
            if let `query` = query {
                titleLabel.attributedText = titleLabel.text?.makeSubstringColor(query, color: UIColor.hex(0xD33F3F))
                contentLabel.attributedText = contentLabel.text?.makeSubstringColor(query, color: UIColor.hex(0xD33F3F))
//                titleLabel.highlight(text: query, normal: nil, highlight: [NSAttributedString.Key.foregroundColor : UIColor.hex(0xD33F3F)])
//                contentLabel.highlight(text: query, normal: nil, highlight: [NSAttributedString.Key.foregroundColor : UIColor.hex(0xD33F3F)])
            }
            guard let memberName = topic.member,
                let time = topic.created,
                let replies = topic.replies else { return }
            
            desLabel.text = "\(memberName) 于 \(time) 发表, 共计 \(replies) 个回复"
            desLabel.makeSubstringColor(memberName, color: Theme.Color.linkColor)
        }
    }
    
    override func initialize() {
        selectionStyle = .none
        separatorInset = .zero
        
        contentView.addSubviews(
            titleLabel,
            contentLabel,
            desLabel
        )
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.contentLabel.textColor = theme == .day ? UIColor.hex(0x333333) : theme.titleColor
                self?.titleLabel.textColor = theme.titleColor
                self?.desLabel.textColor = theme.dateColor
        }.disposed(by: rx.disposeBag)
    }
    
    override func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.left.top.right.equalToSuperview().inset(15)
        }
        
        contentLabel.snp.makeConstraints {
            $0.left.right.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        
        desLabel.snp.makeConstraints {
            $0.left.right.equalTo(titleLabel)
            $0.bottom.equalToSuperview().inset(15)
            $0.top.equalTo(contentLabel.snp.bottom).offset(10)
        }
    }
}
