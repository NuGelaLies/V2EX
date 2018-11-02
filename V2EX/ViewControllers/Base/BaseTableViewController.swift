import UIKit

class BaseTableViewController: UITableViewController, InteractivePopProtocol {
    
    var interactivePopDisabled: Bool = false
    
    var disabled: Bool {
        return interactivePopDisabled
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTheme()
    }
    
    func setupTheme() {
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.tableView.backgroundColor = theme.bgColor
                self?.tableView.separatorColor = theme.borderColor
                self?.navigationItem.leftBarButtonItem?.tintColor = ThemeStyle.style.value.tintColor
            }.disposed(by: rx.disposeBag)
    }
    
    deinit {
        log.verbose(className + " Deinit")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }
}
