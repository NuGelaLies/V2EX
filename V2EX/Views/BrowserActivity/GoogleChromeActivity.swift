import Foundation
import UIKit

public class GoogleChromeActivity: BrowserActivity {

    static var isChromeInstalled: Bool {
        return UIApplication.shared.canOpenURL(URL(string: "googlechrome://")!)
    }

    override var foundURL: URL? {
        didSet {
            if let nsURL = NSURL(string: foundURL?.absoluteString ?? " "),
                let googleScheme = nsURL.scheme?.replacingOccurrences(of: "http", with: "googlechrome"),
                let resourceSpecifier = nsURL.resourceSpecifier {
                urlToOpen = URL(string: googleScheme + ":" + resourceSpecifier)
            }
        }
    }

    override public var activityTitle: String? {
        return "在 Chrome 中打开"
    }

    override public var activityImage: UIImage? {
        return #imageLiteral(resourceName: "chromeActivity")
    }

    override public var activityType: UIActivity.ActivityType {
        return UIActivity.ActivityType.openInGoogleChrome
    }
}
