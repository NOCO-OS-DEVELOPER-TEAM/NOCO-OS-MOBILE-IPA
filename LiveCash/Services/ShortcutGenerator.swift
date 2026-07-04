import Foundation

enum ShortcutGenerator {
    static func generate(from transactions: [Transaction], existing: [QuickShortcut]) -> [QuickShortcut] {
        let manual = existing.filter(\.isUserDefined).sorted { $0.sortOrder < $1.sortOrder }
        if manual.count >= 6 { return Array(manual.prefix(6)) }

        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.merchant.lowercased() })

        let autoCandidates: [QuickShortcut] = grouped.map { _, items in
            let latest = items.max(by: { $0.date < $1.date })!
            let avg = items.reduce(0) { $0 + $1.amount } / Double(items.count)
            return QuickShortcut(
                merchant: latest.merchant,
                amount: (avg * 10).rounded() / 10,
                type: .expense,
                category: latest.category,
                location: latest.location,
                sortOrder: items.count,
                isUserDefined: false
            )
        }
        .sorted { $0.sortOrder > $1.sortOrder }

        var result = manual
        for candidate in autoCandidates {
            guard result.count < 6 else { break }
            if result.contains(where: { $0.merchant.lowercased() == candidate.merchant.lowercased() }) { continue }
            var c = candidate
            c.sortOrder = result.count
            result.append(c)
        }

        if result.count < 6 {
            let defaults = [
                QuickShortcut(merchant: "Kaffee", amount: 3.5, category: .food, sortOrder: result.count),
                QuickShortcut(merchant: "Mittagessen", amount: 12, category: .food, sortOrder: result.count + 1),
                QuickShortcut(merchant: "Tanken", amount: 50, category: .transport, sortOrder: result.count + 2)
            ]
            for d in defaults where result.count < 6 {
                if !result.contains(where: { $0.merchant.lowercased() == d.merchant.lowercased() }) {
                    var item = d
                    item.sortOrder = result.count
                    result.append(item)
                }
            }
        }

        return Array(result.prefix(6)).enumerated().map { idx, s in
            var copy = s
            copy.sortOrder = idx
            return copy
        }
    }
}
