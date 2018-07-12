import Foundation

struct AccountModel: Codable {

    private enum CodingKeys: String, CodingKey {
        case avatarNormal = "avatar_normal"
        case twitter = "twitter"
        case github = "github"
        case avatarMini = "avatar_mini"
        case website = "website"
        case bio = "bio"
        case psn = "psn"
        case username = "username"
        case status = "status"
        case location = "location"
        case id = "id"
        case created = "created"
        case btc = "btc"
        case tagline = "tagline"
        case avatarLarge = "avatar_large"
        case url = "url"
    }

    // MARK: Properties
    public var twitter: String?
    public var github: String?
    public var website: String?
    public var bio: String?
    public var psn: String?
    public var username: String
    public var status: String?
    public var location: String?
    public var id: Int?
    public var created: Int?
    public var btc: String?
    public var url: String
    public var tagline: String?
    public var avatarMini: String?
    public var avatarNormal: String
    public var avatarLarge: String?

    var avatarNormalSrc: String {
        return Constants.Config.URIScheme + avatarNormal
    }

    static var isLogin: Bool {
        if let username = AccountModel.current?.username,
            username.isNotEmpty {
            return true
        }
        return false
    }

    public static var current: AccountModel? {
        guard let avatarSrc = UserDefaults.get(forKey: Constants.Keys.avatarSrc) as? String,
            let name = UserDefaults.get(forKey: Constants.Keys.username) as? String else {
                return nil
        }
        return AccountModel(username: name, url: "/member/\(name)", avatar: avatarSrc)
    }
    
    init(username: String, url: String, avatar: String) {
        self.username = username
        self.url = url
        self.avatarNormal = avatar
    }

    public static func store(_ user: AccountModel?) {
        guard let `user` = user else { return }

        UserDefaults.save(at: user.avatarNormal, forKey: Constants.Keys.avatarSrc)
        UserDefaults.save(at: user.username, forKey: Constants.Keys.username)
    }
    
    public func save() {
//        JPUSHService.setAlias(self.username, completion: { (resCode, alia, seq) in
//            log.info(resCode, alia, seq)
//        }, seq: 2)
        AccountModel.store(self)
    }
    
    public static func delete() {
        UserDefaults.remove(forKey: Constants.Keys.avatarSrc)
        UserDefaults.remove(forKey: Constants.Keys.username)
    }

    public static func saveOnce(_ once: String) {
        UserDefaults.save(at: once, forKey: Constants.Keys.once)
    }

    public static func getOnce() -> String? {
        return UserDefaults.get(forKey: Constants.Keys.once) as? String
    }

    static func account(data: Data) -> AccountModel? {
        return try? JSONDecoder().decode(AccountModel.self, from: data)
    }
}
