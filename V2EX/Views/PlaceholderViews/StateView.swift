import Foundation
import UIKit


enum StatusType {
    case empty, emptyNoRetry, normal, error, notNet, noAuth, noSearchResult, noBlockUser

    var image: UIImage? {
        switch self {
        case .error: return #imageLiteral(resourceName: "hg-error")
        case .notNet: return #imageLiteral(resourceName: "hg-no_connection")
        default: return #imageLiteral(resourceName: "hg-no_results")
        }
    }

    var title: String {
        switch self {
        case .empty, .emptyNoRetry, .noBlockUser:
            return "没有数据"
        case .notNet:
            return "无网络连接"
        default:
            return "请求失败"
        }
    }

    var message: String? {
        switch self {
        case .noSearchResult:
            return "试试换个关键字?"
        case .noAuth:
            return "请在登录之后操作"
        case .noBlockUser:
            return "暂无屏蔽任何用户"
        default:
            return nil
        }
    }

    var buttonTitle: String? {
        switch self {
        case .noAuth:
            return "点击登录"
        case .noSearchResult, .emptyNoRetry, .noBlockUser:
            return nil
        default:
            return "重试"
        }
    }
}

class StateView: BasePlaceholderView {

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = UIFont.boldSystemFont(ofSize: 20)
        return view
    }()

    private lazy var messageLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.textColor = UIColor.hex(0x8E8A8F)
        view.fontSize = 14
        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var actionButton: UIButton = {
        let view = UIButton()
        view.setTitle("重试", for: .normal)
        view.backgroundColor = Theme.Color.globalColor
        view.setCornerRadius = 20
        view.addTarget(self, action: #selector(retryBtnClick), for: .touchUpInside)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()

    public var message: String? {
        didSet {
            messageLabel.text = message
        }
    }

    public var actionBtnTitle: String? {
        didSet {
            actionButton.setTitle(actionBtnTitle, for: .normal)
        }
    }

    public var type: StatusType = .normal {
        didSet {
            imageView.image = type.image
            titleLabel.text = type.title
            animate()
        }
    }

    init(frame: CGRect, message: String? = nil, type: StatusType = .error) {
        super.init(frame: frame)

        addSubviews(titleLabel, messageLabel, imageView, actionButton)

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            if UIDevice.current.orientation.isLandscape && !UIDevice.current.isPad {
                $0.top.equalToSuperview().offset(10)
            } else {
                $0.centerY.equalToSuperview().offset(-100)
            }
            $0.size.equalTo(100)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(imageView.snp.bottom).offset(20)
        }

        messageLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.left.right.equalToSuperview().inset(25)
        }

        actionButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            if UIDevice.current.orientation.isLandscape && !UIDevice.current.isPad {
                $0.top.equalTo(messageLabel.snp.bottom).offset(10)
            } else {
                $0.bottom.equalToSuperview().multipliedBy(0.75)
            }
            $0.width.equalTo(120)
            $0.height.equalTo(40)
        }

        titleLabel.text = type.title
        messageLabel.text = message
        imageView.image = type.image
    }

    func animate() {
        let rotate = CGAffineTransform(rotationAngle: -0.2)
        let stretchAndRotate = rotate.scaledBy(x: 0.5, y: 0.5)
        imageView.transform = stretchAndRotate
        imageView.alpha = 0.5
        UIView.animate(
            withDuration: 1.5,
            delay: 0.0,
            usingSpringWithDamping: 0.45,
            initialSpringVelocity: 10.0,
            options:[.curveEaseOut],
            animations: {
                self.imageView.alpha = 1.0
                let rotate = CGAffineTransform(rotationAngle: 0.0)
                let stretchAndRotate = rotate.scaledBy(x: 1.0, y: 1.0)
                self.imageView.transform = stretchAndRotate

        }, completion: nil)
    }

    func set(_ state: StatusType) {
        if let image = state.image {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
        }

        titleLabel.text = state.title
        messageLabel.text = state.message

        if let buttonTitle = state.buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.setTitle(buttonTitle, for: .highlighted)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func retryBtnClick() {
        handleActionButtonTap(actionButton)
    }

    override func didMoveToSuperview() {
        titleLabel.textColor = ThemeStyle.style.value.titleColor
        animate()
    }

    func handleActionButtonTap(_: UIButton) {
        fatalError("Should be overriden in subclass")
    }
}

