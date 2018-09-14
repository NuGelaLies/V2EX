import UIKit

class IgnoreWordsViewController: UICollectionViewController {

    
    private struct Metric {
        static let stateHeight: CGFloat = 60
    }
    
    // MARK: - UI
    
    private lazy var stateLabel: UIInsetLabel = {
        let view = UIInsetLabel()
        view.text = "含有屏蔽词的主题标题将不出现在时间线上, 屏蔽词过多时可能影响丝毫加载速度"
        view.numberOfLines = 0
        view.textColor = UIColor.hex(0x666666)
        view.font = UIFont.systemFont(ofSize: 13)
        view.contentInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        view.textAlignment = .center
        view.isHidden = true
        self.view.addSubview(view)
        return view
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let view = UILabel()
        view.text = "暂未添加任何屏蔽词\n\n点击右上角 \"+\" 按钮添加需要屏蔽的关键字"
        view.textAlignment = .center
        view.isHidden = true
        view.textColor = UIColor.hex(0x666666)
        view.font = UIFont.systemFont(ofSize: 15)
        view.numberOfLines = 0
        self.view.addSubview(view)
        return view
    }()
    
    // MARK: - Propertys
    
    private var ignoreWords: [String] = []
    
    private var stateHeight: CGFloat {
        if #available(iOS 11, *) {
            return AppWindow.shared.window.safeAreaInsets.bottom + Metric.stateHeight
        } else {
            return Metric.stateHeight
        }
    }
    
    // MARK: - View Life Cycle
    
    init() {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 0)
        layout.cellSpacing = 5
        layout.minimumLineSpacing = 5
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeStyle.style.value.statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "主题屏蔽"
        view.backgroundColor = ThemeStyle.style.value.whiteColor
        
        if let words = UserDefaults.get(forKey: Constants.Keys.ignoreWords) as? [String] {
            ignoreWords = words
        }
        
        setupCollectionView()
        setupConstraints()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, action: { [weak self] in
            let alertVC = UIAlertController(title: "添加屏蔽关键词", message: "一个关键字至少两个字符, 如需同时添加多个, 请用英文逗号(,)隔开", preferredStyle: .alert)
            alertVC.addTextField(configurationHandler: { textField in
                textField.placeholder = "请输入需要屏蔽的关键字"
                textField.enablesReturnKeyAutomatically = true
            })
            
            let addAction = UIAlertAction(title: "添加", style: .default, handler: { [weak self] _ in
                guard let `self` = self,
                    let text = alertVC.textFields?.first?.text?.trimmed else {
                        return
                }
                var splitWords = text.components(separatedBy: ",")
                if splitWords.count == 1 {
                    splitWords = text.components(separatedBy: "，")
                }
                // 非 Nil && 关键词大于1 && 已有此不包含
                var words = splitWords.map { $0.trimmed }.filter { $0.isNotEmpty && $0.count > 1 && self.ignoreWords.contains($0).not }
                words = Array(Set(words))
                guard words.count.boolValue else { return }
                self.ignoreWords.append(contentsOf: words)
                self.collectionView?.reloadData()
                self.saveToLocalIgnoreWords()
                log.info(words)
            })
            
            _ = alertVC.textFields?.first?.rx
                .text
                .filterNil()
                .takeUntil(alertVC.rx.deallocated)
                .map { $0.trimmed }
                .map { $0.isNotEmpty && $0.count > 1 }
                .bind(to: addAction.rx.isEnabled)
            
            alertVC.addAction(addAction)
            
            alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self?.present(alertVC, animated: true, completion: nil)
        })
        navigationItem.rightBarButtonItem?.tintColor = ThemeStyle.style.value.tintColor
    }
    
    deinit {
        log.info(className + " Deinit")
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        collectionView?.register(WordCell.self, forCellWithReuseIdentifier: WordCell.description())
        collectionView?.backgroundColor = ThemeStyle.style.value.whiteColor
        
        collectionView?.height -= stateHeight
    }
    
    private func setupConstraints() {
        stateLabel.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(stateHeight)
        }
        
        placeholderLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension IgnoreWordsViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        placeholderLabel.isHidden = ignoreWords.count.boolValue
        stateLabel.isHidden = placeholderLabel.isHidden.not
        return ignoreWords.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WordCell.description(), for: indexPath) as! WordCell
        cell.title = ignoreWords[indexPath.row]
        
        cell.deleteHandle = { [weak self] cell in
            guard let indexPath = self?.collectionView?.indexPath(for: cell) else { return }
            self?.ignoreWords.remove(at: indexPath.row)
            self?.collectionView?.deleteItems(at: [indexPath])
            self?.saveToLocalIgnoreWords()
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension IgnoreWordsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = ignoreWords[indexPath.row]
        let w = item.toWidth(fontSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        return CGSize(width: w + 50, height: 30)
    }
}

// MARK: - Local
extension IgnoreWordsViewController {
    
    private func readLocalIgnoreWords() {
        guard let ignoreWords = UserDefaults.get(forKey: Constants.Keys.ignoreWords) as? [String] else {
            return
        }

        self.ignoreWords = ignoreWords
        collectionView?.reloadData()
    }

    private func saveToLocalIgnoreWords() {

        UserDefaults.save(at: ignoreWords, forKey: Constants.Keys.ignoreWords)
        collectionView?.reloadData()
    }
}
