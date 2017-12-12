import Foundation
import Alamofire
import Kanna

let Network = Networking.shared

typealias Success = ((Data) -> Void)
typealias Failure = ((String) -> Void)

/// 网络状态
enum NetworkStatus {
    case unknown
    case notReachable
    case reachableViaWiFi
    case reachableViaWWAN
}

/// 处理所有网络请求
final class Networking {

    public static let shared = Networking()

    private var reachabilityManager: NetworkReachabilityManager?

    public var isWiFi: Bool {
        return reachabilityManager?.networkReachabilityStatus == .reachable(.ethernetOrWiFi)
    }

    private init() {
        Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 10
        Alamofire.SessionManager.default.session.configuration.timeoutIntervalForResource = 10
    }

    /// 监听网络
    public func networkListening(_ handle: ((NetworkStatus) -> Void)?) {

        reachabilityManager = NetworkReachabilityManager()
        reachabilityManager?.startListening()

        reachabilityManager?.listener = { status in
            switch status {
            case .notReachable:
                handle?(.notReachable)
            case .unknown :
                handle?(.unknown)
            case .reachable(.ethernetOrWiFi):
                handle?(.reachableViaWiFi)
            case .reachable(.wwan):
                handle?(.reachableViaWWAN)
            }
        }
    }

    /// 发起请求
    func request(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        target: API,
        success: Success?,
        failure: Failure?
        ) {

        GCD.runOnMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        guard let url = target.url else { return }

        switch target.task {
        case .request: // 普通请求操作

            Alamofire.request(url,
                              method: target.route.method,
                              parameters: target.parameters,
                              encoding: target.parameterEncoding,
                              headers: target.httpHeaderFields)
                .responseData(completionHandler: { [weak self] (dataResponse) in
                    self?.responseHandle(target: target, success: success, failure: failure, dataResponse: dataResponse)
                })
            break

        case .upload(.file(let fileUrl, let name)): // 上传请求
            
            Alamofire.upload(multipartFormData: { multipartFormData in
                // 拼接表单数据
                multipartFormData.append(fileUrl, withName: name)
                if let params = target.parameters as? [String: String] {
                    for (key, value) in params {
                        multipartFormData.append(value.data(using: .utf8)!, withName: key)
                    }
                }
            }, to: url, encodingCompletion: { (encodingResult: SessionManager.MultipartFormDataEncodingResult) in
                switch encodingResult {
                case let .success(request, _, _):
                    request.uploadProgress(closure: { progress in
                        log.info(progress)
                    })

                    request.responseData(completionHandler: { dataResponse in
                        self.responseHandle(target: target, success: success, failure: failure, dataResponse: dataResponse)
                    })
                case .failure(let error):
                    HUD.showTest(error.localizedDescription)
                    log.error(error.localizedDescription)
                }
            })
        default:
            break
        }
    }
}

// MARK: - Handle
extension Networking {

    // 请求响应统一处理
    fileprivate func responseHandle(file: StaticString = #file,
                                    function: StaticString = #function,
                                    line: UInt = #line,
                                    target: API,
                                    success: Success?,
                                    failure: Failure?,
                                    dataResponse: DataResponse<Data>) {

        let requestString = "\(target.route.method) \(String(describing: target.url)) \(target.parameters ?? [:]))"

        UIApplication.shared.isNetworkActivityIndicatorVisible = false

        let message =  "\(requestString) (\(dataResponse.response?.statusCode ?? -1))"

        switch dataResponse.result {
        case .success(let data):
            log.verbose("✅ SUCCESS: " + message, file: file, function: function, line: line)

            // 两步验证
            if let path = dataResponse.response?.url?.path, path.hasPrefix("/2fa") {
                NotificationCenter.default.post(.init(name: NSNotification.Name.V2.TwoStepVerificationName))
            }

            if let statusCode = dataResponse.response?.statusCode {
                if statusCode == 502 {
                    failure?("502 Bad Gateway")
                    return
                } else if statusCode == 404 {
                    failure?("404")
                    return
                }
            }

            // 主要处理如果网页跳转到登录页面，代表该页面查看需要登录
            switch target {
            // 忽略这些请求
            case .signin(_), .once, .captcha(_):
                break
            default:
                // 重定向到 signin ， 代表需要登录
                if (dataResponse.response?.url?.absoluteString ?? "").contains(API.signin(dict: [:]).defaultURLString) {
                    AccountModel.delete()
                    failure?("您要查看的页面需要先登录")
                    return
                }
            }
            success?(data)
        case .failure(let error):
            log.error("❌ FAILURE: \(message) \n \(error)", file: file, function: function, line: line)
            HUD.showTest(error.localizedDescription)
            failure?(error.localizedDescription)
        }
    }
}

extension Networking {

    public func htmlRequest(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        target: API,
        success: ((HTMLDocument) -> Void)?,
        failure: Failure?
        ) {
        request(target: target, success: { data in
            guard let html = HTML(html: data, encoding: .utf8) else {
                failure?("数据解析失败")
                return
            }

            if let once = html.xpath("//input[@name='once']").first?["value"] {
                AccountModel.saveOnce(once)
            }

            success?(html)
        }, failure: failure)
    }

    /// 不需要响应结果，  用于 感谢、删除通知评论时， data count = 0
    public func htmlRequestNotResponse(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        target: API,
        success: Action?,
        failure: Failure?
        ) {
        request(target: target, success: { data in
            success?()
        }, failure: failure)
    }
}
