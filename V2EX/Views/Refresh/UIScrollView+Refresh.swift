import UIKit
import PullToRefreshKit

extension UIScrollView {

    func addHeaderRefresh(handle: @escaping Action) {
//        configRefreshHeader(with: DefaultRefreshHeader.header(), action: handle)
        let header = ElasticRefreshHeader()
        #if swift(>=4.2)
        header.control.spinner.style = ThemeStyle.style.value == .day ? .gray : .white
        #else
        header.control.spinner.style = ThemeStyle.style.value == .day ? .gray : .white
        #endif
        configRefreshHeader(with: header, container: self, action: handle)
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
