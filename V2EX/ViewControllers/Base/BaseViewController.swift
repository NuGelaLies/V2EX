import UIKit
import RxSwift

class BaseViewController: ViewController, InteractivePopProtocol {

    var interactivePopDisabled: Bool = false

    // MARK: Initializing

    deinit {
        log.verbose("DEINIT: \(self.className)")
    }
    
    // MARK: Status Bar Style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }
    
    var disabled: Bool {
        return interactivePopDisabled
    }
    
    // MARK: Layout Constraints
    
    private(set) var didSetupConstraints = false
    
    override func viewDidLoad() {
//        view.backgroundColor = Theme.Color.bgColor

        setupSubviews()
        
        view.setNeedsUpdateConstraints()
        
        setupRx()

        setupTheme()
    }

    func setupTheme() {
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.view.backgroundColor = theme.bgColor
                self?.navigationItem.leftBarButtonItem?.tintColor = theme.tintColor
                self?.navigationItem.rightBarButtonItem?.tintColor = theme.tintColor
//                self?.navigationController?.navigationBar.barStyle = theme.barStyle
            }.disposed(by: rx.disposeBag)
    }
    
    override func updateViewConstraints() {
        if !didSetupConstraints {
            setupConstraints()
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }

    func setupSubviews() {
        // Override point
    }
    
    func setupConstraints() {
        // Override point
    }
    
    func setupRx() {
        // Override point
    }

    // MARK: Action
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}
