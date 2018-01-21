import Foundation
import StoreKit

struct RequestReview {

    private struct Keys {
        static let runIncrementerSetting = "numberOfRuns"
        static let minimumRunCount = 30
    }

    // app 运行次数计数器
    private func incrementAppRuns() -> Int {
        let runs = getRunCounts() + 1
        UserDefaults.save(at: runs, forKey: Keys.runIncrementerSetting)
        return runs
    }

    // 从 UserDefaults 里读取运行次数并返回。
    private func getRunCounts () -> Int {
        let savedRuns = UserDefaults.get(forKey: Keys.runIncrementerSetting) as? Int ?? 1
        log.info("已运行\(savedRuns)次")
        return savedRuns
    }

    public func showReview() {
        let runs = incrementAppRuns()

        log.verbose("请求显示评分")
        // 运行次数 大于 10， 并且 运行次数 % 20 == 0
        // 第一次请求时机是第十次运行
        // 之后每运行 250 次请求一次
        // 但不一定触发
        if (runs == Keys.minimumRunCount || runs % 250 == 0) {
            if #available(iOS 10.3, *) {
                //                 #if !DEBUG
                //                #endif
                    log.verbose("已请求评分")
                    SKStoreReviewController.requestReview()
            } else {
                let alertVC = UIAlertController(
                    title: "喜欢 \(UIApplication.appDisplayName())？",
                    message: "喜欢使用 \(UIApplication.appDisplayName()) 吗?，花一点时间为其评分？非常感谢您的支持！",
                    preferredStyle: .alert
                )
                alertVC.addAction(UIAlertAction(title: "评分", style: .default, handler: { _ in
                    UIApplication.appReviewPage(with: Constants.Config.AppID)
                }))
                alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                AppWindow.shared.window.currentViewController()?.present(alertVC, animated: true, completion: nil)
            }
        } else {
            log.verbose("请求评分所需的运行次数不足！")
        }
    }
}
