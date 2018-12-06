import UIKit
import PullToRefreshKit

extension UIScrollView {

    func addHeaderRefresh(handle: @escaping Action) {
//        configRefreshHeader(with: DefaultRefreshHeader.header(), action: handle)
        
        configRefreshHeader(with: ElasticRefreshHeader(), container: self, action: handle)
    }

    func addFooterRefresh(handle: @escaping Action) {
        configRefreshFooter(with: VFooterRefresh(), container: self, action: handle)
    }

    func endHeaderRefresh() {
        switchRefreshHeader(to: HeaderRefresherState.normal(.none, 0))
        switchRefreshFooter(to: .normal)
    }

    func endFooterRefresh(showNoMore: Bool = false) {
        switchRefreshFooter(to: .normal)
        
        if showNoMore {
            switchRefreshFooter(to: .noMoreData)
        }
    }

    func endRefresh(showNoMore: Bool = false) {

        guard showNoMore else {
            switchRefreshHeader(to: HeaderRefresherState.normal(.none, 0))
            switchRefreshFooter(to: .normal)
            return
        }
        endFooterRefresh(showNoMore: showNoMore)
    }

}
