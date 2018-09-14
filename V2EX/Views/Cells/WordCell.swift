import UIKit

class WordCell: UICollectionViewCell {
    
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
    
    private lazy var deleteBtn: UIButton = {
        let view = UIButton()
        view.setImage(#imageLiteral(resourceName: "close").withRenderingMode(.alwaysTemplate), for: .normal)
        view.addTarget(self, action: #selector(deleteBtnClickAction), for: .touchUpInside)
        return view
    }()
    
    
    public var title: String? {
        didSet {
            guard let `title` = title else { return }
            
            textLabel.text = title
        }
    }
    
    public var deleteHandle: ((WordCell) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubviews(textLabel, deleteBtn)
        
        backgroundColor = Theme.Color.bgColor
        
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
        textLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(10)
            $0.top.bottom.equalToSuperview()
        }
        
        deleteBtn.snp.makeConstraints {
            $0.right.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(15)
        }
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.backgroundColor = theme == .day ? theme.bgColor : theme.cellBackgroundColor
                self?.textLabel.textColor = theme.somberColor
                self?.deleteBtn.tintColor = theme.tintColor
            }.disposed(by: rx.disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func deleteBtnClickAction() {
        deleteHandle?(self)
    }
}
