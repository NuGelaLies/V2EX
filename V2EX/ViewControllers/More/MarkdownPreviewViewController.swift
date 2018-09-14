import UIKit
import MarkdownView

class MarkdownPreviewViewController: BaseViewController {

    // MARK: - UI

    private lazy var markdownView: MarkdownView = {
        let view = MarkdownView()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        return view
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        activityIndicator.style = UIDevice.isiPad ? .whiteLarge : .white
        activityIndicator.color = .gray
        return activityIndicator
    }()

    // MARK: - Propertys

    public var markdownString: String


    // MARK: - View Life Cycle

    init(markdownString: String) {
        self.markdownString = markdownString
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "预览"


        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain) { [weak self] in
            self?.dismiss()
        }
        navigationItem.leftBarButtonItem?.tintColor = ThemeStyle.style.value.tintColor

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)

        markdownView.onRendered = { [weak self] _ in
            self?.activityIndicator.stopAnimating()
        }
    }

    // MARK: - Setup

    override func setupSubviews() {
        loadHTML()
    }

    override func setupConstraints() {
        markdownView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    /// MARK: - Actions
    
    private func loadHTML() {
        activityIndicator.startAnimating()
        markdownView.load(markdown: markdownString, enableImage: true)
    }
}
