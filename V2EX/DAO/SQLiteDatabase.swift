import Foundation
import SQLite3

public enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

// 数据库用于保存浏览历史，可以查看浏览历史 如果一个帖子已经查看在帖子列表页面此帖子标题灰色显示
public class SQLiteDatabase {
    private let TABLE_READ_HISTORY = "readHistory"

    private static var db: SQLiteDatabase?
    private let dbPointer: OpaquePointer?

    fileprivate init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }

    deinit {
        log.verbose("dinit sqlite3 db")
        sqlite3_close(dbPointer)
    }

    public static func initDatabase() {
//        DispatchQueue.global(qos: .background).async {
        
        log.verbose("====================")
        log.verbose("init database")
        
        do {
            // 不存在数据库
            if !FileManager.default.fileExists(atPath: Constants.Keys.dbFile) {
                try SQLiteDatabase.instance?.createTables()
            } else {
                if let version = SQLiteDatabase.instance?.userVersion(), version == 0 {
                    do {
                        try SQLiteDatabase.instance?.migrateDB()
                    } catch {
                        log.error(error)
                    }
                } else {
                    try SQLiteDatabase.instance?.clearOldHistory(max: 1000) //最多存1000条
                }
            }
        } catch {
            log.error(error)
        }
    }

    // 数据库实例
    public static var instance: SQLiteDatabase? {
        if SQLiteDatabase.db == nil {
            if !FileManager.default.fileExists(atPath: Constants.Keys.dbFile) {
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: Constants.Keys.dbFile.deletingLastPathComponent), withIntermediateDirectories: true, attributes: nil)
                    log.verbose("success create db dir:\(Constants.Keys.dbFile)")
                } catch {
                    log.error(error)
                }
            }

            try? SQLiteDatabase.db = SQLiteDatabase.open(path: Constants.Keys.dbFile)
        }

        return SQLiteDatabase.db
    }

    // 关闭数据库
    public static func close() {
        if SQLiteDatabase.db != nil {
            SQLiteDatabase.db = nil
        }
    }

    // 数据库出错信息
    public var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }

    // 打开数据库
    private static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer? = nil
        if sqlite3_open(path, &db) == SQLITE_OK {
            return SQLiteDatabase(dbPointer: db)
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            if let errPointer = sqlite3_errmsg(db) {
                let message = String(cString: errPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }

    // prepare
    private func prepare(statement sql: String) throws -> OpaquePointer? {
//        log.info(Thread.current)
        var statement: OpaquePointer? = nil
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }

        return statement
    }

    // 执行sql语句
    public func excute(sql: String) throws {
        let statement = try prepare(statement: sql)
        defer {
            sqlite3_finalize(statement)
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        log.verbose("success excute sql:\n\(sql)")
    }
    
    // 获取当前数据库版本
    func userVersion() -> Int? {
        guard let statement = try? prepare(statement: "PRAGMA user_version") else { return  nil }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            return Int(sqlite3_column_int(statement, 0))
        }
        return nil
    }
    
    // 创建表
    func createTables() throws {
        // commentCount 当楼层使用
        let tbHistorySql = """
        CREATE TABLE IF NOT EXISTS \(TABLE_READ_HISTORY) (
        tid INTEGER primary key,
        title TEXT NOT NULL,
        username TEXT NOT NULL,
        avatarURL TEXT NOT NULL,
        created DATETIME NOT NULL,
        anchor INTEGER NOT NULL,
        replyCount INTEGER)
        """
        try excute(sql: tbHistorySql)
        try excute(sql: "PRAGMA user_version = 1")
        log.verbose("success create table: \n\(TABLE_READ_HISTORY)")
    }

    // 表迁移
    func migrateDB() throws {
        
        let temp_table = "readHistory_temp"

        let tbHistorySql = """
        CREATE TABLE IF NOT EXISTS \(temp_table) (
        tid INTEGER primary key,
        title TEXT NOT NULL,
        username TEXT NOT NULL,
        avatarURL TEXT NOT NULL,
        created DATETIME NOT NULL,
        anchor INTEGER NOT NULL,
        replyCount INTEGER)
        """
        do {
            try excute(sql: tbHistorySql)
            
            let migrateSql = """
            INSERT INTO \(temp_table)(tid, title, username, avatarURL, created, anchor, replyCount) SELECT tid, title, username, avatarURL, created, commentCount, -1 FROM \(TABLE_READ_HISTORY)
            """
            
            do {
                try excute(sql: migrateSql)
                try excute(sql: "DROP TABLE \(TABLE_READ_HISTORY)")
                try excute(sql: "ALTER TABLE \(temp_table) RENAME TO \(TABLE_READ_HISTORY)")
                try excute(sql: "PRAGMA user_version = 1")
            } catch {
                log.verbose("数据库迁移失败")
            }
            log.info("表迁移成功")
        } catch {
            log.error("表：\(temp_table) 创建失败", error.localizedDescription)
        }
    }

    // 删除所有的表
    func dropTables() throws {
        let dropSql = "DROP TABLE IF EXISTS \(TABLE_READ_HISTORY)"
        try excute(sql: dropSql)
        log.verbose("success drop table:\(TABLE_READ_HISTORY)")
    }

    // MARK: - 浏览历史相关
    
    // 新增 or 更新 浏览历史
    func addHistory(tid: Int, title: String, username: String, avatarURL: String, replyCount: Int? = nil) {
        let sql = """
        REPLACE INTO \(TABLE_READ_HISTORY)(tid,title,username,avatarURL,created,anchor,replyCount) VALUES (?,?,?,?,CURRENT_TIMESTAMP,?,?)
        """
        guard let statement = try? prepare(statement: sql) else {
            log.error(errorMessage)
            return
        }
        defer {
            sqlite3_finalize(statement)
        }
        
        guard sqlite3_bind_int(statement, 1, Int32(tid)) == SQLITE_OK &&
            sqlite3_bind_text(statement, 2, NSString(string: title).utf8String, -1, nil) == SQLITE_OK &&
            sqlite3_bind_text(statement, 3, NSString(string: username).utf8String, -1, nil) == SQLITE_OK &&
            sqlite3_bind_text(statement, 4, NSString(string: avatarURL).utf8String, -1, nil) == SQLITE_OK &&
            sqlite3_bind_int(statement, 5, Int32(getAnchor(topicID: tid) ?? -1)) == SQLITE_OK &&
            sqlite3_bind_int(statement, 6, Int32(replyCount ?? 0)) == SQLITE_OK else {
            log.error(errorMessage)
            return
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            log.error(errorMessage)
            return
        }

        log.verbose("Successfully inserted history row.")
    }

    // 判断 topics 是否为已读并修改返回
    func setAnchor(topicID: Int, anchor: Int) {
        let sql = "UPDATE \(TABLE_READ_HISTORY) set anchor = \(anchor) where tid = \(topicID)"
        try? excute(sql: sql)
    }
    
    // 加载浏览历史
    func getAnchor(topicID: Int) -> Int? {
        
        let sql = "SELECT * FROM \(TABLE_READ_HISTORY) where tid = \(topicID)"
        guard let statement = try? prepare(statement: sql) else {
            return nil
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        while (sqlite3_step(statement) == SQLITE_ROW) {
            return Int(sqlite3_column_int(statement, 5))
        }
        return nil
    }
    
    // 获取主题
    func getTopic(topicID: Int) -> TopicModel? {
        let sql = "SELECT * FROM \(TABLE_READ_HISTORY) where tid = \(topicID)"
        guard let statement = try? prepare(statement: sql) else {
            return nil
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let tid = Int(sqlite3_column_int(statement, 0))
            let title = String(cString: sqlite3_column_text(statement, 1))
            let username = String(cString: sqlite3_column_text(statement, 2))
            let avatarURL = String(cString: sqlite3_column_text(statement, 3))
            //            let created = String(cString: sqlite3_column_text(statement, 4))
            //            let anchor = String(cString: sqlite3_column_text(statement, 5))
            let replyCount = Int(sqlite3_column_int(statement, 6))
            return TopicModel(member: MemberModel(username: username, url: username, avatar: avatarURL), node: nil, title: title, href: tid.description, replyCount: String(replyCount))
        }
        return nil
    }
    
    // 判断 topics 是否为已读并修改返回
    func setReadHistory(topics: [TopicModel]) -> [TopicModel]{
        var `topics` = topics
        let sql = "SELECT * from \(TABLE_READ_HISTORY) where tid = ?"
        guard let statement = try? prepare(statement: sql) else {
            return topics
        }
        defer {
            sqlite3_finalize(statement)
        }
        for (offset, topic) in topics.enumerated() {
            guard let topicID = topic.topicID?.int else {
                continue
            }
            let tid = Int32(topicID)
            sqlite3_reset(statement)
            guard sqlite3_bind_int(statement, 1, tid) == SQLITE_OK else {
                log.error("bind error \(errorMessage)")
                continue
            }
            guard sqlite3_step(statement) == SQLITE_ROW else {
                continue
            }
            
            log.info("replyCount = ", Int(sqlite3_column_int(statement, 6)))
            topics[offset].readStatus = .read
        }
        return topics
    }

    // 加载浏览历史
    func loadReadHistory(count: Int) -> [TopicModel] {
        var topics = [TopicModel]()
        let sql = "SELECT * FROM \(TABLE_READ_HISTORY) order by created desc limit \(count)"
        guard let statement = try? prepare(statement: sql) else {
            return topics
        }

        defer {
            sqlite3_finalize(statement)
        }
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let tid = Int(sqlite3_column_int(statement, 0))
            let title = String(cString: sqlite3_column_text(statement, 1))
            let username = String(cString: sqlite3_column_text(statement, 2))
            let avatarURL = String(cString: sqlite3_column_text(statement, 3))
//            let created = String(cString: sqlite3_column_text(statement, 4))
//            let anchor = String(cString: sqlite3_column_text(statement, 5))
            let replyCount = Int(sqlite3_column_int(statement, 6))
            topics.append(TopicModel(member: MemberModel(username: username, url: username, avatar: avatarURL), node: nil, title: title, href: tid.description, replyCount: String(replyCount)))
        }

        log.verbose(topics.count)
        return topics
    }

    // 删除浏览历史
    func deleteHistory(tid: Int) throws {
        let sql = "DELETE FROM \(TABLE_READ_HISTORY) WHERE tid = \(tid)"
        try excute(sql: sql)
    }

    // 浏览历史到了一定数量以后需要删除老的数据
    func clearOldHistory(max: Int) throws {
        let sql = "SELECT COUNT(*) FROM \(TABLE_READ_HISTORY)"
        let statement = try prepare(statement: sql)
        defer{
            sqlite3_finalize(statement)
        }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw SQLiteError.Step(message: errorMessage)
        }

        let count = Int(sqlite3_column_int(statement, 0))
        if count <= max {
            return
        }

        let deletes = count / 4
        let deleteSql = "DELETE FROM \(TABLE_READ_HISTORY) ORDER BY created asc limit \(deletes)"
        try excute(sql: deleteSql)
    }

    // 清空浏览历史
    func clearHistory() throws {
        let sql = "DELETE FROM \(TABLE_READ_HISTORY)"
        try excute(sql: sql)
    }
}
