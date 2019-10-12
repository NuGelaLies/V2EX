import Foundation
import Alamofire

enum CaptchaType: String {
    case signin = "/signin"
    case forgot = "/forgot"
}

enum PrimaryKeyType {
    case id(Int), username(String)
    
    var param: String {
        switch self {
        case .id(let id):
            return "id=\(id)"
        case .username(let username):
            return "username=\(username)"
        }
    }
}

// V2EX js
// https://www.v2ex.com/static/js/v2ex.js?v=2658dbd9f54ebdeb51d27a0611b2ba96
//
// 定义所有的请求接口


enum API {

    // 通用
    case currency(href: String)

    // 获取 once
    case once

    // MARK: - 登录注册相关接口

    // 获取验证码
    case captcha(type: CaptchaType)
    // 获取验证码
    case captchaImageData(once: String)
    // 登录
    case signin(dict: [String: String])
    // Google 登录
    case googleSignin(once: String)
    // 两步验证
    case twoStepVerification(code: String, once: String)
    // 忘记密码
    case forgot(dict: [String: String])
    // 注册
    case signup(dict: [String: String])

    // MARK: - 用户操作相关接口

    // 登录奖励
    case loginReward(once: String?)
    // 上传头像
    case updateAvatar(localURL: String, once: String)
    // 账号信息
    case memberIntro(primartKeyType: PrimaryKeyType)
    // 特别关注
    case following
    // 我收藏的收藏
    case myFavorites(page: Int)
    // 获取通知消息
    case notifications(page: Int)
    // 删除通知
    case deleteNotification(notifacationID: String, once: String)
    // 绑定手机
    case bindPhone(callingCode: String, phoneNumber: String, password: String, once: String)
    // 取消屏蔽
    case unblock(userID: Int, t: Int)
    
    // MARK: - 节点操作相关接口

    // 我的节点
    case myNodes
    // 全部节点
    case nodes
    /// 节点详情
    case nodeDetail(href: String, page: Int)


    // MARK: - 会员相关接口

    // 会员首页
    case memberHome(username: String)
    // 会员主题
    case memberTopics(username: String, page: Int)
    // 会员回复
    case memberReplys(username: String, page: Int)
    // 最近的主题
    case recentTopics(page: Int)

    // MARK: - 主题相关接口
    // 主题列表
    case topics(href: String?)
    // 主题详情
    case topicDetail(topicID: String, page: Int)
    // 发表主题回复
    case comment(topicID: String, dict: [String: String])
    // 创建主题
    case createTopic(nodename: String, dict: [String: String])
    // 搜索主题
    case search(query: String, offset: Int, size: Int, sortType: String)
    // 收藏主题
    case favoriteTopic(topicID: String, token: String)
    // 取消收藏主题
    case unfavoriteTopic(topicID: String, token: String)
    // 感谢主题
    case thankTopic(topicID: String, token: String)
    // 忽略主题
    case ignoreTopic(topicID: String, once: String)
    // 取消忽略主题
    case unignoreTopic(topicID: String, once: String)
    // 感谢回复
    case thankReply(replyID: String, token: String)
    // 忽略回复
    case ignoreReply(replyID: String, once: String)
    // 预览 Markdown
    case previewTopic(md: String, once: String)
    // 报告主题
    case reportTopic(topicID: String, token: String)

    // MARK: - 其他

    // 关于
    case about

    // 上传图片
    case uploadPicture(localURL: String)

    // 源码地址
    case codeRepo
    
    // MARK: - 百度 OCR
    
    // 获取 Access Token
    case baiduAccessToken(clientId: String, clientSecret: String)
    
    // OCR 识别
    case baiduOCRRecognize(accessToken: String, imgBase64: String)
    
    // block List
    case blockList
    
    // 消息通知页面
    case atomFeed
    
    // 添加需要通知服务的用户
    case addUser(feedURL: String, name: String)
    case userStatus(username: String)
    case userLogout(username: String)
}

extension API: TargetType {
    
    /// The target's base `URL`.
    var baseURL: String {
        switch self {
        case .codeRepo:
            return "https://github.com/Joe0708/V2EX"
        case .search:
            return "https://www.sov2ex.com/api/search"
        case .uploadPicture:
            return "https://sm.ms/api/v2"
        case .baiduAccessToken, .baiduOCRRecognize:
            return "https://aip.baidubce.com"
        case .addUser, .userStatus, .userLogout:
            return "http://123.207.3.59"
//            return "http://localhost:8080"
        default:
            return Constants.Config.baseURL
        }
    }
    
    var route: Route {
        switch self {
        case .currency(let href):
            return .get(href)
        case .topics(let href):
            return .get(href ?? "")
        case .recentTopics(let page):
            return .get("/recent?p=\(page)")
        case .topicDetail(let topicID, let page):
            return .get("/t/\(topicID)?p=\(page)")
        case .captcha(let type):
            return .get(type.rawValue)
        case .captchaImageData(let once):
            return .get("/_captcha?once=\(once)")
        case .once:
            return .get("/signin")
        case .signin:
            return .post("/signin")
        case .googleSignin(let once):
            return .get("/auth/google?once=\(once)")
        case .twoStepVerification:
            return .post("/2fa")
        case .forgot:
            return .post("/forgot")
        case .signup:
            return .post("/signup")
        case .loginReward(let once):
            var url = "/mission/daily/redeem"
            if let `once` = once {
                url.append("?once=\(once)")
            }
            return .get(url)
        case .updateAvatar:
            return .post("/settings/avatar")
        case .memberIntro(let primaryType):
//            memberIntro(primartKeyType: PrimaryKeyType)
            return .get("/api/members/show.json?\(primaryType.param)")
        case .nodes:
            return .get("/api/nodes/all.json")
        case let .nodeDetail(href, page):
            return .get("\(href)?p=\(page)")
        // return .get("/planes")
        case .myNodes:
            return .get("/my/nodes")
        case .following:
            return .get("/my/following")
        case .myFavorites(let page):
            return .get("/my/topics?p=\(page)")
        case .about:
            return .get("/about")
        case .comment(let topicID, _):
            return .post("/t/\(topicID)")
        case .notifications(let page):
            return .get("/notifications?p=\(page)")
        case .atomFeed:
            return .get("/notifications")
        case let .deleteNotification(notifacationID, once):
            return .post("/delete/notification/\(notifacationID)?once=\(once)")
        case .bindPhone:
            return .post("/settings/phone")
        case let .unblock(userID, t):
            return .get("/unblock/\(userID)?t=\(t)")
        case .memberHome(let username):
            return .get("/member/\(username)")
        case .memberTopics(let username, let page):
            return .get("/member/\(username)/topics?p=\(page)")
        case .memberReplys(let username, let page):
            return .get("/member/\(username)/replies?p=\(page)")
        case .createTopic(let nodename, _):
            return .post("/new/\(nodename)")
        case let .favoriteTopic(topicID, token):
            return .get("/favorite/topic/\(topicID)?t=\(token)")
        case let .unfavoriteTopic(topicID, token):
            return .get("/unfavorite/topic/\(topicID)?t=\(token)")
        case let .thankTopic(topicID, token):
            return .post("/thank/topic/\(topicID)?t=\(token)")
        case let .reportTopic(topicID, token):
            return .get("/report/topic/\(topicID)?t=\(token)")
        case let .ignoreTopic(topicID, once):
            return .get("/ignore/topic/\(topicID)?once=\(once)")
        case let .unignoreTopic(topicID, once):
            return .get("/unignore/topic/\(topicID)?once=\(once)")
        case let .thankReply(replyID, token):
            return .post("/thank/reply/\(replyID)?t=\(token)")
        case let .ignoreReply(replyID, once):
            return .post("/ignore/reply/\(replyID)?once=\(once)")
        case let .previewTopic(md, once):
            return .post("/preview/markdown?md=\(md)&once=\(once)&syntax=1")
        case .uploadPicture:
            return .post("/upload")
        case .baiduAccessToken:
            return .post("/oauth/2.0/token")
        case .baiduOCRRecognize:
            return .post("/rest/2.0/ocr/v1/general")
        case .addUser:
            return .post("/user")
        case .userStatus(let username):
            return .get("/user/status/" + username)
        case .userLogout(let username):
            return .get("/user/logout/" + username)
        default:
            return .get("")
        }
    }
    
    /// The parameters to be encoded in the request.
    var parameters: [String : Any]? {
        var param: [String: Any] = [:]
        switch self {
        case .signin(let dict),
             .forgot(let dict),
             .signup(let dict),
             .comment(_, let dict),
             .createTopic(_, let dict):
            param = dict
        case .twoStepVerification(let code, let once):
            param["code"] = code
            param["once"] = once
        case let .search(query, offset, size, sortType):
            param["q"] = query
            param["from"] = offset
            param["size"] = size
            param["sort"] = sortType
        case .updateAvatar(_, let once):
            param["once"] = once
        case let .bindPhone(callingCode, phoneNumber, password, once):
            param["once"] = once
            param["new_calling_code"] = callingCode // 86_CN
            param["new_phone_number"] = phoneNumber
            param["p"] = password
        case let .baiduAccessToken(clientId, clientSecret):
            param["grant_type"] = "client_credentials"
            param["client_id"] = clientId
            param["client_secret"] = clientSecret
        case let .baiduOCRRecognize(accessToken, imgBase64):
            param["access_token"] = accessToken
            param["image"] = imgBase64
            param["language_type"] = "ENG"
            param["probability"] = "true"
//            param["url"] = ""
        case let .addUser(feedURL, name):
            param["feedURL"] = feedURL
            param["name"] = name
        default:
            return nil
        }
        return param
    }
    
    /// The method used for parameter encoding.
    var parameterEncoding: ParameterEncoding {
        return Alamofire.URLEncoding()
    }
    
    private enum UserAgentType {
        case phone, pad
        
        var description: String {
            switch self {
            case .phone:
               return "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.3 Mobile/14E277 Safari/603.1.30"
            case .pad:
                return "Mozilla/5.0 (iPad; CPU OS 10_3 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.3 Mobile/14E277 Safari/603.1.30"
            }
        }
    }
    
    // Returns HTTP header values.
    var httpHeaderFields: [String: String]? {
        var headers: [String: String] = [:]
        headers["User-Agent"] = UserAgentType.phone.description
        switch self {
        case .signin, .forgot, .createTopic, .updateAvatar:
            headers["Referer"] = defaultURLString
        case .loginReward:
            headers["Referer"] = baseURL + "/mission/daily"
        case .comment:
            if UIDevice.current.isPad {
                headers["User-Agent"] = UserAgentType.pad.description
            }
        case .blockList, .atomFeed:
            headers["User-Agent"] = UserAgentType.pad.description
        default:
            break
        }
        return headers
    }
    
    var useCache: Bool {
        switch self {
        case .nodes, .memberIntro, .blockList:
            return true
        default:
            return false
        }
    }
    
    /// The type of HTTP task to be performed.
    var task: Task {
        switch self {
        case .uploadPicture(let localURL):
            return .upload(.file(URL(fileURLWithPath: localURL), "smfile"))
        case .updateAvatar(let localURL, _):
            return .upload(.file(URL(fileURLWithPath: localURL), "avatar"))
        default:
            return .request
        }
    }
}

