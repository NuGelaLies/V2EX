import UIKit
import StatefulViewController

class LoadingView: BasePlaceholderView, StatefulPlaceholderView {

    override func setupView() {
        UIActivityIndicatorView(style: .gray)
            .hand.adhere(toSuperView: self)
            .hand.config { activityIndicator in
                activityIndicator.startAnimating()
                activityIndicator.style = UIDevice.isiPad ? .whiteLarge : .white
                activityIndicator.color = .gray
            }.hand.layout { maker in
                maker.center.equalToSuperview()
        }
    }

    func placeholderViewInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: Constants.Metric.navigationHeight, left: 0, bottom: Constants.Metric.tabbarHeight, right: 0)
    }
}
