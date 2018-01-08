import UIKit

class ReplyCell: BaseTableViewCell {
    
    private var replyDesLabel: UILabel?
    
    private var contentLabel: UILabel?
    
    override func initialize() {
        separatorInset = .zero
        selectionStyle = .none
        
        let replyDesLabel = UILabel()
            .hand.adhere(toSuperView: contentView)
            .hand.layout {
                $0.left.top.right.equalToSuperview().inset(15)
            }
            .hand.config { label in
                label.textColor = UIColor.hex(0xCCCCCC)
                label.font = UIFont.systemFont(ofSize: 14)
                label.numberOfLines = 0
        }
        self.replyDesLabel = replyDesLabel
        
        let contentLabel = UILabel()
            .hand.adhere(toSuperView: contentView)
            .hand.layout {
                $0.top.equalTo(replyDesLabel.snp.bottom).offset(10)
                $0.left.bottom.right.equalToSuperview().inset(15)
            }
            .hand.config { label in
                label.numberOfLines = 0
//                label.font = UIFont.systemFont(ofSize: 15)
                label.font = .preferredFont(forTextStyle: .body)
                if #available(iOS 10, *) {
                    label.adjustsFontForContentSizeCategory = true
                }
        }
        self.contentLabel = contentLabel

        ThemeStyle.style.asObservable()
            .subscribeNext { theme in
                contentLabel.textColor = theme.titleColor
            }.disposed(by: rx.disposeBag)
    }
    
    public var message: MessageModel? {
        didSet {
            guard let `message` = message else { return }
            contentLabel?.text = message.content
            replyDesLabel?.text = message.replyTypeStr
            replyDesLabel?.makeSubstringColor(message.topic.title, color: Theme.Color.linkColor)
            //            replyDesLabel.makeSubstringColor(message.time, color: UIColor.hex(0xe2e2e2))
        }
    }
}
