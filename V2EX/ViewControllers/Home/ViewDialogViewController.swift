import Foundation
import UIKit

class ViewDialogViewController: BaseTableViewController {

    // MARK: - Propertys

    public var comments: [CommentModel]


    // MARK: - View Life Cycle

    init(comments: [CommentModel], username: String) {
        self.comments = comments
        super.init(style: .plain)
        title = "有关 \(username) 的对话"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log.verbose("DEINIT \(className)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.keyboardDismissMode = .onDrag
        tableView.register(cellWithClass: TopicCommentCell.self)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        navigationItem.leftBarButtonItem?.tintColor = ThemeStyle.style.value.tintColor

        let headerView = UILabel().hand.config { headerView in
            headerView.text = "下拉关闭查看"
            headerView.sizeToFit()
            headerView.width = tableView.width
            headerView.textAlignment = .center
            headerView.textColor = .gray
            headerView.height = 44
            headerView.font = UIFont.systemFont(ofSize: 12)
        }

        tableView.tableHeaderView = headerView
        tableView.contentInset = UIEdgeInsets(top: -44, left: 0, bottom: 0, right: 0)
    }
    
}

// MARK: - UITableViewDelegate
extension ViewDialogViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: TopicCommentCell.self)!
        let comment = comments[indexPath.row]
        cell.comment = comment
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        (tableView.tableHeaderView as? UILabel)?.text = scrollView.contentOffset.y <= -(tableView.contentInset.top + 100) ? "松开关闭查看" : "下拉关闭查看"
    }
    
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 下拉关闭
        if scrollView.contentOffset.y <= -(tableView.contentInset.top + 100) {
            // 让scrollView 不弹跳回来
            scrollView.contentInset = UIEdgeInsets(top: -1 * scrollView.contentOffset.y, left: 0, bottom: 0, right: 0)
            scrollView.isScrollEnabled = false
            navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}
