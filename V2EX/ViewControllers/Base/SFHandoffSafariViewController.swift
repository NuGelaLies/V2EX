import SafariServices

open class SFHandoffSafariViewController: SFSafariViewController {

    override public init(url URL: URL, entersReaderIfAvailable: Bool) {
        super.init(url: URL, entersReaderIfAvailable: entersReaderIfAvailable)
        if userActivity == nil && URL.scheme != nil {
            userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        }
        userActivity?.webpageURL = URL
        delegate = self
    }

    convenience public init(url URL: URL) {
        self.init(url: URL, entersReaderIfAvailable: false)
    }
}

extension SFHandoffSafariViewController: SFSafariViewControllerDelegate {
    
    open func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if didLoadSuccessfully {
            controller.userActivity?.becomeCurrent()
        }
    }
    
    open func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.userActivity?.resignCurrent()
    }
    
}
