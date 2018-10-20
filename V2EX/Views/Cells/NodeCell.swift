import UIKit

class NodeCell: UICollectionViewCell {

    private lazy var textLabel: UILabel = {
        let view = UILabel()
//        view.font = UIFont.systemFont(ofSize: 15)
        view.textAlignment = .center
        view.textColor = Theme.Color.globalColor
        view.font = .preferredFont(forTextStyle: .body)
        if #available(iOS 10, *) {
            view.adjustsFontForContentSizeCategory = true
        }
        return view
    }()
    
    public var node: NodeModel? {
        didSet {
            guard let `node` = node else { return }
            
            textLabel.text = node.title
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        
        
//        backgroundColor = Theme.Color.bgColor

        textLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.backgroundColor = theme.nodeColor
                self?.textLabel.textColor = theme.somberColor
            }.disposed(by: rx.disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
