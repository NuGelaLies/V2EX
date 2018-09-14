import UIKit

enum RightType {
    case none, arrow, `switch`
}

class BaseTableViewCell: UITableViewCell {

    public lazy var switchView: UISwitch = {
        let view = UISwitch()
        view.sizeToFit()
        view.isUserInteractionEnabled = false
        view.onTintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2666666667, alpha: 1)
        return view
    }()

    public var rightType: RightType = .arrow {
        didSet {
            switch rightType {
            case .arrow:
                accessoryType = .disclosureIndicator
            case .switch:
                accessoryView = switchView
            default:
                accessoryType = .none
            }
        }
    }

    // MARK: Initializing
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        //        separatorInset = .zero
        //        textLabel?.textColor = Theme.Color.shallowBlack
        initialize()
        setupConstraints()
        setupTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initialize() {
        // Override point
    }

    func setupConstraints() {
        // Override point
    }

    func setupTheme() {

        ThemeStyle.style
            .asObservable()
            .subscribeNext { [weak self] theme in
                self?.backgroundColor = theme.cellBackgroundColor
                self?.textLabel?.textColor = theme.titleColor
                self?.detailTextLabel?.textColor = theme.titleColor
                self?.imageView?.tintColor = theme.tintColor
        }.disposed(by: rx.disposeBag)
    }
}
