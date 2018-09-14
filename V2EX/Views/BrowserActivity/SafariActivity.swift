import Foundation
import UIKit

public class SafariActivity: BrowserActivity {

    override public var activityTitle: String? {
        return "在 Safari 中打开"
    }

    override public var activityImage: UIImage? {
        return #imageLiteral(resourceName: "safariActivity")
    }
    
    override public var activityType: UIActivity.ActivityType {
        return UIActivity.ActivityType.openInSafari
    }
}
