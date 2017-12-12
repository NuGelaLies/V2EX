import UIKit

class TopicFavoriteViewController: BaseTopicsViewController, AccountService {

    // MARK: - Setup

    override func setupRefresh() {
        tableView.addHeaderRefresh { [weak self] in
            self?.fetchFavoriteTopic()
        }
        tableView.addFooterRefresh { [weak self] in
            self?.fetchMoreFavoriteTopic()
        }
    }

    init() {
        super.init(href: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: State Handle

    override func loadData() {
        fetchFavoriteTopic()
    }

    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {
        fetchFavoriteTopic()
    }

    override  func emptyView(_ emptyView: EmptyView, didTapActionButton sender: UIButton) {
        fetchFavoriteTopic()
    }
}

// MARK: - Actions
extension TopicFavoriteViewController {

    private func fetchFavoriteTopic() {
        page = 1
        startLoading()

        myFavorite(page: page, success: { [weak self] topics, maxPage in
            self?.maxPage = maxPage
            self?.topics = topics
            self?.endLoading()
            self?.tableView.endHeaderRefresh()
            }, failure: { [weak self] error in
                self?.tableView.endHeaderRefresh()
                self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
                self?.errorMessage = error
        })
    }

    func fetchMoreFavoriteTopic() {
        if page >= maxPage {
            tableView.endRefresh(showNoMore: true)
            return
        }

        page += 1

        startLoading()

        myFavorite(page: page, success: { [weak self] topics, maxPage in
            guard let `self` = self else { return }
            self.topics.append(contentsOf: topics)
            self.tableView.reloadData()
            self.tableView.endRefresh(showNoMore: maxPage < self.page)
        }) { [weak self] error in
            self?.tableView.endFooterRefresh()
            self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
            self?.page -= 1
        }
    }
}
