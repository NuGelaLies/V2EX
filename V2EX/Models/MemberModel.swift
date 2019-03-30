import Foundation

struct MemberModel {
    
    public var username: String
    public var url: String
    public var avatar: String
    public var joinTime: String?
    public var followHref: String?
    public var blockHref: String?
    public var isFollow: Bool = false
    public var isBlock: Bool = false

    public var followOrUnfollowHref: String? {
        guard let href = followHref else { return nil }

        if isFollow, href.hasPrefix("/follow") {
            return href.replacingOccurrences(of: "/follow", with: "/unfollow")
        } else if !isFollow, href.hasPrefix("/unfollow") {
            return href.replacingOccurrences(of: "/unfollow", with: "/follow")
        } else {
            return href
        }
    }

    public var blockOrUnblockHref: String? {
        guard let href = blockHref else { return nil }

        if isBlock, href.hasPrefix("/block") {
            return href.replacingOccurrences(of: "/block", with: "/unblock")
        } else if !isBlock, href.hasPrefix("/unblock") {
            return href.replacingOccurrences(of: "/unblock", with: "/block")
        } else {
            return href
        }
    }

    public var avatarSrc: String {
        return avatar.hasPrefix("http") ? avatar : Constants.Config.URIScheme + avatar
    }

    public var atUsername: String {
        return "@\(username) "
    }
    
    public var atUsernameWithoutSpace: String {
        return "@\(username)"
    }
    
    init(username: String, url: String, avatar: String) {
        self.username = username
        self.url = url
        self.avatar = avatar
    }

    init(username: String, url: String, avatar: String, joinTime: String?, followHref: String?, blockHref: String?, isFollow: Bool = false, isBlock: Bool = false) {
        self.username = username
        self.url = url
        self.avatar = avatar
        self.joinTime = joinTime
        self.followHref = followHref
        self.blockHref = blockHref
        self.isFollow = isFollow
        self.isBlock = isBlock
    }
}

extension MemberModel: Hashable {
    static func ==(lhs: MemberModel, rhs: MemberModel) -> Bool {
        return lhs.username == rhs.username && lhs.url == rhs.url && lhs.avatar == rhs.avatar
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine("\(username),\(url),\(avatar)".hashValue)
    }
}
