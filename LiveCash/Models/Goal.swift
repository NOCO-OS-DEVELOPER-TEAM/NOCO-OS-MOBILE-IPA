import Foundation

enum GoalPaceStatus: String, Codable, Equatable {
    case onTrack = "Im Plan"
    case slow = "Zu langsam"
    case fast = "Über Plan"
    case noDeadline = "Offen"
}

struct SavingsGoal: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var createdAt: Date
    var targetDate: Date?
    var notifySlowProgress: Bool
    var notifyFastProgress: Bool
    var notifyAt50Percent: Bool
    var notifiedMilestones: [Int]

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        createdAt: Date = Date(),
        targetDate: Date? = nil,
        notifySlowProgress: Bool = true,
        notifyFastProgress: Bool = false,
        notifyAt50Percent: Bool = true,
        notifiedMilestones: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.targetAmount = max(targetAmount, 0.01)
        self.currentAmount = max(currentAmount, 0)
        self.createdAt = createdAt
        self.targetDate = targetDate
        self.notifySlowProgress = notifySlowProgress
        self.notifyFastProgress = notifyFastProgress
        self.notifyAt50Percent = notifyAt50Percent
        self.notifiedMilestones = notifiedMilestones
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        targetAmount = try c.decode(Double.self, forKey: .targetAmount)
        currentAmount = try c.decodeIfPresent(Double.self, forKey: .currentAmount) ?? 0
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        targetDate = try c.decodeIfPresent(Date.self, forKey: .targetDate)
        notifySlowProgress = try c.decodeIfPresent(Bool.self, forKey: .notifySlowProgress) ?? true
        notifyFastProgress = try c.decodeIfPresent(Bool.self, forKey: .notifyFastProgress) ?? false
        notifyAt50Percent = try c.decodeIfPresent(Bool.self, forKey: .notifyAt50Percent) ?? true
        notifiedMilestones = try c.decodeIfPresent([Int].self, forKey: .notifiedMilestones) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case id, name, targetAmount, currentAmount, createdAt, targetDate
        case notifySlowProgress, notifyFastProgress, notifyAt50Percent, notifiedMilestones
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(targetAmount, forKey: .targetAmount)
        try c.encode(currentAmount, forKey: .currentAmount)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(targetDate, forKey: .targetDate)
        try c.encode(notifySlowProgress, forKey: .notifySlowProgress)
        try c.encode(notifyFastProgress, forKey: .notifyFastProgress)
        try c.encode(notifyAt50Percent, forKey: .notifyAt50Percent)
        try c.encode(notifiedMilestones, forKey: .notifiedMilestones)
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1)
    }

    var progressPercent: Int {
        Int((progress * 100).rounded())
    }

    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }

    var daysRemaining: Int? {
        guard let targetDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        return max(days, 0)
    }

    var requiredDailyPace: Double? {
        guard let days = daysRemaining, days > 0, remaining > 0 else { return nil }
        return remaining / Double(days)
    }

    var actualDailyPace: Double? {
        let days = max(Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 1, 1)
        guard currentAmount > 0 else { return nil }
        return currentAmount / Double(days)
    }

    func paceStatus(referenceMonthlySavings: Double) -> GoalPaceStatus {
        guard targetDate != nil else { return .noDeadline }
        guard let required = requiredDailyPace else {
            return progress >= 1 ? .fast : .onTrack
        }
        let actual = actualDailyPace ?? (referenceMonthlySavings / 30)
        if actual >= required * 1.15 { return .fast }
        if actual < required * 0.85 { return .slow }
        return .onTrack
    }

    func estimatedMonthsToComplete(monthlySavings: Double) -> Int? {
        guard monthlySavings > 0, remaining > 0 else { return nil }
        return max(1, Int(ceil(remaining / monthlySavings)))
    }

    func estimatedCompletionDate(monthlySavings: Double) -> Date? {
        guard let months = estimatedMonthsToComplete(monthlySavings: monthlySavings) else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: Date())
    }

    func monthlyRequired(months: Int = 12) -> Double {
        guard months > 0 else { return remaining }
        return remaining / Double(months)
    }
}
