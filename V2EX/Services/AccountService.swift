import Foundation
import Kanna

protocol AccountService: HTMLParseService {

    func once(
        success: @escaping ((_ once: String) -> Void),
        failure: Failure?)

    func captcha(
        type: CaptchaType,
        success: ((LoginForm) -> Void)?,
        failure: Failure?)

    func signin(
        loginForm: LoginForm,
        success: Action?,
        failure: ((_ error: String, _ loginForm: LoginForm?, _ is2Fa: Bool) -> Void)?)

    func twoStepVerification(
        code: String,
        once: String,
        success: Action?,
        failure: Failure?)

    func forgot(
        forgotForm: LoginForm,
        success: ((_ info: String) -> ())?,
        failure: ((_ error: String, _ forgotForm: LoginForm?) -> Void)?)

    func notifications(
        page: Int,
        success: ((_ messages: [MessageModel], _ maxPage: Int) -> ())?,
        failure: Failure?)
    
    func atomFeed(
        success: ((_ feedURL: String) -> Void)?,
        failure: Failure?)

    func deleteNotification(
        notifacationID: String,
        once: String,
        success: Action?,
        failure: Failure?)

    func dailyReward(
        success: ((String) -> Void)?,
        failure: Failure?)

    func updateAvatar(
        localURL: String,
        success: Action?,
        failure: Failure?)

    func userIntro(
        username: String,
        success: @escaping ((AccountModel) -> Void),
        failure: Failure?)

    /// 关注 或 取消关注 用户， 根据 href
    ///
    /// - Parameters:
    ///   - href: href
    ///   - success: 成功
    ///   - failure: 失败
    func follow(
        href: String,
        success: Action?,
        failure: Failure?)

    /// 屏蔽 或 取消屏蔽 用户， 根据 href 决定
    ///
    /// - Parameters:
    ///   - href: href
    ///   - success: 成功
    ///   - failure: 失败
    func block(
        href: String,
        success: Action?,
        failure: Failure?)
    
    /// 取消屏蔽 用户
    ///
    /// - Parameters:
    ///   - userID: 用户id
    ///   - success: 成功
    ///   - failure: 失败
    func unblock(
        userID: Int,
        success: Action?,
        failure: Failure?)
    
    /// 查看所有block用户
    ///
    /// - Parameters:
    ///   - success: 成功
    ///   - failure: 失败
    /// - Returns: block member list
    func blockedMember(
        success: (([AccountModel]) -> Void)?,
        failure: Failure?)

    /// 收藏 或 取消收藏 节点， 根据 href 决定
    ///
    /// - Parameters:
    ///   - href: href
    ///   - success: 成功
    ///   - failure: 失败
    func favorite(
        href: String,
        success: Action?,
        failure: Failure?)

    /// 收藏列表
    ///
    /// - Parameters:
    ///   - page: page
    ///   - success: 成功
    ///   - failure: 失败
    func myFavorite(
        page: Int,
        success: @escaping ((_ topics: [TopicModel], _ maxPage: Int) -> Void),
        failure: Failure?)
    
    /// 查询新消息
    func queryNewMessage(
        success: ((_ unreadNoticeCount: Int) -> Void)?,
        failure: Failure?)
    
    func addUser(
        feedURL: String,
        name: String,
        success: ((String) -> Void)?,
        failure: Failure?)
    
    func userStatus(
        username: String,
        success: ((Bool) -> Void)?,
        failure: Failure?)
}

extension AccountService {

    func once(
        success: @escaping ((_ once: String) -> Void),
        failure: Failure?) {
        Network.htmlRequest(target: .once, success: { html in
            if let once = self.parseOnce(html: html) {
                success(once)
            }
            failure?("获取 once 失败")
        }, failure: failure)
    }

    func captcha(
        type: CaptchaType,
        success: ((LoginForm) -> Void)?,
        failure: Failure?) {

        Network.htmlRequest(target: .captcha(type: type), success: { html in
            self.parseCaptcha(type: type, html: html, success: success, failure: failure)
        }, failure: failure)
    }

    func signin(
        loginForm: LoginForm,
        success: Action?,
        failure: ((_ error: String, _ loginForm: LoginForm?, _ is2Fa: Bool) -> Void)?) {
        Network.htmlRequest(target: .signin(dict: loginForm.loginDict()), success: { html in
            //html.xpath("//*[@id='Top']/div/div/table/tr/td/a").map {$0["href"]}

            // 两步验证
            if let title = html.title, title.contains("两步验证登录") {
                // 更新登录框的用户名
                UserDefaults.save(at: loginForm.username, forKey: Constants.Keys.loginAccount)
                failure?("您的账号已经开启了两步验证，请输入验证码继续", nil, true)
                return
            }

            // 有通知 代表登录成功
            if let innerHTML = html.innerHTML, innerHTML.contains("notifications") {
                // 领取今日登录奖励
                if let dailyHref = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[@class='inner']/a").first?["href"],
                    dailyHref == "/mission/daily" {
                }
                
                UserDefaults.save(at: loginForm.username, forKey: Constants.Keys.loginAccount)
                if let account = self.parseLoginUser(html: html) {
                    account.save()
                }
                success?()
                return
            }
            // 没有登录成功， 获取失败原因
            if let problem = html.xpath("//*[@id='Wrapper']//div[@class='problem']/ul/li").first?.content {
                self.parseCaptcha(html: html, success: { loginForm in
                    failure?(problem, loginForm, false)
                }, failure: { error in
                    failure?(problem, nil, false)
                })
                return
            } else if let errorLimit = html.xpath("//*[@id='Wrapper']/div/div/div[2]/div").first?.text?.trimmed.replacingOccurrences(of: " ", with: "") { // 错误次数过多提示
                failure?(errorLimit, nil, false)
                return
            }
            failure?("登录失败", nil, false)
        }, failure: { error in
            failure?(error, nil, false)
        })
    }

    func twoStepVerification(
        code: String,
        once: String,
        success: Action?,
        failure: Failure?) {

        Network.htmlRequest(target: .twoStepVerification(code: code, once: once), success: { html in
            if let errorMessage = html.xpath("//*[@id='Wrapper']//div[@class='message']").first?.content {
                failure?(errorMessage)
                return
            }
            if let account = self.parseLoginUser(html: html) {
                account.save()
            }
            success?()
        }, failure: failure)
    }

    func forgot(
        forgotForm: LoginForm,
        success: ((_ info: String) -> ())?,
        failure: ((_ error: String, _ forgotForm: LoginForm?) -> Void)?) {
        Network.htmlRequest(target: .forgot(dict: forgotForm.forgotDict()), success: { html in

            // 没有提交成功， 获取失败原因
            if let problem = html.xpath("//*[@id='Wrapper']//div[@class='problem']/ul/li").first?.content {
                self.parseCaptcha(type: .forgot ,html: html, success: { loginForm in
                    failure?(problem, loginForm)
                }, failure: { error in
                    failure?(problem, nil)
                })
                return
            } else if let errorLimit = html.xpath("//*[@id='Wrapper']/div/div/div[2]/div").first?.text?.trimmed.replacingOccurrences(of: " ", with: "") { // 错误次数过多提升
                failure?(errorLimit, nil)
                return
            }

            // 成功
            if let successTip = html.xpath("//*[@id='Main']/div[2]/div[2]").first?.content?.trimmed  {
                UserDefaults.save(at: forgotForm.username, forKey: Constants.Keys.loginAccount)
                success?(successTip)
                return
            }

            failure?("登录失败", nil)
        }, failure: { error in
            failure?(error, nil)
        })
    }

    func parseCaptcha(
        type: CaptchaType = .signin,
        html: HTMLDocument,
        success: ((LoginForm) -> Void)?,
        failure: Failure?) {

        switch type {
        case .signin:
            guard let usernameKey = html.xpath("//*[@id='Wrapper']//div[@class='cell']/form/table/tr[1]/td[2]/input[@class='sl']").first?["name"],
                let passwordKey = html.xpath("//*[@id='Wrapper']//div[@class='cell']/form/table/tr[2]/td[2]/input[@class='sl']").first?["name"],
                let captchaKey = html.xpath("//*[@id='Wrapper']//div[@class='cell']/form/table/tr[4]/td[2]/input[@class='sl']").first?["name"],
                let once = html.xpath("//*[@name='once'][1]").first?["value"] else {
                    if let errorLimit = html.xpath("//*[@id='Wrapper']/div/div/div[2]/div").first?.text?.trimmed.replacingOccurrences(of: " ", with: "") { // 错误次数过多提升
                        failure?(errorLimit)
                    } else {
                        failure?("数据解析失败")
                    }
                    return
            }
            Network.request(target: .captchaImageData(once: once), success: { data in
                let loginForm = LoginForm(usernameKey: usernameKey, passwordKey: passwordKey, captchaKey: captchaKey, captchaImageData: data, once: once)
                success?(loginForm)
            }, failure: failure)

        case .forgot:
            guard let usernameKey = html.xpath("//*[@id='Wrapper']//div[@class='inner']/form/table/tr[1]/td[2]/input[@class='sl']").first?["name"],
                let emailKey = html.xpath("//*[@id='Wrapper']//div[@class='inner']/form/table/tr[2]/td[2]/input[@class='sl']").first?["name"],
                let captchaKey = html.xpath("//*[@id='Wrapper']//div[@class='inner']/form/table/tr[3]/td[2]/input[@class='sl']").first?["name"],
                let once = html.xpath("//*[@name='once'][1]").first?["value"] else {
                    failure?("数据解析失败")
                    return
            }
            Network.request(target: .captchaImageData(once: once), success: { data in
                let loginForm = LoginForm(usernameKey: usernameKey, emailKey: emailKey, captchaKey: captchaKey, captchaImageData: data, once: once)
                success?(loginForm)
            }, failure: failure)

        }


        //        guard let usernameKey = html.xpath("//*[@id='Wrapper']//div[@class='cell']/form/table/tr[1]/td[2]/input[@class='sl']").first?["name"],
        //            let passwordKey = html.xpath("//*[@id='Wrapper']//div[@class='cell']/form/table/tr[2]/td[2]/input[@class='sl']").first?["name"],
        //            let captchaKey = html.xpath("//*[@id='Wrapper']//div[@class='cell']/form/table/tr[4]/td[2]/input[@class='sl']").first?["name"],
        //            let once = html.xpath("//*[@name='once'][1]").first?["value"] else {
        //                if let errorLimit = html.xpath("//*[@id='Wrapper']/div/div/div[2]/div").first?.text?.trimmed.replacingOccurrences(of: " ", with: "") { // 错误次数过多提升
        //                    failure?(errorLimit)
        //                } else {
        //                    failure?("数据解析失败")
        //                }
        //                return
        //        }
        //        Network.request(target: .captchaImageData(once: once), success: { data in
        //        let loginForm = LoginForm(usernameKey: usernameKey, passwordKey: passwordKey, captchaKey: captchaKey, captchaImageData: data, once: once, username: "", password: "", captcha: "")
        //        success?(loginForm)
        //        }, failure: failure)
    }

    func notifications(
        page: Int,
        success: ((_ messages: [MessageModel], _ maxPage: Int) -> ())?,
        failure: Failure?) {

        Network.htmlRequest(target: .notifications(page: page), success: { html in
            let cellPath = html.xpath("//*[@id='Wrapper']/div/div/div[@class='cell']")

            let messages = cellPath.compactMap({ ele -> MessageModel? in
                guard let id = ele["id"]?.deleteOccurrences(target: "n_"),
                    let userNode = ele.xpath("table/tr/td[1]/a/img").first,
                    let userPageHref = userNode.parent?["href"],
                    let avatarSrc = userNode["src"],
                    let topicNode = ele.xpath("table/tr/td[2]/span/a[2]").first,
                    let topicHref = topicNode["href"],
                    let topicTitle = topicNode.content,
                    let time = ele.xpath("table/tr/td[2]/span[2]").first?.content?.trimmed,
                    let replyTypeStr = ele.xpath("table/tr/td[2]/span[1]").first?.text else {
                        return nil
                }
                let onclick = ele.xpath("table/tr/td[2]/a").first?["onclick"]
                let once = onclick?.components(separatedBy: ",").last?.deleteOccurrences(target: ")").trimmed

                let username = userPageHref.lastPathComponent
                let content = ele.xpath("table/tr/td[2]/div[@class='payload']").first?.text ?? ""

                let member = MemberModel(username: username, url: userPageHref, avatar: avatarSrc)
                let topic = TopicModel(member: nil, node: nil, title: topicTitle, href: topicHref)
                return MessageModel(id: id,member: member, topic: topic, time: time, content: content, replyTypeStr: replyTypeStr, once: once)
            })
            let page = self.parsePage(html: html)
            success?(messages, page.max)
        }, failure: failure)
    }
    
    func atomFeed(
        success: ((_ feedURL: String) -> Void)?,
        failure: Failure?) {
        
        Network.htmlRequest(target: .atomFeed, success: { html in
            guard let feedURL = html.at_xpath("//*[@id='Wrapper']/div/div[@id='Main']/div[last()]//input")?["value"] else {
                failure?("操作失败")
                return
            }
            success?(feedURL)
        }, failure: failure)
    }

    func deleteNotification(
        notifacationID: String,
        once: String,
        success: Action?,
        failure: Failure?) {
        Network.htmlRequestNotResponse(target: .deleteNotification(notifacationID: notifacationID, once: once), success: {
            success?()
        }, failure: failure)
    }

    func dailyReward(
        success: ((String) -> Void)?,
        failure: Failure?) {

        // 第一次请求获取 token
        Network.htmlRequest(target: .loginReward(once: ""), success: { html in
            if (html.content ?? "").contains("奖励已领取") { return }

            if let comps = html.xpath("//*[@id='Wrapper']/div/div/div/input").first?["onclick"]?.components(separatedBy: "\'"),
                comps.count >= 2 {
                let href = comps[1]

                Network.htmlRequest(target: .currency(href: href), success: { html in
                    self.dailyRewardResultHandle(html: html, success: success, failure: failure)
                }, failure: failure)
                return
            }

            self.dailyRewardResultHandle(html: html, success: success, failure: failure)
        }, failure: failure)
    }

    private func dailyRewardResultHandle(
        html: HTMLDocument,
        success: ((String) -> Void)?,
        failure: Failure?) {

        let messagePath = html.xpath("//body/div[@id='Wrapper']/div[@class='content']/div[@class='box']/div[@class='message']").first

        guard let content = messagePath?.content, content.contains("已成功领取") else {
            failure?("领取每日奖励失败")
            return
        }

        if let days =  html.xpath("//*[@id='Wrapper']/div/div/div[last()]").first?.content {
            success?("每日登录奖励领取成功\n\(days)")
            return
        }

        success?("每日登录奖励领取成功")
    }


    func updateAvatar(
        localURL: String,
        success: Action?,
        failure: Failure?) {

        if let once = AccountModel.getOnce() {
            Network.htmlRequest(target: .updateAvatar(localURL: localURL, once: once), success: { html in
                // Optimize: 成功失败判断
                success?()
            }, failure: failure)
            return
        }

        // 没有才去获取
        once(success: { once in
            Network.htmlRequest(target: .updateAvatar(localURL: localURL, once: once), success: { html in
                // Optimize: 成功失败判断
                success?()
            }, failure: failure)
        }, failure: failure)
    }

    func userIntro(
        username: String,
        success: @escaping ((AccountModel) -> Void),
        failure: Failure?) {

        Network.request(target: .memberIntro(primartKeyType: .username(username)), success: { data in
            guard let account = AccountModel.account(data: data) else {
                failure?("未知错误")
                return
            }
            account.save()
            success(account)
        }, failure: failure)
    }

    func follow(
        href: String,
        success: Action?,
        failure: Failure?) {

        Network.htmlRequest(target: .currency(href: href), success: { html in
            success?()
        }, failure: failure)
    }

    func block(
        href: String,
        success: Action?,
        failure: Failure?) {

        Network.htmlRequest(target: .currency(href: href), success: { html in
            success?()
        }, failure: failure)
    }
    
    func unblock(
        userID: Int,
        success: Action?,
        failure: Failure?) {
        guard let username = AccountModel.current?.username else {
            failure?("当前登录状态异常，请尝试重新登录")
            return
        }
        userIntro(username: username, success: { account in
            guard let created = account.created else {
                failure?("操作失败，无法获取 created，请尝试重新操作")
                return
            }
            Network.htmlRequest(target: API.unblock(userID: userID, t: created), success: { html in
                success?()
            }, failure: failure)
        }, failure: failure)
    }
    
    func blockedMember(
        success: (([AccountModel]) -> Void)?,
        failure: Failure?) {
        Network.htmlRequest(target: .blockList, success: { html in
            guard let content = html.content,
                content.contains("blocked") else {
                    failure?("无法获取 blocked 列表")
                    return
            }
            let blockedIDs = TextParser.extractBlockList(content)
            guard blockedIDs.count.boolValue else {
                success?([])
                return
            }
            
            var accounts: [AccountModel] = []
            
            for id in blockedIDs {
                Network.request(target: .memberIntro(primartKeyType: .id(id)), success: { data in
                    guard let account = AccountModel.account(data: data) else {
                        failure?("未知错误")
                        return
                    }
                    accounts.append(account)
                    success?(accounts)
                }, failure: { error in
                    log.info(error)
                })
            }
        }, failure: failure)
    }

    func favorite(
        href: String,
        success: Action?,
        failure: Failure?) {

        Network.htmlRequest(target: .currency(href: href), success: { html in
            success?()
        }, failure: failure)
    }

    func myFavorite(
        page: Int,
        success: @escaping ((_ topics: [TopicModel], _ maxPage: Int) -> Void),
        failure: Failure?) {
        Network.htmlRequest(target: .myFavorites(page: page), success: { html in
            let topics = self.parseTopic(html: html, type: .topicCollect)
            let maxPath = html.xpath("//*[@id='Wrapper']/div/div[@class='box']/div[@class='cell'][last()]//tr/td/a[last()]").first
            let maxPage = maxPath?.content?.int ?? 1
            success(topics, maxPage)
        }, failure: failure)
    }
    
    func queryNewMessage(
        success: ((_ unreadNoticeCount: Int) -> Void)?,
        failure: Failure?) {
        
        Network.htmlRequest(target: .topics(href: nil), success: { html in
            if let unreadNoticeString = html.xpath("//*[@id='Wrapper']/div[@class='content']/div[@class='box']/div[1]//td[1]/input").first?["value"],
                let unreadNoticeCount = unreadNoticeString.deleteOccurrences(target: "条未读提醒").trimmed.int {
                success?(unreadNoticeCount)
                return
            }
            success?(0)
        }, failure: failure)
    }
    
    func addUser(
        feedURL: String,
        name: String,
        success: ((String) -> Void)?,
        failure: Failure?) {
        Network.request(target: .addUser(feedURL: feedURL, name: name), success: { data in
            guard let resultDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                failure?("操作失败")
                return
            }

            guard (resultDict["status"] as? Int) == 0 else {
                    failure?("操作失败")
                    return
            }
            success?(resultDict["message"] as? String ?? "操作成功")
        }, failure: failure)
    }
    
    func userStatus(
        username: String,
        success: ((Bool) -> Void)?,
        failure: Failure?) {
        
        Network.request(target: .userStatus(username: username), success: { data in
            guard let resultDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                failure?("操作失败")
                return
            }
            
            guard let dict = resultDict["data"] as? [String: Any],
                let result = dict["status"] as? Bool else {
                    failure?("操作失败")
                    return
            }
            success?(result)
        }, failure: failure)
    }
}

