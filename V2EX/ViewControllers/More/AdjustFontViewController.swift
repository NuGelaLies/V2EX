import UIKit

class AdjustFontViewController: BaseViewController {

    // MARK: - UI

    private lazy var previewContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var avatarView: UIImageView = {
        return UIImageView(image: #imageLiteral(resourceName: "avatarRect"))
    }()

    private lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.text = "Joe"
        view.font = UIFont.systemFont(ofSize: 16)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = "如果调节字体大小？"
        view.numberOfLines = 0
        view.font = UIFont.boldSystemFont(ofSize: 17)
        return view
    }()

    private lazy var contentLabel: UILabel = {
        let view = UILabel()
        view.text = "通过滑动下方的滑块可调节主题详情的字体大小。\n通过系统内的【设置】->【显示与亮度】->【文字大小】可修改 App 整体字体大小"
        view.numberOfLines = 0
        view.setLineHeight(5)
        view.font = UIFont.systemFont(ofSize: CGFloat(sliderView.value * 0.1 + 1.05) * 13.f)
        return view
    }()

    private lazy var sliderContainerView: UIView = {
        let view = UIView()
        view.layer.borderColor = Theme.Color.borderColor.cgColor
        view.layer.borderWidth = 0.5
        return view
    }()

    private lazy var sliderView: DiscreteSliderView = {
//        let view = UISlider()
//        view.minimumValue = 1.0
//        view.maximumValue = 2.0
//        view.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
//        view.tintColor = Theme.Color.globalColor
//        view.value = Preference.shared.webViewFontScale
        
        // Font slider size
        let slider = DiscreteSliderView(frame: CGRect(x: 60, y: 0, width: view.frame.width-120, height: 55))
        slider.tickStyle = ComponentStyle.rounded
        slider.tickCount = 7
        slider.tickSize = CGSize(width: 8, height: 8)
        slider.minimumValue = 1.0
        slider.incrementValue = 1.0
        slider.thumbStyle = .rounded
        slider.thumbSize = CGSize(width: 28, height: 28)
        slider.thumbShadowOffset = CGSize(width: 0, height: 2)
        slider.thumbShadowRadius = 3
        slider.thumbColor = Theme.Color.globalColor
        
        slider.backgroundColor = UIColor.clear
        slider.tintColor = Theme.Color.bgColor
        slider.value = CGFloat(Preference.shared.webViewFontScale)
//        slider.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
        
        slider.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
        // Force remove fill color
        slider.layer.sublayers?.forEach({ layer in
            layer.backgroundColor = UIColor.clear.cgColor
        })

        return slider
    }()

    private lazy var minLabel: UILabel = {
        let view = UILabel()
        view.text = "A"
        view.font = UIFont.systemFont(ofSize: 15)
        return view
    }()

    private lazy var maxLabel: UILabel = {
        let view = UILabel()
        view.text = "A"
        view.font = UIFont.systemFont(ofSize: 30)
        return view
    }()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        interactivePopDisabled = true
        
        title = "阅读设置"
        view.backgroundColor = .white
        view.clipsToBounds = true
        
        ThemeStyle.style
            .asObservable()
            .subscribeNext { [weak self] theme in
                self?.view.backgroundColor = theme.whiteColor
                self?.titleLabel.textColor = theme.titleColor
                self?.usernameLabel.textColor = theme.titleColor
                self?.contentLabel.textColor = theme.titleColor
                self?.sliderContainerView.layer.borderColor = theme == .day ? theme.borderColor.cgColor : UIColor.gray.cgColor
                self?.minLabel.textColor = theme.titleColor
                self?.maxLabel.textColor = theme.titleColor
            }.disposed(by: rx.disposeBag)
    }

    // MARK: - Setup

    override func setupSubviews() {
        view.addSubviews(previewContainerView, sliderContainerView)
        previewContainerView.addSubviews(avatarView, usernameLabel, titleLabel, contentLabel)
        sliderContainerView.addSubviews(sliderView, minLabel, maxLabel)
    }

    override func setupConstraints() {

        // MARK - Preview ContainerView
        previewContainerView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(200)
            $0.top.equalToSuperview().offset(50)
        }

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
        }

        // MARK : - Slider ContainerView
        sliderContainerView.snp.makeConstraints {
            $0.top.equalTo(previewContainerView.snp.bottom).offset(155)
            $0.left.right.equalToSuperview().inset(-1)
            $0.bottom.equalTo(sliderView)
        }

        sliderView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.65)
            $0.height.equalTo(60)
        }

        minLabel.snp.makeConstraints {
            $0.right.equalTo(sliderView.snp.left).inset(-20)
            $0.centerY.equalTo(sliderView)
        }

        maxLabel.snp.makeConstraints {
            $0.left.equalTo(sliderView.snp.right).offset(20)
            $0.centerY.equalTo(minLabel)
        }
    }

    /// MARK: - Actions
    @objc func sliderValueDidChange() {
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
        contentLabel.font = UIFont.systemFont(ofSize: (CGFloat(sliderView.value) * 0.1 + 1.05) * 13.f)
        Preference.shared.webViewFontScale = Float(sliderView.value)
    }
}


