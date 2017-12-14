import Foundation
import Kanna
import YYText

/// 解析类型
///
/// - index: 首页主题解析
/// - topicCollect:
/// - nodeDetail: 节点详情 (节点主页)
enum HTMLParserType {
    case index, topicCollect, nodeDetail, member
}

protocol HTMLParseService {
    func parseTopic(html: HTMLDocument, type: HTMLParserType) -> [TopicModel]
    func parseNodeNavigation(html: HTMLDocument) -> [NodeCategoryModel]
    func replacingIframe(text: String) -> String
    func parseOnce(html: HTMLDocument) -> String?
    func parseComment(html: HTMLDocument) -> [CommentModel]
    func parseMemberReplys(html: HTMLDocument) -> [MessageModel]
    func parseMemberTopics(html: HTMLDocument) -> [TopicModel]
    func parseMemberProfile(html: HTMLDocument) -> MemberModel?
    func parsePage(html: HTMLDocument) -> (current: Int, max: Int)
    func parseLoginUser(html: HTMLDocument) -> AccountModel?
}

extension HTMLParseService {
    
    
    /// 解析主题列表
    ///
    /// - Parameter html: HTMLDoc
    /// - Returns: topic model
    func parseTopic(html: HTMLDocument, type: HTMLParserType) -> [TopicModel] {
        
        //        let itemPath = html.xpath("//*[@id='Wrapper']/div[@class='box']/div[@class='cell item']")
        
        if let unreadNoticeString = html.xpath("//*[@id='Wrapper']/div[@class='content']/div[@class='box']/div[1]//td[1]/input").first?["value"],
            let unreadNoticeCount = unreadNoticeString.deleteOccurrences(target: "条未读提醒").trimmed.int {
            // 发送未读消息通知
            NotificationCenter.default.post(name: Notification.Name.V2.UnreadNoticeName, object: unreadNoticeCount)
        }
        let rootPathOp: XPathObject?
        switch type {
        case .index, .member:
            rootPathOp = html.xpath("//*[@id='Wrapper']/div/div/div[@class='cell item']")
        default://.nodeDetail:
            rootPathOp = html.xpath("//*[@id='Wrapper']/div[@class='content']//div[contains(@class, 'cell')]")
        }

        guard let rootPath = rootPathOp else { return [] }

        let topics = rootPath.flatMap({ ele -> TopicModel? in
            guard let userPage = ele.xpath(".//td/a").first?["href"],
                let avatarSrc = ele.xpath(".//td/a/img").first?["src"],
                let topicPath = ele.xpath(".//td/span[@class='item_title']/a").first,
                let topicTitle = topicPath.content,
                let topicHref = topicPath["href"],
                let username = ele.xpath(".//td/span[@class='small fade']/strong[1]").first?.content else {
                    return nil
            }

            
            let replyCount = ele.xpath(".//td/a[@class='count_livid']").first?.content ?? "0"
            
            let homeXPath = ele.xpath(".//td/span[3]/text()").first
            let nodeDetailXPath = ele.xpath(".//td/span[2]/text()").first
            let textNode = homeXPath ?? nodeDetailXPath
            let timeString = textNode?.content ?? ""
            let replyUsername = textNode?.parent?.xpath("./strong").first?.content ?? ""
            
            var lastReplyAndTime: String = ""
            if homeXPath != nil { // 首页的布局
                lastReplyAndTime = timeString + replyUsername
            } else if nodeDetailXPath != nil {
                var str = timeString.trimmed
                str.removeFirst()
                lastReplyAndTime = str.trimmed
            }
            
            let member = MemberModel(username: username, url: userPage, avatar: avatarSrc)
            
            var node: NodeModel?
            
            if let nodePath = ele.xpath(".//td/span[@class='small fade']/a[@class='node']").first,
                let nodename = nodePath.content,
                let nodeHref = nodePath["href"] {
                node = NodeModel(title: nodename, href: nodeHref)
            }

            return TopicModel(member: member, node: node, title: topicTitle, href: topicHref, lastReplyTime: lastReplyAndTime, replyCount: replyCount)
        })
        
        return topics
    }
    
    /// 解析节点导航
    ///
    /// - Parameter html: HTMLDoc
    /// - Returns: node model
    func parseNodeNavigation(html: HTMLDocument) -> [NodeCategoryModel] {
        let nodesPath = html.xpath("//*[@id='Wrapper']//div[@class='box'][last()]/div/table/tr")
        let nodeCategorys = nodesPath.flatMap { (ele) -> NodeCategoryModel? in
            guard let sectionName = ele.xpath("./td[1]/span").first?.content else { return nil }
            let nodes = ele.xpath("./td[2]/a").flatMap({ (ele) -> NodeModel? in
                guard let title = ele.content, let href = ele["href"] else { return nil }
                return NodeModel(title: title, href: href)
            })
            return NodeCategoryModel(id: 0, name: sectionName, nodes: nodes)
        }
        return nodeCategorys
    }


    //／ 评论里面的视频替换成链接地址
    func replacingIframe(text: String) -> String {
        guard text.contains("</iframe>") else { return text }
        
        guard let results = TextParser.iframe?.matches(
            in: text,
            options: .reportProgress,
            range: NSRange(location: 0, length: text.count)) else {
                return text
        }

        var content = text
        results.forEach {result in
            if let range = result.range.range(for: text) {
                let iframe = text[range]
                let arr = iframe.components(separatedBy: " ")
                if let srcIndex = arr.index(where: {$0.contains("src")}) {
                    let srcText = arr[srcIndex]
                    let href = srcText.replacingOccurrences(of: "src", with: "href")
                    let urlString = srcText.replacingOccurrences(of: "src=", with: "").replacingOccurrences(of: "\"", with: "")
                    let a = "<a \(href)>\(urlString)</a>"
                    content = content.replacingOccurrences(of: iframe, with: a)
                }
            }
        }
        return content
    }


    /// 解析 once
    ///
    /// - Parameter html: HTMLDoc
    func parseOnce(html: HTMLDocument) -> String? {
        return html.xpath("//input[@name='once']").first?["value"]
    }


    /// 解析回复列表
    ///
    /// - Parameter html: HTMLDoc
    func parseComment(html: HTMLDocument) -> [CommentModel] {
        let commentPath = html.xpath("//*[@id='Wrapper']//div[@class='box'][2]/div[contains(@id, 'r_')]")
        let comments = commentPath.flatMap({ ele -> CommentModel? in
            guard let replyID = ele["id"]?.deleteOccurrences(target: "r_"),
                let userAvatar = ele.xpath("./table/tr/td/img").first?["src"],
                let userPath = ele.xpath("./table/tr/td[3]/strong/a").first,
                let userHref = userPath["href"],
                let username = userPath.content,
                let publicTime = ele.xpath("./table/tr/td[3]/span").first?.content,
                let content = ele.xpath("./table/tr/td[3]/div[@class='reply_content']").first?.content,
                let floor = ele.xpath("./table/tr/td/div/span[@class='no']").first?.content else {
                    return nil
            }


            let contentNode = ele.xpath("./table/tr/td[3]/div[@class='reply_content']/node()")
            let attributedString = NSMutableAttributedString()
            wrapperAttributedString(attributedString, node: contentNode)
            let textContainer = YYTextContainer(size: CGSize(width: Constants.Metric.screenWidth - 30, height: CGFloat.max))
            let textLayout = YYTextLayout(container: textContainer, text: attributedString)
            let thankString = ele.xpath("./table/tr/td[3]/span[2]").first?.content
            let thankCount = thankString?.components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted).joined().int
            let member = MemberModel(username: username, url: userHref, avatar: userAvatar)
            let isThank = ele.xpath(".//div[@id='thank_area_\(replyID)' and contains(@class, 'thanked')]").count.boolValue

            return CommentModel(id: replyID,
                                member: member,
                                content: content,
                                publicTime: publicTime,
                                isThank: isThank,
                                floor: floor,
                                thankCount: thankCount,
                                textLayout: textLayout)
        })
        return comments
    }

    func wrapperAttributedString(_ attributedString: NSMutableAttributedString, node: XPathObject) {

        for ele in node {
            let tagName = ele.tagName
            if tagName == "text", let content = ele.content, content.isNotEmpty {

                let textAttrString = NSMutableAttributedString(
                    string: content,
                    attributes: [
                        .foregroundColor: ThemeStyle.style.value.titleColor,
                        .font: UIFont.preferredFont(forTextStyle: .body)]
                )

                // 文本中有链接
                TextParser.extractLink(content).forEach({ link in

                    textAttrString.yy_setTextHighlight(content.NSString.range(of: link),
                                                       color: ThemeStyle.style.value.linkColor, // Theme.Color.linkColor,
                        backgroundColor: .clear,
                        userInfo: ["url": link],
                        tapAction: { _, attrString, range, _ in
                            guard let highlight = attrString.yy_attribute(YYTextHighlightAttributeName, at: UInt(range.location)),
                                let url = (highlight as AnyObject).userInfo["url"] as? String else { return }
                            clickCommentLinkHandle(urlString: url)
                            //                        NotificationCenter.default.post(name: Notification.Name.V2.HighlightTextClickName, object: url)
                    }, longPressAction: nil)
                })
                attributedString.append(textAttrString)
                attributedString.yy_lineSpacing = 5
            } else if tagName == "img", let imageSrc = ele["src"] {
                let imageAttachment = wrapperImageAttachment(URL(string: imageSrc))
                attributedString.append(imageAttachment)
            } else if tagName == "a", let content = ele.content, let urlString = ele["href"] {
                // 是图片链接
                if ["jpg", "png", "jpeg", "gif"].contains(urlString.pathExtension.lowercased()),
                    let url = URL(string: urlString) {
                    let imageAttachment = wrapperImageAttachment(url)
                    attributedString.append(imageAttachment)
                    continue
                }

                /// 子节点 递归
                let subnodes = ele.xpath("./node()")
                if subnodes.first?.tagName != "text" && subnodes.count.boolValue {
                    wrapperAttributedString(attributedString, node: subnodes)
                }

                /// 链接
                if content.count.boolValue {
                    //                    let linkAttrString = NSMutableAttributedString(string: content,
                    //                                                                   attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
                    //                    linkAttrString.yy_setTextHighlight(NSRange(location: 0, length: content.count),
                    //                                                       color: ThemeStyle.style.value.linkColor, // Theme.Color.linkColor,
                    //                                                       backgroundColor: .clear,
                    //                                                       userInfo: ["url": urlString],
                    //                                                       tapAction: { _, attrString, range, _ in
                    //                        guard let highlight = attrString.yy_attribute(YYTextHighlightAttributeName, at: UInt(range.location)),
                    //                            let url = (highlight as AnyObject).userInfo["url"] as? String else { return }
                    //                                                    clickCommentLinkHandle(urlString: url)
                    ////                        NotificationCenter.default.post(name: Notification.Name.V2.HighlightTextClickName, object: url)
                    //                    }, longPressAction: nil)
                    let linkAttrString = wrapperURLAttachment(content, urlString: urlString)
                    attributedString.append(linkAttrString)
                }
            } else if tagName == "div" {
                let subnodes = ele.xpath("./node()")
                if subnodes.count.boolValue {
                    wrapperAttributedString(attributedString, node: subnodes)
                }
            } else if tagName == "br" {
                let contentAttrString = NSAttributedString(string: "\n", attributes: [.foregroundColor: ThemeStyle.style.value.titleColor])
                attributedString.append(contentAttrString)
            } else if let content = ele.content, content.isNotEmpty {
                if content.contains("显示 Gist 代码") { continue }
                let contentAttrString = NSAttributedString(string: content, attributes: [.foregroundColor: ThemeStyle.style.value.titleColor])
                attributedString.append(contentAttrString)
            }
        }
    }

    func wrapperImageAttachment(_ url: URL?) -> NSMutableAttributedString {
        let imageAttachment = ImageAttachment(url: url)
        let imageAttrString = NSMutableAttributedString.yy_attachmentString(withContent: imageAttachment, contentMode: .scaleAspectFit, attachmentSize: CGSize(width: 80, height: 80), alignTo: UIFont.preferredFont(forTextStyle: .body), alignment: .bottom)
        return imageAttrString
    }

    func wrapperURLAttachment(_ content: String, urlString: String) -> NSMutableAttributedString {
        let linkAttrString = NSMutableAttributedString(string: content,
                                                       attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
        linkAttrString.yy_setTextHighlight(NSRange(location: 0, length: content.count),
                                           color: ThemeStyle.style.value.linkColor, // Theme.Color.linkColor,
            backgroundColor: .clear,
            userInfo: ["url": urlString],
            tapAction: { _, attrString, range, _ in
                guard let highlight = attrString.yy_attribute(YYTextHighlightAttributeName, at: UInt(range.location)),
                    let url = (highlight as AnyObject).userInfo["url"] as? String else { return }
                clickCommentLinkHandle(urlString: url)
                //                        NotificationCenter.default.post(name: Notification.Name.V2.HighlightTextClickName, object: url)
        }, longPressAction: nil)
        return linkAttrString
    }

    //    func parseComment(html: HTMLDocument) -> [CommentModel] {
    //        let commentPath = html.xpath("//*[@id='Wrapper']//div[@class='box'][2]/div[contains(@id, 'r_')]")
    //        let comments = commentPath.flatMap({ ele -> CommentModel? in
    //            guard let replyID = ele["id"]?.deleteOccurrences(target: "r_"),
    //                let userAvatar = ele.xpath("./table/tr/td/img").first?["src"],
    //                let userPath = ele.xpath("./table/tr/td[3]/strong/a").first,
    //                let userHref = userPath["href"],
    //                let username = userPath.content,
    //                let publicTime = ele.xpath("./table/tr/td[3]/span").first?.content,
    //                var content = ele.xpath("./table/tr/td[3]/div[@class='reply_content']").first?.toHTML,
    //                let floor = ele.xpath("./table/tr/td/div/span[@class='no']").first?.content else {
    //                    return nil
    //            }
    //            let thankString = ele.xpath("./table/tr/td[3]/span[2]").first?.content
    //            content = self.replacingIframe(text: content)
    //            let member = MemberModel(username: username, url: userHref, avatar: userAvatar)
    //            let isThank = ele.xpath(".//div[@id='thank_area_\(replyID)' and contains(@class, 'thanked')]").count.boolValue
    //            return CommentModel(id: replyID, member: member, content: content, publicTime: publicTime, isThank: isThank, floor: floor, thankCount: thankString)
    //        })
    //        return comments
    //    }

    func parseMemberReplys(html: HTMLDocument) -> [MessageModel] {
        let titlePath = html.xpath("//*[@id='Wrapper']//div[@class='dock_area']")
        let contentPath = html.xpath("//*[@id='Wrapper']//div[@class='reply_content']")

        let messages = titlePath.enumerated().flatMap({ index, ele -> MessageModel? in
            guard let replyContent = contentPath[index].text,
                let replyNode = ele.xpath(".//tr[1]/td[1]/span").first,
                let replyDes = ele.content?.trimmed,
                let topicNode = replyNode.xpath("a").first,
                let topicTitle = topicNode.content?.trimmed,
                let topicHref = topicNode["href"],
                let replyTime = ele.xpath(".//tr[1]/td/div/span").first?.content else {
                    return nil
            }

            let topic = TopicModel(member: nil, node: nil, title: topicTitle, href: topicHref)
            return MessageModel(
                id: nil,
                member: nil,
                topic: topic,
                time: replyTime,
                content: replyContent,
                replyTypeStr: replyDes,
                once: nil)
        })
        return messages
    }

    func parseMemberTopics(html: HTMLDocument) -> [TopicModel] {
        
        let rootPath = html.xpath("//*[@id='Wrapper']/div/div/div[@class='cell item']")
        let topics = rootPath.flatMap({ ele -> TopicModel? in
            guard let userNode = ele.xpath(".//td//span/strong/a").first,
                let userPage = userNode["href"],
                let username = userNode.content,
                let topicPath = ele.xpath(".//td/span[@class='item_title']/a").first,
                let topicTitle = topicPath.content,
                //                    let avatarSrc = ele.xpath(".//td/a/img").first?["src"],
                let topicHref = topicPath["href"] else {
                    return nil
            }

            let replyCount = ele.xpath(".//td[2]/a").first?.text ?? "0"

            let homeXPath = ele.xpath(".//td/span[3]/text()").first
            let nodeDetailXPath = ele.xpath(".//td/span[2]/text()").first
            let textNode = homeXPath ?? nodeDetailXPath
            let timeString = textNode?.content ?? ""
            let replyUsername = textNode?.parent?.xpath("./strong").first?.content ?? ""

            var lastReplyAndTime: String = ""
            if homeXPath != nil { // 首页的布局
                lastReplyAndTime = timeString + replyUsername
            } else if nodeDetailXPath != nil {
                lastReplyAndTime = replyUsername + timeString
            }

            let member = MemberModel(username: username, url: userPage, avatar: "")

            var node: NodeModel?

            if let nodePath = ele.xpath(".//td/span[@class='small fade']/a[@class='node']").first,
                let nodeTitle = nodePath.content,
                let nodeHref = nodePath["href"] {
                node = NodeModel(title: nodeTitle, href: nodeHref)
            }

            return TopicModel(member: member, node: node, title: topicTitle, href: topicHref, lastReplyTime: lastReplyAndTime, replyCount: replyCount)
        })

        return topics
    }

    func parseMemberProfile(html: HTMLDocument) -> MemberModel? {
        guard let headerPath = html.xpath("//*[@id='Wrapper']/div/div[@class='box'][1]//tr").first,
            let avatar = headerPath.xpath("td/img").first?["src"],
            let username = headerPath.xpath("td[last()]/h1").first?.content else {
                return nil
        }
        return MemberModel(username: username, url: API.memberHome(username: username).path, avatar: avatar)
    }

    func parsePage(html: HTMLDocument) -> (current: Int, max: Int) {
        let pageComponents = html.xpath("//*[@id='Wrapper']//div[@class='box']/div[@class='inner']//strong").first?.content?.components(separatedBy: "/")
        let currentPage = pageComponents?.first?.int ?? 1
        let maxPage = pageComponents?.last?.int ?? 1
        return (currentPage, maxPage)
    }

    func parseLoginUser(html: HTMLDocument) -> AccountModel? {
        if let avatarNode = html.xpath("//*[@id='Top']/div/div/table/tr/td[3]/a[1]/img[1]").first,
            let avatarPath = avatarNode["src"]?.replacingOccurrences(of: "s=24", with: "s=55"), // 修改图片尺寸
            let href = avatarNode.parent?["href"] {
            let username = href.lastPathComponent

            return AccountModel(username: username, url: href, avatar: avatarPath)
        }

        return nil
    }
}
