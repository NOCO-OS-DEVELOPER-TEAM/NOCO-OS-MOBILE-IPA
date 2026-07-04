import Foundation

struct SpendingLimits: Codable, Equatable {
    var dailyLimit: Double?
    var weeklyLimit: Double?
    var monthlyLimit: Double?
    var enabled: Bool

    static let `default` = SpendingLimits(dailyLimit: nil, weeklyLimit: nil, monthlyLimit: nil, enabled: false)

    var hasAnyLimit: Bool {
        dailyLimit != nil || weeklyLimit != nil || monthlyLimit != nil
    }
}

struct PendingSpendLimit: Equatable {
    var draft: ParsedTransactionDraft
    var rawInput: String?
    var message: String
}
