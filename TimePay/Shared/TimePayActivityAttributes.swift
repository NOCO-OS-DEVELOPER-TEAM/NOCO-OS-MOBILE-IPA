import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct TimePaySessionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endDate: Date
        var remainingSeconds: Int
        var sessionTitle: String
        var sessionKind: String
    }

    var totalSeconds: Int
    var startedAt: Date
}
#endif
