import UIKit

enum MarkdownItemType: Int, CaseIterable {
    case leftMove
    case rightMove
    case undo
    case redo
    case bold
    case italic
    case heading
    case quote
    case codeBlock
    case genericList
    case numberedList
    case link
    case image
    case clear
    case closeKeyboard

    var image: UIImage {
        switch self {
        case .leftMove: return #imageLiteral(resourceName: "leftArrow")
        case .rightMove: return #imageLiteral(resourceName: "rightArrow")
        case .undo: return #imageLiteral(resourceName: "undo")
        case .redo: return #imageLiteral(resourceName: "redo")
        case .bold: return #imageLiteral(resourceName: "bold")
        case .italic: return #imageLiteral(resourceName: "italic")
        case .heading: return #imageLiteral(resourceName: "heading")
        case .quote: return #imageLiteral(resourceName: "quote")
        case .codeBlock: return #imageLiteral(resourceName: "codeBlock")
        case .genericList: return #imageLiteral(resourceName: "genericList")
        case .numberedList: return #imageLiteral(resourceName: "numberedList")
        case .link: return #imageLiteral(resourceName: "link")
        case .image: return #imageLiteral(resourceName: "image")
        case .clear: return #imageLiteral(resourceName: "Clear")
        case .closeKeyboard: return #imageLiteral(resourceName: "closeKeyboard")
        }
    }

    var mark: String? {
        switch self {
        case .bold: return "****"
        case .italic: return "**"
        case .heading: return "#"
        case .quote: return "> "
        case .codeBlock: return "\n```\n\n```"
        case .genericList: return "* "
        case .numberedList: return "1. "
        case .link: return "[]()"
        default: return nil
        }
    }

    var location: Int? {
        switch self {
        case .bold: return 2
        case .italic: return 1
        case .codeBlock: return 4
        case .link: return 3
        default: return nil
        }
    }
}

class MarkdownInputAccessoryView: UIView {

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.delaysContentTouches = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return view
    }()

    private lazy var closeKeyboardBtn: UIButton = {
        let view = UIButton()
        view.setImage(MarkdownItemType.closeKeyboard.image.withRenderingMode(.alwaysTemplate), for: .normal)
        view.setImage(MarkdownItemType.closeKeyboard.image.withRenderingMode(.alwaysTemplate), for: .selected)
        view.tag = MarkdownItemType.closeKeyboard.rawValue
        view.addTarget(self, action: #selector(clickHandle(_:)), for: .touchUpInside)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 1
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: -2, height: 0)
        view.backgroundColor = .white
        return view
    }()

    public var didSelectedItemHandle: ((_ type: MarkdownItemType) -> Void)?

    private var items: [MarkdownItemType] = MarkdownItemType.allCases
    private var pins: [MarkdownItemType] = [.closeKeyboard]

    init(height: CGFloat = 44) {
        super.init(frame: CGRect(x: 0, y: 0, width: Constants.Metric.screenWidth, height: height))
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundColor = UIColor.hex(0xd7d7d7)
        layer.borderColor = Theme.Color.borderColor.cgColor
        layer.borderWidth = 0.3

        scrollView.frame = frame
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: pins.count.f * height)
        scrollView.contentSize = CGSize(width: (items.count - pins.count).f * height, height: height)

        backgroundColor = .white

        setupUI()
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.backgroundColor = theme.whiteColor
                self?.closeKeyboardBtn.backgroundColor = theme.whiteColor
                self?.layer.borderColor = (theme == .day ? theme.borderColor : UIColor.hex(0x49431A)).cgColor
                self?.scrollView.tintColor = theme.titleColor
                self?.closeKeyboardBtn.tintColor = theme.tintColor
        }.disposed(by: rx.disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        addSubviews(scrollView, closeKeyboardBtn)

        let w = height
        for (index, item) in items.enumerated() {
            if pins.contains(item) { continue }
            let btn = UIButton()
            btn.frame = CGRect(x: index.f * w, y: 0, width: w, height: w)
            btn.tag = item.rawValue
            btn.setImage(item.image.withRenderingMode(.alwaysTemplate), for: .normal)
            btn.setImage(item.image.withRenderingMode(.alwaysTemplate), for: .selected)
            btn.addTarget(self, action: #selector(clickHandle(_:)), for: .touchUpInside)
            scrollView.addSubview(btn)
        }

        closeKeyboardBtn.frame = CGRect(x: width - height, y: 0, width: height, height: height)
        closeKeyboardBtn.autoresizingMask = .flexibleLeftMargin
    }

    @objc func clickHandle(_ btn: UIButton) {
        guard let type = MarkdownItemType(rawValue: btn.tag) else { return }

        didSelectedItemHandle?(type)
    }
}
