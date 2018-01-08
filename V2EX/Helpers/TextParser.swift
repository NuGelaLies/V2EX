import Foundation
import UIKit
import YYText

//    "<([^>]*)>"; // 过滤所有以<开头以>结尾的标签
//    "<\\s*img\\s+([^>]*)\\s*>"; // 找出IMG标签
//    "src=\"([^\"]+)\""; // 找出IMG标签的SRC属性
struct TextParser {

    // 匹配 @
    static var mentioned: NSRegularExpression? {
        // \\B@\\w\\S*\\b
        return try? NSRegularExpression(pattern: "@(\\S+)\\s", options: [.caseInsensitive])
    }

    /// 匹配 iframe 标签
    static var iframe: NSRegularExpression? {
        return try? NSRegularExpression(pattern: "<iframe(.*?)</iframe>", options: [.caseInsensitive, .dotMatchesLineSeparators])
    }

    /// 匹配 img 标签
    static var imgTag: NSRegularExpression? {
        return try? NSRegularExpression(pattern: "<img src=(.*?)>", options: [.caseInsensitive, .dotMatchesLineSeparators])
    }

    /// 匹配 www.a.com 或者 http://www.a.com 的类型
    /// ref: http://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url
    static var link: NSRegularExpression? {
        get {
            let regex: String = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|^[a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)+([-A-Z0-9a-z_\\$\\.\\+!\\*\\(\\)/,:;@&=\\?~#%]*)*"
            return try? NSRegularExpression(pattern: regex, options: [.caseInsensitive])
        }
    }
    
    /// blocklist
    static var blockList: NSRegularExpression? {
        get {
            let regex: String = "blocked = \\[(.*?)\\]"
            return try? NSRegularExpression(pattern: regex, options: [.caseInsensitive])
        }
    }

    /// 匹配链接和@
    static var linkAndAt: NSRegularExpression? {
        let regex: String = "(((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|^[a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)+([-A-Z0-9a-z_\\$\\.\\+!\\*\\(\\)/,:;@&=\\?~#%]*)*)\\s|@(\\S+)\\s"
        return try? NSRegularExpression(pattern: regex, options: [.caseInsensitive])
    }

    /// 匹配链接和@ 不带空格
    static var linkAndAtNoBlank: NSRegularExpression? {
        let regex: String = "(((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|^[a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)+([-A-Z0-9a-z_\\$\\.\\+!\\*\\(\\)/,:;@&=\\?~#%]*)*)|@(\\S+)"
        return try? NSRegularExpression(pattern: regex, options: [.caseInsensitive])
    }
}

extension TextParser {

    /// 提取文本中的 链接
    ///
    /// - Parameter str: 文本
    /// - Returns: 结果集
    static func extractLink(_ str: String) -> [String] {
        var urls: [String] = []
        guard let res = TextParser.link?.matches(in: str, options: [.withoutAnchoringBounds], range: NSRange(location: 0, length: str.count)) else { return []}
        for checkingRes in res {
            urls.append((str.NSString).substring(with: checkingRes.range))
        }
        return urls
    }
    
    /// 提取 blocklist
    static func extractBlockList(_ str: String) -> [Int] {
        guard let res = TextParser.blockList?.matches(in: str, options: [.withoutAnchoringBounds], range: NSRange(location: 0, length: str.count)).first else { return [] }
        var blockListStr = (str.NSString).substring(with: res.range).deleteOccurrences(target: "blocked = ")
        blockListStr.removeFirst()
        blockListStr.removeLast()
        return blockListStr.components(separatedBy: ",").map { $0.trimmed.int }.filterNil()
    }
}

private extension String {
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = range.lowerBound.samePosition(in: utf16view)
        let to = range.upperBound.samePosition(in: utf16view)
        return NSRange(location: utf16view.distance(from: utf16view.startIndex, to: from!), length: utf16view.distance(from: from!, to: to!))
    }

    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
}


