import UIKit

enum V2erError: Error {
    static let domain = "com.v2er.error"

    var domain: String {
        return self.domain
    }

    var localizedDescription: String {
        switch self {
        default:
            return ""
        }
    }

    var message: String {
        switch self {
        default:
            return ""
        }
    }
}
