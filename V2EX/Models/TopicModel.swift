import Foundation
import UIKit

struct TopicModel {
    
    
    /// 阅读状态
    ///
    /// - unread: 未读
    /// - read: 已读
    /// - newReply: 已读，有新的回复
    enum ReadStatus {
        case unread, read, newReply
    }
    
    var member: MemberModel?
    var node: NodeModel?

    var title: String
    var content: String = ""
    var href: String
    var lastReplyTime: String?
    var replyCount: String

    var publicTime: String = ""

    var once: String?
    var token: String?
    var isFavorite: Bool = false
    var isThank: Bool = false
    var isIgnore = false
    var readStatus: ReadStatus = .unread
    
    var reportToken: String?
    
    /// 主题 ID
    var topicID: String? {
        let isTopic = href.hasPrefix("/t/") || href.hasPrefix("http")
        guard isTopic,
            let topicID = try? href.asURL().path.lastPathComponent else {
                // href 可能是 topic id
                return href.int == nil ? nil : href
        }
        return topicID
    }
    
    var anchor: Int? {
        let url = try? href.asURL()
        let anchor = url?.fragment?.deleteOccurrences(target: "reply").int
        return anchor
    }

    init(member: MemberModel?, node: NodeModel?, title: String, href: String, lastReplyTime: String? = "", replyCount: String = "0") {
        self.member = member
        self.node = node
        self.title = title
        self.href = href
        self.lastReplyTime = lastReplyTime
        self.replyCount = replyCount
    }
}

extension TopicModel: Hashable, Equatable {
    static func ==(lhs: TopicModel, rhs: TopicModel) -> Bool {
        return lhs.title == rhs.title && lhs.href == rhs.href && lhs.publicTime == rhs.publicTime
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine("\(title)-\(href)-\(publicTime)".hashValue)
    }
}
