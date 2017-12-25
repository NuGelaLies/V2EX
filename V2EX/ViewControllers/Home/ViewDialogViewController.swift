import Foundation
import UIKit

class ViewDialogViewController: UITableViewController {

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
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = ThemeStyle.style.value.bgColor
        tableView.keyboardDismissMode = .onDrag
        tableView.register(cellWithClass: TopicCommentCell.self)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

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
        tableView.contentInset = UIEdgeInsetsMake(-44, 0, 0, 0)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
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
            scrollView.contentInset = UIEdgeInsetsMake(-1 * scrollView.contentOffset.y, 0, 0, 0)
            scrollView.isScrollEnabled = false
            navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}
