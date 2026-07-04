import Foundation

struct SavingsGoal: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetAmount = max(targetAmount, 0.01)
        self.currentAmount = max(currentAmount, 0)
        self.createdAt = createdAt
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

    func estimatedCompletionDate(monthlySavings: Double) -> Date? {
        guard monthlySavings > 0, remaining > 0 else { return nil }
        let months = ceil(remaining / monthlySavings)
        return Calendar.current.date(byAdding: .month, value: Int(months), to: Date())
    }

    func monthlyRequired(months: Int = 12) -> Double {
        guard months > 0 else { return remaining }
        return remaining / Double(months)
    }
}
