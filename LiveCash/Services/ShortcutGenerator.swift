import Foundation

enum ShortcutGenerator {
    static func generate(
        from transactions: [Transaction],
        existing: [QuickShortcut],
        settings: ShortcutSettings
    ) -> [QuickShortcut] {
        let protected = existing
            .filter { $0.isUserDefined || $0.isPinned }
            .sorted { $0.sortOrder < $1.sortOrder }
        let cap = min(max(settings.maxActiveShortcuts, 1), 6)
        if protected.count >= cap { return Array(protected.prefix(cap)) }
        if !settings.autoShortcutsEnabled {
            return reindex(Array(protected.prefix(cap)))
        }

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

        var result = protected
        for candidate in autoCandidates {
            guard result.count < cap else { break }
            if result.contains(where: { $0.merchant.lowercased() == candidate.merchant.lowercased() }) { continue }
            var c = candidate
            c.sortOrder = result.count
            result.append(c)
        }

        if result.count < cap {
            let defaults: [QuickShortcut] = [
                QuickShortcut(merchant: "Kaffee", amount: 3.5, category: .food),
                QuickShortcut(merchant: "Mittagessen", amount: 12, category: .food),
                QuickShortcut(merchant: "Tanken", amount: 50, category: .transport),
                QuickShortcut(merchant: "Assistant", amount: 0, actionType: .assistant),
                QuickShortcut(merchant: "Übersicht", amount: 0, actionType: .overview)
            ]
            for d in defaults where result.count < cap {
                if d.actionType != .book || !result.contains(where: { $0.merchant.lowercased() == d.merchant.lowercased() }) {
                    var item = d
                    item.sortOrder = result.count
                    result.append(item)
                }
            }
        }

        return reindex(Array(result.prefix(cap)))
    }

    private static func reindex(_ shortcuts: [QuickShortcut]) -> [QuickShortcut] {
        shortcuts.enumerated().map { idx, s in
            var copy = s
            copy.sortOrder = idx
            return copy
        }
    }
}
