import Foundation
import UIKit
import PullToRefreshKit


class VFooterRefresh: UIView, RefreshableFooter {

    fileprivate let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(white: 160.0 / 255.0, alpha: 1.0)
        label.textAlignment = .center
        label.text = "已加载全部数据"
        label.isHidden = true
        return label
    }()

    fileprivate let indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .gray)
        indicatorView.isHidden = true
        return indicatorView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(indicatorView)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func heightForFooter() -> CGFloat {
        return 40
    }

    /// 不需要下拉加载更多的回调
    func didUpdateToNoMoreData() {
        titleLabel.isHidden = false
        
        UIView.animate(withDuration: 1.5, delay: 0.3, options: .curveEaseInOut, animations: {
            self.titleLabel.alpha = 0.0
        }) { _ in
            let scrollView = self.superview?.superview as? UIScrollView
            scrollView?.switchRefreshFooter(to: .normal)
        }
    }

    /// 重新设置到常态的回调
    func didResetToDefault() {
        titleLabel.isHidden = true
        titleLabel.alpha = 1
    }

    /// 结束刷新的回调
    func didEndRefreshing() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }

    /// 已经开始执行刷新逻辑，在一次刷新中，只会调用一次
    func didBeginRefreshing() {
        indicatorView.startAnimating()
        indicatorView.isHidden = false
        titleLabel.isHidden = true
    }

    /// 当Scroll触发刷新，这个方法返回是否需要刷新
    func shouldBeginRefreshingWhenScroll() -> Bool {
        return titleLabel.isHidden
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.sizeToFit()
        indicatorView.center = center
        titleLabel.center = center
    }
}
