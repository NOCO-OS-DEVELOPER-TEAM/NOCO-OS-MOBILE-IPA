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
            if avgInterval >= 25 && avgInterval <= 35 {
                frequency = .monthly
            } else if avgInterval >= 350 && avgInterval <= 380 {
                frequency = .yearly
            } else if avgInterval >= 5 && avgInterval <= 9 {
                frequency = .weekly
            } else {
                frequency = nil
            }

            guard let freq = frequency else { continue }

            let isSubCategory = txs.contains { $0.category == .subscription }
            let isKnownSub = FinanceCategory.detect(from: merchant) == .subscription
            guard isSubCategory || isKnownSub || txs.count >= 3 else { continue }

            results.append(Subscription(
                name: sorted.last?.merchant ?? merchant,
                amount: avgAmount,
                frequency: freq,
                detectedFromTransactions: true,
                lastSeen: sorted.last?.date
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
