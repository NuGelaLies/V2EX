import Foundation
import Kanna

enum TopicFavoriteType {
    case detail, list
}

protocol TopicService: HTMLParseService {

    /// 获取 首页 数据
    ///
    /// - Parameters:
    ///   - success: 成功返回 nodes, topics, navigations
    ///   - failure: 失败
    func index(
        success: ((_ nodes: [NodeModel], _ topics: [TopicModel], _ rewardable: Bool) -> Void)?,
        failure: Failure?)

    /// 获取 最近 的分页数据
    ///
    /// - Parameters:
    ///   - success: 成功返回 topics
    ///   - failure: 失败
    func recentTopics(
        page: Int,
        success: ((_ topics: [TopicModel], _ maxPage: Int) -> Void)?,
        failure: Failure?)
    
    /// 获取 首页 主题数据
    ///
    /// - Parameters:
    ///   - href: href
    ///   - success: 成功返回 topics
    ///   - failure: 失败
    func topics(
        href: String,
        success: ((_ topics: [TopicModel], _ maxPage: Int) -> Void)?,
        failure: Failure?)

    /// 获取 主题 详情数据
    ///
    /// - Parameters:
    ///   - topic: topic
    ///   - success: 成功
    ///   - failure: 失败
    func topicDetail(
        topicID: String,
        success: ((_ topic: TopicModel, _ comments: [CommentModel], _ maxPage: Int) -> Void)?,
        failure: Failure?)

    /// 获取主题中更多评论
    ///
    /// - Parameters:
    ///   - topicID: 主题ID
    ///   - page: 获取页数
    ///   - success: 成功
    ///   - failure: 失败
    func topicMoreComment(
        topicID: String,
        page: Int,
        success: ((_ comments: [CommentModel]) -> Void)?,
        failure: Failure?)
    
    /// 发布评论
    ///
    /// - Parameters:
    ///   - once: 凭证
    ///   - topicID: 主题 id
    ///   - content: 回复内容
    ///   - success: 成功
    ///   - failure: 失败
    func comment(
        once: String,
        topicID: String,
        content: String,
        success: Action?,
        failure: Failure?)

    /// 上传图片到 SM.MS
    ///
    /// - Parameters:
    ///   - localURL: 图片本地URL
    ///   - success: 成功
    ///   - failure: 失败
    func uploadPicture(
        localURL: String,
        success: ((String) -> Void)?,
        failure: Failure?)

    /// 创建主题
    ///
    /// - Parameters:
    ///   - nodename: 节点名称
    ///   - title: 主题标题
    ///   - body: 主题正文
    ///   - success: 成功
    ///   - failure: 失败
    func createTopic(
        nodename: String,
        title: String,
        body: String?,
        success: Action?,
        failure: @escaping Failure)
    
    
    /// 搜索主题
    ///
    /// - Parameters:
    ///   - query: 关键字
    ///   - offset: 偏移量
    ///   - size: 一页大小
    ///   - sortType: 排序类型
    ///   - success: 成功
    ///   - failure: 失败
    func search(
        query: String,
        offset: Int,
        size: Int,
        sortType: SearchSortType,
        success: ((_ results: [SearchResultModel]) -> ())?,
        failure: Failure?)
    
    /// 忽略主题
    ///
    /// - Parameters:
    ///   - topicID: 主题id
    ///   - once: 凭证
    ///   - success: 成功
    ///   - failure: 失败
    func ignoreTopic(topicID: String,
                     once: String,
                     success: Action?,
                     failure: Failure?)
    
    /// 取消忽略主题
    ///
    /// - Parameters:
    ///   - topicID: 主题id
    ///   - once: 凭证
    ///   - success: 成功
    ///   - failure: 失败
    func unignoreTopic(topicID: String,
                     once: String,
                     success: Action?,
                     failure: Failure?)
    
    /// 收藏主题
    ///
    /// - Parameters:
    ///   - topicID: 主题id
    ///   - token: token
    ///   - success: 成功
    ///   - failure: 失败
    func favoriteTopic(topicFavoriteType: TopicFavoriteType,
                       topicID: String,
                       token: String,
                       success: Action?,
                       failure: Failure?)
    
    /// 取消收藏主题
    ///
    /// - Parameters:
    ///   - topicID: 主题id
    ///   - token: token
    ///   - success: 成功
    ///   - failure: 失败
    func unfavoriteTopic(topicFavoriteType: TopicFavoriteType,
                         topicID: String,
                         token: String,
                         success: Action?,
                         failure: Failure?)
    
    /// 感谢主题
    ///
    /// - Parameters:
    ///   - topicID: 主题id
    ///   - token: token
    ///   - success: 成功
    ///   - failure: 失败
    func thankTopic(topicID: String,
                    token: String,
                    success: Action?,
                    failure: Failure?)
    
    /// 感谢回复
    ///
    /// - Parameters:
    ///   - replyID: 回复id
    ///   - token: token
    ///   - success: 成功
    ///   - failure: 失败
    func thankReply(replyID: String,
                    token: String,
                    success: Action?,
                    failure: Failure?)
    
    /// 报告主题
    ///
    /// - Parameters:
    ///   - topicID: 主题id
    ///   - token: token
    ///   - success: 成功
    ///   - failure: 失败
    func reportTopic(topicID: String,
                    token: String,
                    success: Action?,
                    failure: Failure?)
}

extension TopicService {
    
    func index(
        success: ((_ nodes: [NodeModel], _ topics: [TopicModel], _ rewardable: Bool) -> Void)?,
        failure: Failure?) {
        Networking.shared.htmlRequest(target: .topics(href: nil), success: { html in
            
            //            let nodePath = html.xpath("//*[@id='Wrapper']/div/div[3]/div[2]/a")
            
            // 有通知 代表登录成功
            var isLogin = false
            var rewardable = false
            if let innerHTML = html.innerHTML {
                isLogin = innerHTML.contains("notifications")
                if  isLogin {
                    // 领取今日登录奖励
                    if let dailyHref = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[@class='inner']/a").first?["href"],
                        dailyHref == "/mission/daily" {
                        rewardable = true
                    }

                    if let account = self.parseLoginUser(html: html) {
                        account.save()
                    }
                } else {
                    AccountModel.delete()
                }
            }
            
            //  已登录 div[2] / 没登录 div[1]
            let nodePath = html.xpath("//*[@id='Wrapper']/div[@class='content']/div/div[\(isLogin ? 2 : 1)]/a")
            
            let nodes = nodePath.compactMap({ ele -> NodeModel? in
                guard let href = ele["href"],
                    let title = ele.content else {
                        return nil
                }
                let isCurrent = ele.className == "tab_current"
                
                return NodeModel(title: title, href: href, isCurrent: isCurrent)
            })
            
            let topics = self.parseTopic(html: html, type: .index)
            
            guard topics.count > 0 else {
                failure?("获取节点信息失败")
                return
            }
            
            success?(nodes, topics, rewardable)
        }, failure: failure)
    }

    func recentTopics(
        page: Int,
        success: ((_ topics: [TopicModel], _ maxPage: Int) -> Void)?,
        failure: Failure?) {

        Network.htmlRequest(target: .recentTopics(page: page), success: { html in
            let topics = self.parseTopic(html: html, type: .index)
            let page = self.parsePage(html: html)
            success?(topics, page.max)
        }, failure: failure)

    }
    
    func topics(
        href: String,
        success: ((_ topics: [TopicModel], _ maxPage: Int) -> Void)?,
        failure: Failure?) {
        
        log.info(href)
        Network.htmlRequest(target: .topics(href: href), success: { html in
            let topics = self.parseTopic(html: html, type: .nodeDetail)
            
            // 领取今日登录奖励
            if let dailyHref = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[@class='inner']/a").first?["href"],
                dailyHref == "/mission/daily" {
                NotificationCenter.default.post(.init(name: Notification.Name.V2.DailyRewardMissionName))
            }
            // Optimize: 区分数据解析失败 还是 没有数据
//            guard topics.count > 0 else {
//                failure?("获取节点信息失败")
//                return
//            }

            success?(topics, self.parsePage(html: html).max)
        }, failure: failure)
    }

    func topicDetail(
        topicID: String,
        success: ((_ topic: TopicModel, _ comments: [CommentModel], _ maxPage: Int) -> Void)?,
        failure: Failure?) {

        Network.htmlRequest(target: .topicDetail(topicID: topicID, page: 1), success: { html in
            
            guard let _ = html.xpath("//*[@id='Wrapper']//div[@class='header']/small/text()[2]").first?.text else {
                // 需要登录
                if let error = html.xpath("//*[@id='Wrapper']/div[2]/div[2]").first?.content {
                    failure?(error)
                    return
                }
                // 需要验证
                if let error = html.xpath("//*[@id='Main']/div/div//span[@class='negative'][text()]").first?.content {
                    failure?("访问被限制节点的内容之前，你的账号需要完成以下验证：\n\(error)")
                    return
                }
                // 被重定向到首页, 无法查看, 先这样处理
                if html.title == "V2EX" {
                    failure?("无法查看该主题，被重定向到首页")
                    return
                }
                failure?("数据解析失败")
                return
            }
            let topicContentPath = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[@class='cell']//div[@class='topic_content']")
//            let topicContentPath = html.xpath("//*[@id='Wrapper']//div[@class='topic_content']")
            let contentHTML = topicContentPath.first?.toHTML ?? ""
            let subpath = html.xpath("//*[@id='Wrapper']//div[@class='subtle']")
            let subtleHTML = subpath.compactMap { $0.toHTML }.joined(separator: "")
            var content = contentHTML + subtleHTML
            
            //            content = self.replacingIframe(text: content)
            // 添加 HTTPS: 头
            topicContentPath.first?.xpath(".//img").forEach({ ele in
                if let srcURL = ele["src"], srcURL.hasPrefix("//") {
                    content = content.replacingOccurrences(of: srcURL, with: Constants.Config.URIScheme + srcURL)
                }
            })

            let comments = self.parseComment(html: html)

            guard let userPath = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[@class='header']/div/a").first,
                let userAvatar = userPath.xpath("./img").first?["src"],
                let userhref = userPath["href"],
                let nodeEle = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[@class='header']/a[2]").first,
                let nodeTitle = nodeEle.content,
                let nodeHref = nodeEle["href"],
                let title = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[@class='header']/h1").first?.content else {
                    failure?("数据解析失败")
                    return
            }
            
            let member = MemberModel(username: userhref.lastPathComponent, url: userhref, avatar: userAvatar)
            let node = NodeModel(title: nodeTitle, href: nodeHref)
            var topic = TopicModel(member: member, node: node, title: title, href: "")

            // 获取 token
            if let atags = html.at_xpath("//*[@id='Wrapper']/div[@class='content']/div/div[@class='inner']"),
                let csrfTokenPath = atags.at_xpath(".//a[1]")?["href"] {
                let csrfToken = URLComponents(string: csrfTokenPath)?["t"]
                let isFavorite = csrfTokenPath.hasPrefix("/unfavorite")
                
                if let ignore = atags.at_xpath(".//a[last()]")?["onclick"] {
                    topic.isIgnore = ignore.contains("/unignore/topic/")
                }
                
                topic.token = csrfToken

                // 如果是登录状态 检查是否已经感谢和收藏
                if AccountModel.isLogin {
                    topic.isFavorite = isFavorite
                    let thankStr = html.xpath("//*[@id='topic_thank']").first?.content ?? ""
                    topic.isThank = thankStr != "感谢"
                }
            }
            
//            // 提取 Base64 密文，并解密添加到正文内容中
//            let contentClean = (topicContentPath.first?.content ?? "") + subpath.compactMap { $0.content }.joined()
//            let regular = try? NSRegularExpression(pattern: "(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)", options: .caseInsensitive)
//            if let res = regular?.matches(in: contentClean, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: contentClean.count)) {
//                let ciphertexts = res.map { contentClean.NSString.substring(with: $0.range)}
//                for text in ciphertexts {
//                    if let base64Data = Data(base64Encoded: text),
//                        let clearText = String(data: base64Data, encoding: .utf8),
//                        clearText.isNotEmpty {
//                        content = content.replacingOccurrences(of: text, with: text + " <span class='v2er'>(解码内容: \(clearText) - App 附加内容)</span>")
//                    }
//                }
//            }
            
            topic.lastReplyTime = html.xpath("//*[@id='Wrapper']/div[@class='content']/div[3]/div/span/text()").first?.content?.trimmed
            topic.once = self.parseOnce(html: html)
            topic.content = content
            topic.publicTime = html.xpath("//*[@id='Wrapper']/div/div[1]/div[1]/small/text()[2]").first?.content ?? ""
            
            // 报告主题需要的 token
            if let reportToken = html.at_xpath("//*[@id='Wrapper']/div[@class='content']/div/div[@class='inner']/div[@class='fr']/following-sibling::a[1]")?["onclick"]?.components(separatedBy: "';").first?.components(separatedBy: "=").last, let _ = reportToken.int {
                topic.reportToken = reportToken
            }
            let maxPage = html.xpath("//*[@id='Wrapper']/div/div[@class='box'][2]/div[last()]/a[last()]").first?.content?.int ?? 1
            success?(topic, comments, maxPage)
        }, failure: failure)
    }

    func topicMoreComment(
        topicID: String,
        page: Int,
        success: ((_ comments: [CommentModel]) -> Void)?,
        failure: Failure?) {

        Network.htmlRequest(target: .topicDetail(topicID: topicID, page: page), success: { html in
            let comments = self.parseComment(html: html)
            success?(comments)
        }, failure: failure)
    }


    func comment(
        once: String,
        topicID: String,
        content: String,
        success: Action?,
        failure: Failure?) {
        
        let params = [
            "content": content,
            "once": once
        ]
        
        Network.htmlRequest(target: .comment(topicID: topicID, dict: params), success: { html in
            guard let problem =  html.xpath("//*[@id='Wrapper']/div//div[@class='problem']/ul").first?.content else {
                success?()
                return
            }
            
            failure?(problem)
        }, failure: failure)
    }

    func uploadPicture(
        localURL: String,
        success: ((String) -> Void)?,
        failure: Failure?) {
        Network.request(target: .uploadPicture(localURL: localURL), success: { data in
            guard let resultDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                failure?("上传失败")
                return
            }

            guard (resultDict["code"] as? String) == "success",
            let dataDict = resultDict["data"] as? [String: Any],
            let url = dataDict["url"] as? String else {
                failure?("上传失败")
                return
            }
            success?(url)
        }, failure: failure)
    }

    func createTopic(
        nodename: String,
        title: String,
        body: String?,
        success: Action?,
        failure: @escaping Failure) {
        
        Network.htmlRequest(target: .createTopic(nodename: nodename, dict: [:]), success: { html in
            if let htmlStr = html.body?.toHTML {
                if htmlStr.contains("你的帐号刚刚注册") {
                    failure("你的帐号刚刚注册，暂时无法发帖。")
                    return                    
                }
            }
            guard let once = self.parseOnce(html: html) else {
                failure("操作失败，无法获取 once")
                return
            }
            let params = [
                "title": title,
                "content": body ?? "",
                "once": once,
                "syntax": "1" //文本标记语法, 0: 默认 1: Markdown
            ]
            Network.htmlRequest(target: .createTopic(nodename: nodename, dict: params), success: { html in
                guard let problem =  html.xpath("//*[@id='Wrapper']/div//div[@class='problem']/ul").first?.content else {
                    success?()
                    return
                }
                failure(problem)
            }, failure: failure)
        }, failure: failure)
        
    }
    
    func search(
        query: String,
        offset: Int,
        size: Int,
        sortType: SearchSortType,
        success: ((_ results: [SearchResultModel]) -> ())?,
        failure: Failure?) {
        Network.request(target: .search(query: query, offset: offset, size: size, sortType: sortType.rawValue), success: { data in
            let decoder = JSONDecoder()
            guard let response = try? decoder.decode(SearchResponeModel.self, from: data),
                let result = response.result else {
                    failure?("搜索失败")
                    return
            }
            success?(result)
        }, failure: failure)
    }
    
    func ignoreTopic(topicID: String,
                     once: String,
                     success: Action?,
                     failure: Failure?) {
        Network.htmlRequest(target: .ignoreTopic(topicID: topicID, once: once), success: { html in
            success?()
        }, failure: failure)
    }
    
    func unignoreTopic(topicID: String,
                     once: String,
                     success: Action?,
                     failure: Failure?) {
        Network.htmlRequest(target: .unignoreTopic(topicID: topicID, once: once), success: { html in
            success?()
        }, failure: failure)
    }
    
    func favoriteTopic(topicFavoriteType: TopicFavoriteType = .detail,
                       topicID: String,
                       token: String,
                       success: Action?,
                       failure: Failure?) {
        Network.htmlRequest(target: .favoriteTopic(topicID: topicID, token: token), success: { html in
            success?()
        }, failure: failure)
    }
    
    func unfavoriteTopic(topicFavoriteType: TopicFavoriteType = .detail,
                         topicID: String,
                         token: String,
                         success: Action?,
                         failure: Failure?) {
        
        guard topicFavoriteType == .list else {
            Network.htmlRequest(target: .unfavoriteTopic(topicID: topicID, token: token), success: { html in
                success?()
            }, failure: failure)
            return
        }
        
        Network.htmlRequest(target: .topicDetail(topicID: topicID, page: 1), success: { html in
            guard let _ = html.xpath("//*[@id='Wrapper']//div[@class='header']/small/text()[2]").first?.text else {
                // 需要登录
                if let error = html.xpath("//*[@id='Wrapper']/div[2]/div[2]").first?.content {
                    failure?(error)
                    return
                }
                // 需要验证
                // 被重定向到首页, 无法查看
                if html.xpath("//*[@id='Main']/div/div//span[@class='negative'][text()]").first?.content != nil ||
                    html.title == "V2EX" {
                    failure?("无法获取该主题 Token，请确保能正常浏览此主题")
                    return
                }
                failure?("数据解析失败")
                return
            }
            
            // 获取 token
            guard let csrfTokenPath = html.xpath("//*[@id='Wrapper']/div[@class='content']/div/div[@class='inner']//a[1]").first?["href"],
                let csrfToken = URLComponents(string: csrfTokenPath)?["t"] else {
                    failure?("无法获取 Token")
                    return
            }
            Network.htmlRequest(target: .unfavoriteTopic(topicID: topicID, token: csrfToken), success: { html in
                success?()
            }, failure: failure)
        }, failure: failure)
    }
    
    func thankTopic(topicID: String,
                    token: String,
                    success: Action?,
                    failure: Failure?) {
        Network.htmlRequestNotResponse(target: .thankTopic(topicID: topicID, token: token), success: {
            success?()
        }, failure: failure)
    }
    
    func thankReply(replyID: String,
                    token: String,
                    success: Action?,
                    failure: Failure?) {
        Network.htmlRequestNotResponse(target: .thankReply(replyID: replyID, token: token), success: {
            success?()
        }, failure: failure)
    }
    
    
    func reportTopic(topicID: String,
                     token: String,
                     success: Action?,
                     failure: Failure?) {
        Network.htmlRequestNotResponse(target: .reportTopic(topicID: topicID, token: token), success: {
            success?()
        }, failure: failure)
    }
}
