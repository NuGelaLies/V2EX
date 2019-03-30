import Foundation
import UIKit

public struct NodeCategoryModel: Codable {
    var id: Int
    var name: String
    var nodes: [NodeModel]

    static func save(_ groups: [NodeCategoryModel]) {
        do {
            let enc = try JSONEncoder().encode(groups)
            let error = FileManager.save(enc, savePath: Constants.Keys.nodeGroupCache)
            if let `error` = error {
                HUD.showTest(error)
                log.error(error)
            }
        } catch {
            HUD.showTest(error)
            log.error(error)
        }
    }

    static func get() -> [NodeCategoryModel]? {
        guard FileManager.default.fileExists(atPath: Constants.Keys.nodeGroupCache) else { return nil }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: Constants.Keys.nodeGroupCache))
            return try JSONDecoder().decode([NodeCategoryModel].self, from: data)
        } catch {
            HUD.showTest(error)
            log.error(error)
            return nil
        }
    }
}

struct NodeModel: Codable {
    /// 节点标题
    var title: String
    /// 节点的路径名字，发布主题时使用 (eg: 沙盒 / sandbox)
    var name: String?
    /// 节点链接
    var href: String
    /// 是否当前选择
    var isCurrent: Bool? = false
    /// 节点图标
    var icon: String?
    var comments: String?
    /// 节点简介
    var intro: String?
    /// 节点下主题个数
    var topicNumber: Int?
    /// 收藏的链接
    var favoriteHref: String?
    /// 是否收藏
    var isFavorite: Bool? = false

    private enum CodingKeys: String, CodingKey {
        case name, title
        case href = "url"
        case intro = "header"
        case topicNumber = "topics"
        case isCurrent, icon, comments, favoriteHref, isFavorite
    }
    
    var path: String {
        return (try? href.asURL().path) ?? href
    }
    
    var iconFullURL: String? {
        guard let `icon` = icon else { return nil }
        // 静态资源，没有 host， 故加上
        return icon.hasPrefix("//v2ex") || icon.hasPrefix("//cdn.v2ex")  ? Constants.Config.URIScheme + icon : Constants.Config.baseURL + icon
    }

    public var favoriteOrUnfavoriteHref: String? {
        guard let href = favoriteHref,
            let `isFavorite` = isFavorite else { return nil }

        if isFavorite, href.hasPrefix("/favorite") {
            return href.replacingOccurrences(of: "/favorite", with: "/unfavorite")
        } else if !isFavorite, href.hasPrefix("/unfavorite") {
            return href.replacingOccurrences(of: "/unfavorite", with: "/favorite")
        } else {
            return href
        }
    }

    init(title: String, href: String, isCurrent: Bool = false) {
        self.title = title
        self.href = href
        self.isCurrent = isCurrent
        self.name = href.lastPathComponent
    }

    init(title: String, href: String, isCurrent: Bool = false, icon: String?, comments: String?) {
        self.title = title
        self.href = href
        self.isCurrent = isCurrent
        self.icon = icon
        self.comments = comments
        self.name = href.lastPathComponent
    }

    init(title: String, href: String, intro: String?, topicNumber: Int) {
        self.title = title
        self.href = href
        self.intro = intro
        self.topicNumber = topicNumber
        self.name = href.lastPathComponent
    }
    
    static func nodes(data: Data) -> [NodeModel]? {
        do {
            return try JSONDecoder().decode([NodeModel].self, from: data)
        } catch {
            HUD.showTest(error.localizedDescription)
            log.error(error)
            return nil
        }
    }
}

// MARK: - Draft
extension NodeModel {

    /// 保存草稿
    static func saveDraft(_ node: NodeModel) {
        do {
            let enc = try JSONEncoder().encode(node)
            let error = FileManager.save(enc, savePath: Constants.Keys.createTopicNodenameDraft)
            if let `error` = error {
                HUD.showTest(error)
                log.error(error)
            }
        } catch {
            HUD.showTest(error)
            log.error(error)
        }
    }

    /// 读取草稿
    static func getDraft() -> NodeModel? {
        guard FileManager.default.fileExists(atPath: Constants.Keys.createTopicNodenameDraft) else { return nil }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: Constants.Keys.createTopicNodenameDraft))
            return try JSONDecoder().decode(NodeModel.self, from: data)
        } catch {
            HUD.showTest(error)
            log.error(error)
            return nil
        }
    }

    /// 删除草稿
    static func deleteDraft() {
        guard FileManager.default.fileExists(atPath: Constants.Keys.createTopicNodenameDraft) else { return }
        
        let error = FileManager.delete(at: Constants.Keys.createTopicNodenameDraft)
        if let `error` = error {
            HUD.showTest(error)
            log.error(error)
        }
    }
}


extension NodeModel: Hashable {
    static func ==(lhs: NodeModel, rhs: NodeModel) -> Bool {
        return lhs.title == rhs.title && lhs.href == rhs.href
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title.hashValue ^ href.hashValue)
    }
}
