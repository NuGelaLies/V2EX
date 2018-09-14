import UIKit

/// A light-weight UITextView subclass that adds support for placeholder.
@IBDesignable open class UIPlaceholderTextView: UITextView {

    // MARK: - Private Properties

    private var placeholderAttributes: [NSAttributedString.Key: Any] {

        var placeholderAttributes = [NSAttributedString.Key: Any]()

        self.typingAttributes.forEach { (key, value) in
            let attributedStringKey = key
            placeholderAttributes[attributedStringKey] = value
        }

        if placeholderAttributes[NSAttributedString.Key.font] == nil {
            placeholderAttributes[NSAttributedString.Key.font] = self.typingAttributes[NSAttributedString.Key.font] ?? self.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        }

        if placeholderAttributes[NSAttributedString.Key.paragraphStyle] == nil {

            let typingParagraphStyle = self.typingAttributes[NSAttributedString.Key.paragraphStyle]
            if typingParagraphStyle == nil {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = self.textAlignment
                paragraphStyle.lineBreakMode = self.textContainer.lineBreakMode
                placeholderAttributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
            } else {
                placeholderAttributes[NSAttributedString.Key.paragraphStyle] = typingParagraphStyle
            }
        }

        placeholderAttributes[NSAttributedString.Key.foregroundColor] = self.placeholderColor

        return placeholderAttributes
    }

    private var placeholderInsets: UIEdgeInsets {

        let placeholderInsets = UIEdgeInsets(top: self.contentInset.top + self.textContainerInset.top,
                                             left: self.contentInset.left + self.textContainerInset.left + self.textContainer.lineFragmentPadding,
                                             bottom: self.contentInset.bottom + self.textContainerInset.bottom,
                                             right: self.contentInset.right + self.textContainerInset.right + self.textContainer.lineFragmentPadding)
        return placeholderInsets
    }

    private lazy var placeholderLayoutManager: NSLayoutManager = NSLayoutManager()

    private lazy var placeholderTextContainer: NSTextContainer = NSTextContainer()

    // MARK: - Open Properties

    /// The attributed string that is displayed when there is no other text in the placeholder text view. This value is `nil` by default.
    @NSCopying open var attributedPlaceholder: NSAttributedString? {
        didSet {
            guard self.isEmpty == true else {
                return
            }
            self.setNeedsDisplay()
        }
    }

    /// Determines whether or not the placeholder text view contains text.
    open var isEmpty: Bool { return self.text.isEmpty }

    /// The string that is displayed when there is no other text in the placeholder text view. This value is `nil` by default.
    @IBInspectable open var placeholder: NSString? {
        get {
            return self.attributedPlaceholder?.string as NSString?
        }
        set {
            if let newValue = newValue as String? {
                self.attributedPlaceholder = NSAttributedString(string: newValue, attributes: self.placeholderAttributes)
            } else {
                self.attributedPlaceholder = nil
            }
        }
    }

    /// The color of the placeholder. This property applies to the entire placeholder string. The default placeholder color is `UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)`.
    @IBInspectable open var placeholderColor: UIColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.6) {
        didSet {
            if let placeholder = self.placeholder as String? {
                self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: self.placeholderAttributes)
            }
        }
    }

    // MARK: - Superclass Properties

    open override var attributedText: NSAttributedString! { didSet { self.setNeedsDisplay() } }

    open override var bounds: CGRect { didSet { self.setNeedsDisplay() } }

    open override var contentInset: UIEdgeInsets { didSet { self.setNeedsDisplay() } }

    open override var font: UIFont? {
        didSet {
            if let placeholder = self.placeholder as String? {
                self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: self.placeholderAttributes)
            }
        }
    }

    open override var textAlignment: NSTextAlignment {
        didSet {
            if let placeholder = self.placeholder as String? {
                self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: self.placeholderAttributes)
            }
        }
    }

    open override var textContainerInset: UIEdgeInsets { didSet { self.setNeedsDisplay() } }

    open override var typingAttributes: [NSAttributedString.Key : Any] {
        didSet {
            if let placeholder = self.placeholder as String? {
                self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: self.placeholderAttributes)
            }
        }
    }

    // MARK: - Object Lifecycle

    deinit {
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: self)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitializer()
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        self.commonInitializer()
    }

    // MARK: - Superclass API

    open override func caretRect(for position: UITextPosition) -> CGRect {

        guard text.isEmpty, let attributedPlaceholder = self.attributedPlaceholder else {
            return super.caretRect(for: position)
        }

        if self.placeholderTextContainer.layoutManager == nil {
            self.placeholderLayoutManager.addTextContainer(placeholderTextContainer)
        }

        let placeholderTextStorage = NSTextStorage(attributedString: attributedPlaceholder)
        placeholderTextStorage.addLayoutManager(placeholderLayoutManager)

        self.placeholderTextContainer.lineFragmentPadding = textContainer.lineFragmentPadding
        self.placeholderTextContainer.size = textContainer.size

        self.placeholderLayoutManager.ensureLayout(for: placeholderTextContainer)

        var caretRect = super.caretRect(for: position)

        caretRect.origin.x = placeholderLayoutManager.usedRect(for: placeholderTextContainer).origin.x + placeholderInsets.left

        return caretRect
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard isEmpty else { return }
        guard let attributedPlaceholder = self.attributedPlaceholder else { return}

        let placeholderRect = rect.inset(by: placeholderInsets)
        attributedPlaceholder.draw(in: placeholderRect)
    }

    // MARK: - Private API

    private func commonInitializer() {
        contentMode = .topLeft

        NotificationCenter.default.addObserver(self, selector: #selector(UIPlaceholderTextView.handleTextViewTextDidChangeNotification(_:)), name: UITextView.textDidChangeNotification, object: self)
    }

    @objc internal func handleTextViewTextDidChangeNotification(_ notification: Notification) {
        guard let object = notification.object as? UIPlaceholderTextView, object === self else {
            return
        }
        setNeedsDisplay()
    }
}
