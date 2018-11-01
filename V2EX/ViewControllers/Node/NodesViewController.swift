import UIKit
import RxSwift
import RxCocoa

class NodesViewController: DataViewController, NodeService {

    // MARK: - UI
    
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        layout.minimumInteritemSpacing = 15
        layout.headerReferenceSize = CGSize(width: self.view.width, height: 40)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .white
        view.dataSource = self
        view.delegate = self
        view.register(NodeCell.self, forCellWithReuseIdentifier: NodeCell.description())
        view.register(NodeHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NodeHeaderView.description())
        self.view.addSubview(view)
        return view
    }()

    // MARK: - Propertys

    private var nodeCategorys: [NodeCategoryModel] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
    }

    // MARK: - Setup

    override func setupRx() {
        ThemeStyle.style.asObservable()
            .subscribeNext { [weak self] theme in
                self?.collectionView.backgroundColor = theme.whiteColor
            }.disposed(by: rx.disposeBag)

        NotificationCenter.default.rx
            .notification(UIContentSizeCategory.didChangeNotification)
            .subscribeNext { [weak self] _ in
                self?.collectionView.reloadData()
            }.disposed(by: rx.disposeBag)
    }

    override func setupSubviews() {
        navigationItem.title = "节点导航"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "search"), style: .plain) { [weak self] in
            let resultVC = AllNodesViewController()
            resultVC.title = "搜索节点"
            let nav = NavigationViewController(rootViewController: resultVC)
            nav.modalTransitionStyle = .crossDissolve
            self?.present(nav, animated: true, completion: nil)
        }
        navigationItem.rightBarButtonItem?.tintColor = ThemeStyle.style.value.tintColor
    }
    
    override func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: State Handle

    override func loadData() {
        fetchNodeNav()
    }

    override func hasContent() -> Bool {
        return nodeCategorys.count.boolValue
    }

    override func errorView(_ errorView: ErrorView, didTapActionButton sender: UIButton) {
        fetchNodeNav()
    }
}

// MARK: - Actions
extension NodesViewController {

    /// 获取导航节点
    private func fetchNodeNav() {
        if nodeCategorys.count.boolValue { return }

        startLoading()

        nodeNavigation(success: { [weak self] cates in
            self?.nodeCategorys = cates
            self?.endLoading()
            self?.fetchAllNode()
        }) { [weak self] error in
            self?.errorMessage = error
            self?.endLoading(error: NSError(domain: "V2EX", code: -1, userInfo: nil))
        }
    }
    
    /// 获取全部节点
    private func fetchAllNode() {
        // 提前获取数据
        GCD.runOnBackgroundThread { [weak self] in
            self?.nodes(success: {_ in}, failure: nil)
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension NodesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return nodeCategorys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nodeCategorys[section].nodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NodeCell.description(), for: indexPath) as! NodeCell
        cell.node = nodeCategorys[indexPath.section].nodes[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NodeHeaderView.description(), for: indexPath) as! NodeHeaderView
        headerView.title = nodeCategorys[indexPath.section].name
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let node = nodeCategorys[indexPath.section].nodes[indexPath.row]
        let nodeDetailVC = NodeDetailViewController(node: node)
        navigationController?.pushViewController(nodeDetailVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension NodesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let node = nodeCategorys[indexPath.section].nodes[indexPath.row]
        let w = node.title.toWidth(fontSize: UIFont.preferredFont(forTextStyle: .body).pointSize + 5)
        return CGSize(width: w, height: 30)
    }
}
