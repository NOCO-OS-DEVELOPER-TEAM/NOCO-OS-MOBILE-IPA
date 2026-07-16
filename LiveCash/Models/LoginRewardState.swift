import Foundation

/// Daily login reward state — coins only for opening the app once per day.
struct LoginRewardState: Codable, Equatable {
    var coins: Int
    var loginStreakDays: Int
    var lastLoginClaimDate: Date?
    var longestStreakDays: Int

    static let empty = LoginRewardState(
        coins: 0,
        loginStreakDays: 0,
        lastLoginClaimDate: nil,
        longestStreakDays: 0
    )

    var hasClaimedToday: Bool {
        guard let last = lastLoginClaimDate else { return false }
        return Calendar.current.isDateInToday(last)
    }
}

struct DailyLoginClaimResult: Equatable {
    let coinsAwarded: Int
    let totalCoins: Int
    let streakDays: Int
    let isNewStreak: Bool
}
