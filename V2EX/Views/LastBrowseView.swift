import UIKit
import SwiftMessages

class LastBrowseView: MessageView {
    
    var cancelAction: (() -> Void)?
 
    @IBAction func cancel() {
        cancelAction?()
    }
    
}
