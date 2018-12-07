import UIKit

extension Defaults.Keys {
    static let fromTime = Defaults.Key<Date>("fromTime", default: "23:00".HHMMDate)
    static let toTime = Defaults.Key<Date>("toTime", default: "08:00".HHMMDate)
}

