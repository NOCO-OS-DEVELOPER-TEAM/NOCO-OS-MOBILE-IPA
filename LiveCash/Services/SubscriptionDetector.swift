import Foundation

final class SubscriptionDetector {
    static let shared = SubscriptionDetector()

    func detect(from transactions: [Transaction]) -> [Subscription] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { normalizeMerchant($0.merchant) }

        var results: [Subscription] = []
        let cal = Calendar.current

        for (merchant, txs) in grouped where txs.count >= 2 {
            let sorted = txs.sorted { $0.date < $1.date }
            var intervals: [Int] = []
            for i in 1..<sorted.count {
                let days = cal.dateComponents([.day], from: sorted[i - 1].date, to: sorted[i].date).day ?? 0
                intervals.append(days)
            }
            guard !intervals.isEmpty else { continue }

            let avgInterval = Double(intervals.reduce(0, +)) / Double(intervals.count)
            let amounts = txs.map(\.amount)
            let avgAmount = amounts.reduce(0, +) / Double(amounts.count)
            let amountVariance = amounts.map { abs($0 - avgAmount) }.max() ?? 0

            guard amountVariance < max(avgAmount * 0.15, 1) else { continue }

            let frequency: SubscriptionFrequency?
            let billingDays: Int
            if avgInterval >= 25 && avgInterval <= 35 {
                frequency = .monthly
                billingDays = 30
            } else if avgInterval >= 350 && avgInterval <= 380 {
                frequency = .yearly
                billingDays = 365
            } else if avgInterval >= 5 && avgInterval <= 9 {
                frequency = .weekly
                billingDays = 7
            } else {
                frequency = nil
                billingDays = 30
            }

            guard let freq = frequency else { continue }

            let isSubCategory = txs.contains { $0.category == .subscription }
            let isKnownSub = FinanceCategory.detect(from: merchant) == .subscription
            guard isSubCategory || isKnownSub || txs.count >= 3 else { continue }

            let category = txs.first(where: { $0.category == .subscription })?.category
                ?? txs.map(\.category).mostCommon
                ?? .subscription

            results.append(Subscription(
                name: sorted.last?.merchant ?? merchant,
                amount: avgAmount,
                frequency: freq,
                detectedFromTransactions: true,
                lastSeen: sorted.last?.date,
                startDate: sorted.first?.date ?? Date(),
                billingPeriodDays: billingDays,
                category: category
            ))
        }

        return results.sorted { $0.monthlyCost > $1.monthlyCost }
    }

    private func normalizeMerchant(_ name: String) -> String {
        name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

private extension Array where Element == FinanceCategory {
    var mostCommon: FinanceCategory? {
        let counts = Dictionary(grouping: self, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
