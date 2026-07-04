import Foundation

struct NotificationLearning: Codable, Equatable {
    /// Typical hour (0–23) when the user logs transactions.
    var typicalLogHour: Int = 19
    var logSampleCount: Int = 0
}
