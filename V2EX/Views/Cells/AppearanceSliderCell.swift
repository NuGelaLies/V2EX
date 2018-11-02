import UIKit

class AppearanceSliderCell: BaseTableViewCell {

    private lazy var sliderContainerView: UIView = {
        let view = UIView()
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
        let slider = DiscreteSliderView(frame: CGRect(x: 60, y: 0, width: Constants.Metric.screenWidth - 120, height: 60))
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
    
    public var fontSizeDidChangeCallback: ((Float) -> Void)?
    
    override func initialize() {
        contentView.addSubview(sliderContainerView)
        sliderContainerView.addSubviews(sliderView, minLabel, maxLabel)
        selectionStyle = .none
        
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.minLabel.textColor = theme.titleColor
                self?.maxLabel.textColor = theme.titleColor
            }.disposed(by: rx.disposeBag)
    }
    
    
    override func setupConstraints() {
        
        sliderContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(60).priority(.high)
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
//        contentLabel.font = UIFont.systemFont(ofSize: (CGFloat(sliderView.value) * 0.1 + 1.05) * 13.f)
        Preference.shared.webViewFontScale = Float(sliderView.value)
        fontSizeDidChangeCallback?(Float(sliderView.value))
    }

}
