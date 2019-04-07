import Foundation

public struct Topic: Codable {
    public let node: Node
    public let member: Member
    public let lastReplyBy: String
    public let title: String
    public let url: String
    public let created: Int
    public let content: String
    public let contentRendered: String
    public let replies: Int
    public let id: Int
    
    enum CodingKeys: String, CodingKey {
        case node = "node"
        case member = "member"
        case lastReplyBy = "last_reply_by"
        case title = "title"
        case url = "url"
        case created = "created"
        case content = "content"
        case contentRendered = "content_rendered"
        case replies = "replies"
        case id = "id"
    }
    
    public init(node: Node, member: Member, lastReplyBy: String, title: String, url: String, created: Int, content: String, contentRendered: String, replies: Int, id: Int) {
        self.node = node
        self.member = member
        self.lastReplyBy = lastReplyBy
        self.title = title
        self.url = url
        self.created = created
        self.content = content
        self.contentRendered = contentRendered
        self.replies = replies
        self.id = id
    }
}

public struct Member: Codable {
    public let username: String
    public let avatarNormal: String
    public let bio: String?
    public let url: String
    public let created: Int
    public let avatarLarge: String
    public let avatarMini: String
    public let id: Int
    
    enum CodingKeys: String, CodingKey {
        case username = "username"
        case avatarNormal = "avatar_normal"
        case bio = "bio"
        case url = "url"
        case created = "created"
        case avatarLarge = "avatar_large"
        case avatarMini = "avatar_mini"
        case id = "id"
    }
    
    public init(username: String, avatarNormal: String, bio: String?, url: String, created: Int, avatarLarge: String, avatarMini: String, id: Int) {
        self.username = username
        self.avatarNormal = avatarNormal
        self.bio = bio
        self.url = url
        self.created = created
        self.avatarLarge = avatarLarge
        self.avatarMini = avatarMini
        self.id = id
    }
}

public struct Node: Codable {
    public let avatarLarge: String
    public let name: String
    public let avatarNormal: String
    public let title: String
    public let url: String
    public let topics: Int
    public let titleAlternative: String
    public let avatarMini: String
    public let stars: Int
    public let root: Bool
    public let id: Int
    public let parentNodeName: String
    
    enum CodingKeys: String, CodingKey {
        case avatarLarge = "avatar_large"
        case name = "name"
        case avatarNormal = "avatar_normal"
        case title = "title"
        case url = "url"
        case topics = "topics"
        case titleAlternative = "title_alternative"
        case avatarMini = "avatar_mini"
        case stars = "stars"
        case root = "root"
        case id = "id"
        case parentNodeName = "parent_node_name"
    }
    
    public init(avatarLarge: String, name: String, avatarNormal: String, title: String, url: String, topics: Int, titleAlternative: String, avatarMini: String, stars: Int, root: Bool, id: Int, parentNodeName: String) {
        self.avatarLarge = avatarLarge
        self.name = name
        self.avatarNormal = avatarNormal
        self.title = title
        self.url = url
        self.topics = topics
        self.titleAlternative = titleAlternative
        self.avatarMini = avatarMini
        self.stars = stars
        self.root = root
        self.id = id
        self.parentNodeName = parentNodeName
    }
}
