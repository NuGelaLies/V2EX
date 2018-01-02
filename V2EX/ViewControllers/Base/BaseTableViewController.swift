import UIKit

class BaseTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = ThemeStyle.style.value.bgColor
        tableView.separatorColor = ThemeStyle.style.value.borderColor
    }

    deinit {
        log.verbose(className + " Deinit")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }
}
