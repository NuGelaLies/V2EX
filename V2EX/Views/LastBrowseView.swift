import UIKit
import SwiftMessages

class LastBrowseView: MessageView {
    
    var cancelAction: (() -> Void)?
    
    @IBOutlet private weak var backBtn: UIButton!
    
    @IBAction func cancel() {
        cancelAction?()
    }
    
    public var title: String? {
        set {
            backBtn.setTitle(newValue, for: .normal)
            backBtn.setTitle(newValue, for: .highlighted)
        }
        get {
            return backBtn.currentTitle
        }
    }

}
