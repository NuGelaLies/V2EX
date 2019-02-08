import UIKit

@objc public protocol PagesControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            setViewController viewController: UIViewController,
                            atPage page: Int)
}

class PagesController: UIPageViewController {
    
    public let startPage = 0
    @objc public var setNavigationTitle = true
    
    public var enableSwipe = true {
        didSet {
            toggle()
        }
    }
    
    public var pages: [UIViewController] = []
    
    public var pagesCount: Int {
        return pages.count
    }
    
    @objc public private(set) var currentIndex = 0
    public weak var pagesDelegate: PagesControllerDelegate?
    
    public convenience init(_ pages: [UIViewController],
                            transitionStyle: UIPageViewController.TransitionStyle = .scroll,
                            navigationOrientation: UIPageViewController.NavigationOrientation = .horizontal,
                            options: [UIPageViewController.OptionsKey : AnyObject]? = nil) {
        self.init(
            transitionStyle: transitionStyle,
            navigationOrientation: navigationOrientation,
            options: options
        )
        
        add(pages)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        
        goTo(startPage)
    }
    
    // MARK: - Public methods
    open func goTo(_ index: Int) {
        if index >= 0 && index < pages.count {
            let direction: UIPageViewController.NavigationDirection = (index > currentIndex) ? .forward : .reverse
            let viewController = pages[index]
            currentIndex = index
            
            setViewControllers(
                [viewController],
                direction: direction,
                animated: true,
                completion: { [unowned self] finished in
                    self.pagesDelegate?.pageViewController(
                        self,
                        setViewController: viewController,
                        atPage: self.currentIndex
                    )
            })
            
            if setNavigationTitle {
                title = viewController.title
            }
        }
    }
    
    @objc open func moveForward() {
        goTo(currentIndex + 1)
    }
    
    @objc open func moveBack() {
        goTo(currentIndex - 1)
    }
    
    @objc dynamic open func add(_ viewControllers: [UIViewController]) {
        for viewController in viewControllers {
            addViewController(viewController)
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension PagesController: UIPageViewControllerDataSource {
    @objc open func pageViewController(_ pageViewController: UIPageViewController,
                                       viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = prevIndex(viewControllerIndex(viewController))
        return pages.at(index)
    }
    
    @objc open func pageViewController(_ pageViewController: UIPageViewController,
                                       viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index: Int? = nextIndex(viewControllerIndex(viewController))
        return pages.at(index)
    }
    
}

// MARK: - UIPageViewControllerDelegate
extension PagesController: UIPageViewControllerDelegate {
    @objc open func pageViewController(_ pageViewController: UIPageViewController,
                                       didFinishAnimating finished: Bool,
                                       previousViewControllers: [UIViewController],
                                       transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        
        guard let viewController = pageViewController.viewControllers?.last else {
            return
        }
        
        guard let index = viewControllerIndex(viewController) else {
            return
        }
        
        currentIndex = index
        
        if setNavigationTitle {
            title = viewController.title
        }
    
        pagesDelegate?.pageViewController(self, setViewController: pages[currentIndex], atPage: currentIndex)
    }
}

// MARK: - Private methods
private extension PagesController {
    func viewControllerIndex(_ viewController: UIViewController) -> Int? {
        return pages.index(of: viewController)
    }
    
    func toggle() {
        for subview in view.subviews {
            if let subview = subview as? UIScrollView {
                subview.isScrollEnabled = enableSwipe
                break
            }
        }
    }
    
    func addViewController(_ viewController: UIViewController) {
        pages.append(viewController)
        
        if pages.count == 1 {
            setViewControllers([viewController],
                               direction: .forward,
                               animated: true,
                               completion: { [unowned self] finished in
                                self.pagesDelegate?.pageViewController(self,
                                                                       setViewController: viewController,
                                                                       atPage: self.currentIndex)
            })
            if setNavigationTitle {
                title = viewController.title
            }
        }
    }
    
}

extension Array {
    func at(_ index: Int?) -> Element? {
        if let index = index , index >= 0 && index < endIndex {
            return self[index]
        } else {
            return nil
        }
    }
}

func nextIndex(_ x: Int?) -> Int? {
    return ((x)! + 1)
}

func prevIndex(_ x: Int?) -> Int? {
    return ((x)! - 1)
}
