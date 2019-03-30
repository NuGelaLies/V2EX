import UIKit

// MARK: - UITableView Extension
extension UITableView {

    /// Dequeue reusable UITableViewCell using class name
    ///
    /// - Parameter name: UITableViewCell type
    /// - Returns: UITableViewCell object with associated class name (optional value)
    public func dequeueReusableCell<T: UITableViewCell>(withClass name: T.Type) -> T? {
        return dequeueReusableCell(withIdentifier: String(describing: name)) as? T
    }

    public func dequeueReusableCell<T: UITableViewCell>(withClass name: T.Type, configure: (T) -> Void) -> T? {
        guard let cell = dequeueReusableCell(withIdentifier: String(describing: name)) as? T else { return nil }
        configure(cell)
        return cell
    }

    /// Dequeue reusable UITableViewCell using class name for indexPath
    ///
    /// - Parameters:
    ///   - name: UITableViewCell type.
    ///   - indexPath: location of cell in tableView.
    /// - Returns: UITableViewCell object with associated class name.
    public func dequeueReusableCell<T: UITableViewCell>(withClass name: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: String(describing: name), for: indexPath) as! T
    }

    public func dequeueReusableCell<T: UITableViewCell>(withClass name: T.Type, for indexPath: IndexPath, configure: (T) -> Void) -> T {
        let cell = dequeueReusableCell(withIdentifier: String(describing: name), for: indexPath) as! T
        configure(cell)
        return cell
    }

    /// Dequeue reusable UITableViewHeaderFooterView using class name
    ///
    /// - Parameter name: UITableViewHeaderFooterView type
    /// - Returns: UITableViewHeaderFooterView object with associated class name (optional value)
    public func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(withClass name: T.Type) -> T? {
        return dequeueReusableHeaderFooterView(withIdentifier: String(describing: name)) as? T
    }

    /// Register UITableViewHeaderFooterView using class name
    ///
    /// - Parameters:
    ///   - nib: Nib file used to create the header or footer view.
    ///   - name: UITableViewHeaderFooterView type.
    public func register<T: UITableViewHeaderFooterView>(nib: UINib?, withHeaderFooterViewClass name: T.Type) {
        register(nib, forHeaderFooterViewReuseIdentifier: String(describing: name))
    }

    /// Register UITableViewHeaderFooterView using class name
    ///
    /// - Parameter name: UITableViewHeaderFooterView type
    public func register<T: UITableViewHeaderFooterView>(headerFooterViewClassWith name: T.Type) {
        register(T.self, forHeaderFooterViewReuseIdentifier: String(describing: name))
    }

    /// Register UITableViewCell using class name
    ///
    /// - Parameter name: UITableViewCell type
    public func register<T: UITableViewCell>(cellWithClass name: T.Type) {
        register(T.self, forCellReuseIdentifier: String(describing: name))
    }

    /// Register UITableViewCell using class name
    ///
    /// - Parameters:
    ///   - nib: Nib file used to create the tableView cell.
    ///   - name: UITableViewCell type.
    public func register<T: UITableViewCell>(nib: UINib?, withCellClass name: T.Type) {
        register(nib, forCellReuseIdentifier: String(describing: name))
    }
}

// MARK: - UICollectionView Extension
public extension UICollectionView {

    enum ElementKind {
        case header
        case footer

        public init?(rawValue: String) {
            switch rawValue {
            case UICollectionView.elementKindSectionHeader: self = .header
            case UICollectionView.elementKindSectionFooter: self = .footer
            default: return nil
            }
        }

        public var value: String {
            switch self {
            case .header: return UICollectionView.elementKindSectionHeader
            case .footer: return UICollectionView.elementKindSectionFooter
            }
        }
    }

    func register(_ nib: UINib?, forSupplementaryViewOfKind kind: ElementKind, withReuseIdentifier identifier: String) {
        register(nib, forSupplementaryViewOfKind: kind.value, withReuseIdentifier: identifier)
    }

    func register(_ viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: ElementKind, withReuseIdentifier identifier: String) {
        register(viewClass, forSupplementaryViewOfKind: elementKind.value, withReuseIdentifier: identifier)
    }

    func dequeueReusableSupplementaryView(ofKind elementKind: ElementKind, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionReusableView {
        return dequeueReusableSupplementaryView(ofKind: elementKind.value, withReuseIdentifier: identifier, for: indexPath)
    }
}

