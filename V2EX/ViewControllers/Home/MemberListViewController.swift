//
//  MemberListViewController.swift
//  V2EX
//
//  Created by danxiao on 2017/10/24.
//  Copyright © 2017年 Joe. All rights reserved.
//

import UIKit

class MemberListViewController: BaseTableViewController {

    // MARK: - Propertys
    
    public var members: [MemberModel] = []
    
    public var callback: (([MemberModel]) -> Void)?
    

    // MARK: - View Life Cycle

    init(members: [MemberModel]) {
        super.init(style: .plain)
        self.members = members
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log.verbose("DEINIT MemberListViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "选择你要@的用户"
        
        tableView.allowsMultipleSelection = true
        tableView.setEditing(true, animated: true)
        tableView.tintColor = Theme.Color.globalColor
        tableView.rowHeight = 55
        tableView.register(cellWithClass: MemberCell.self)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            action: { [weak self] in
                self?.dismiss(animated: true, completion: { [weak self] in
                    self?.callback?([])
                })
        })
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "完成",
            style: .plain,
            action: { [weak self] in
                
                var memberList: [MemberModel] = []
                self?.tableView.indexPathsForSelectedRows?.forEach({ [weak self] indexPath in
                    if let member = self?.members[indexPath.row] {
                        memberList.append(member)
                    }
                })
                
                self?.dismiss(animated: true, completion: { [weak self] in
                    self?.callback?(memberList)
                })
        })
    }
}

// MARK: - UITableViewDelegate
extension MemberListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: MemberCell.self)!
        cell.textLabel?.text = members[indexPath.row].username
        cell.imageView?.setImage(urlString: members[indexPath.row].avatarSrc, placeholder: #imageLiteral(resourceName: "avatar"))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let type = UITableViewCell.EditingStyle.delete.rawValue | UITableViewCell.EditingStyle.insert.rawValue
        return UITableViewCell.EditingStyle(rawValue: type)!
    }
}

