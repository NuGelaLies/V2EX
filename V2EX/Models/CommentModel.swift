import Foundation
import Kanna
import YYText

struct CommentModel {
    var id: String
    var member: MemberModel
    var content: String
    var publicTime: String
    var isThank: Bool = false
    var floor: String
    var thankCount: Int?
    var textLayout: YYTextLayout?
}

extension CommentModel: Hashable {
    static func ==(lhs: CommentModel, rhs: CommentModel) -> Bool {
        return lhs.id == rhs.id && lhs.member == rhs.member
    }

    public var hashValue: Int {
        return "\(id)-\(member.username)".hashValue
    }
}

extension CommentModel {
    
    /// 查找上一个引用的回复
    ///
    /// - Parameters:
    ///   - comments: 所有回复列表
    ///   - currentComment: 当前所选回复
    /// - Returns: 引用的回复
    static func forewordComment(comments: [CommentModel], currentComment: CommentModel) -> CommentModel? {
        guard let atUsers = CommentModel.atUsernames(currentComment),
        let list = comments.split(separator: currentComment).first else { return nil }

        let coms = list.filter { comment -> Bool in
            guard var commentUsers = CommentModel.atUsernames(comment) else { return false }
            commentUsers.insert(comment.member.atUsernameWithoutSpace)
            let intersetions = commentUsers.intersection(atUsers)
            if commentUsers.count > 0 && intersetions.count <= 0 { return false }
            return atUsers.contains(comment.member.atUsernameWithoutSpace)
        }
        
        return coms.last
    }
    
    /// 查找所有回复当中包含指定@用户的对话回复列表
    ///
    /// - Parameters:
    ///   - comments: 所有回复列表
    ///   - currentComment: 当前所选回复
    /// - Returns: 包含当前所选回复中所有@用户的对话回复列表
    static func atUsernameComments(comments: [CommentModel], currentComment: CommentModel) -> [CommentModel] {
        guard var atUsers = CommentModel.atUsernames(currentComment) else { return [] }
//        let ats = atUsers
        atUsers.insert(currentComment.member.atUsernameWithoutSpace)
        
        let coms = comments.filter { comment -> Bool in
            guard var commentUsers = CommentModel.atUsernames(comment) else { return false }
            commentUsers.insert(comment.member.atUsernameWithoutSpace)
            // 当前回复没有@用户.
            // 判断 1: 找出当前所选回复所有@的用户的回复
            //     2: 加入当前所选的回复
            if atUsers.count == 1 {
                return commentUsers.contains(currentComment.member.atUsernameWithoutSpace) || atUsers.contains(comment.member.atUsernameWithoutSpace)
            }
            let intersetions = commentUsers.intersection(atUsers)
            if commentUsers.count > 0 && intersetions.count <= 0 { return false }
            return atUsers.contains(comment.member.atUsernameWithoutSpace)
        }

        // 如果当前 at 的用户为1个，并且 coms 对话列表只有一个
        // 代表没有找有相互对话的回复
        // 此时查询被@用户的所有回复，不需要相互@
        //
        // 例如:
        // #3 imydou: @Level5 把公交卡放入投币箱
        // #10 bk201: @imydou 你惹这种人一般会很麻烦，除非你很闲
        //
        // 此时点击10楼查看对话，两人并没有互相@，所以对话列表只有当前用户自己的回复
        // 这种情况就查询被@用户（@imydou）的所有回复
        // 目前只处理@单个用户。
        // ps: coms 个数如果只有一个， 代表只有当前所有回复
//        if ats.count == 1 && coms.count == 1 {
//            // 从当前所选楼层进行分割，之后的不查找
//            let forepart = comments.split(whereSeparator: { $0.floor == currentComment.floor } ).first
//            let result = forepart?.filter { ats.first == $0.member.atUsernameWithoutSpace }
//            return (result ?? []) + coms
//        }
        return coms
    }
    
    /// 解析回复当中所有 @ 的用户
    ///
    /// - Parameter comment: 回复模型
    /// - Returns: @用户的Set
    static func atUsernames(_ comment: CommentModel?) -> Set<String>?  {
        guard let `comment` = comment else { return nil }
        let text = comment.content
        guard let result = TextParser.mentioned?.matches(in: text, options: .reportProgress, range: NSRange(location: 0, length: text.count)) else {
            return nil
        }
        
        var ats: [String] = []
        result.forEach { result in
            guard let range = result.range.range(for: text) else { return }
            let at = text[range]
            ats.append(String(at).trimmed)
        }
        return Set(ats)
    }
}
