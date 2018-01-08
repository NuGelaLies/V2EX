import Foundation
import SQLite3

// 数据库用于保存浏览历史，可以查看浏览历史 如果一个帖子已经查看在帖子列表页面此帖子标题灰色显示
public class SQLiteDatabase {
    private let TABLE_READ_HISTORY = "readHistory"

    fileprivate static var db: SQLiteDatabase?
    fileprivate let dbPointer: OpaquePointer?

    fileprivate init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }

    deinit {
        log.verbose("dinit sqlite3 db")
        sqlite3_close(dbPointer)
    }

    public static func initDatabase() {
        // history check
        DispatchQueue.global(qos: .background).async {
            log.verbose("====================")
            log.verbose("init database")
            do {
                try SQLiteDatabase.instance?.createTables()
                try SQLiteDatabase.instance?.clearOldHistory(max: 2000) //最多存2000条
            } catch {
                log.error(error)
            }
        }
    }

    // 数据库实例
    public static var instance: SQLiteDatabase? {
        if SQLiteDatabase.db == nil {
            guard let documentsDirectoryURL = try? FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
                return nil
            }
            let dirURL = documentsDirectoryURL.appendingPathComponent("database")
            let fileURL = dirURL.appendingPathComponent("v2er.db")

            if !FileManager.default.fileExists(atPath: dirURL.path) {
                try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
                log.verbose("success create db dir:\(dirURL.path)")
            }

            try? SQLiteDatabase.db = SQLiteDatabase.open(path: fileURL.path)
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

    // 创建表
    func createTables() throws {
        let tbHistorySql = """
        CREATE TABLE IF NOT EXISTS \(TABLE_READ_HISTORY) (
        tid INTEGER primary key,
        title TEXT NOT NULL,
        username TEXT NOT NULL,
        avatarURL TEXT NOT NULL,
        created DATETIME NOT NULL,
        commentCount INTEGER NOT NULL)
        """
        try excute(sql: tbHistorySql)
        log.verbose("success create table: \n\(TABLE_READ_HISTORY)")
    }

    // 删除所有的表
    func dropTables() throws {
        let dropSql = "DROP TABLE IF EXISTS \(TABLE_READ_HISTORY)"
        try excute(sql: dropSql)
        log.verbose("success drop table:\(TABLE_READ_HISTORY)")
    }

    // MARK: - 浏览历史相关
    
    // 新增 or 更新 浏览历史
    func addHistory(tid: Int, title: String, username: String, avatarURL: String) {
        let sql = """
        REPLACE INTO \(TABLE_READ_HISTORY)(tid,title,username,avatarURL,created,commentCount) VALUES (?,?,?,?,CURRENT_TIMESTAMP,-1)
        """
        guard let statemet = try? prepare(statement: sql) else {
            log.error(errorMessage)
            return
        }
        defer {
            sqlite3_finalize(statemet)
        }
        guard sqlite3_bind_int(statemet, 1, Int32(tid)) == SQLITE_OK &&
            sqlite3_bind_text(statemet, 2, NSString(string: title).utf8String, -1, nil) == SQLITE_OK &&
            sqlite3_bind_text(statemet, 3, NSString(string: username).utf8String, -1, nil) == SQLITE_OK &&
            sqlite3_bind_text(statemet, 4, NSString(string: avatarURL).utf8String, -1, nil) == SQLITE_OK else {
            log.error(errorMessage)
            return
        }

        guard sqlite3_step(statemet) == SQLITE_DONE else {
            log.error(errorMessage)
            return
        }

        log.verbose("Successfully inserted history row.")
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
            topics[offset].isRead = true
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
//            let commentCount = String(cString: sqlite3_column_text(statement, 5))
            topics.append(TopicModel(member: MemberModel(username: username, url: username, avatar: avatarURL), node: nil, title: title, href: tid.description))
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
