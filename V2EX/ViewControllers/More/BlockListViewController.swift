import UIKit

class BlockListViewController: DataViewController, AccountService {
    
    /// MARK: - UI
    
    internal lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.register(cellWithClass: BlockedMemberCell.self)
        view.hideEmptyCells()
        view.rowHeight = 90
        view.separatorColor = ThemeStyle.style.value.borderColor
        self.view.addSubview(view)
        return view
    }()
    
    // MARK: - Propertys
    
    var accounts: [AccountModel] = []
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func loadData() {
        
        startLoading()
        blockedMember(success: { [weak self] accounts in
            self?.accounts = accounts
            self?.endLoading()
            self?.tableView.reloadData()
            self?.status = .noBlockUser
        }) { [weak self] error in
            self?.errorMessage = error
            self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
        }
    }
    
    override func hasContent() -> Bool {
        return accounts.count.boolValue
    }
    
    override func emptyView(_: EmptyView, didTapActionButton _: UIButton) {
        
    }
    
    override func errorView(_: ErrorView, didTapActionButton _: UIButton) {
        loadData()
    }
}

// MARK: - UITableViewDelegate && UITableViewDataSource
extension BlockListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: BlockedMemberCell.self)!
        cell.account = accounts[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let memberPageVC = MemberPageViewController(memberName: accounts[indexPath.row].username)
        navigationController?.pushViewController(memberPageVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let unfavoriteAction = UITableViewRowAction(
            style: .destructive,
            title: "取消屏蔽") { [weak self] _, indexPath in
                let account = self?.accounts[indexPath.row]
                guard let userID = account?.id else { return }
                HUD.show()
                self?.unblock(userID: userID, success: { [weak self] in
                    self?.accounts.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                    HUD.dismiss()
                    self?.endLoading()
                    }, failure: { error in
                        HUD.showError(error)
                        HUD.dismiss()
                })
        }
        return [unfavoriteAction]
    }

}
