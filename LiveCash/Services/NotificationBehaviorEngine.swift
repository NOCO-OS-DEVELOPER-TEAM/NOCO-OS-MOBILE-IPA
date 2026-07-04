import Foundation

enum SmartNotificationKind: String {
    case weekdayPattern
    case spontaneousSpending
    case incomeDetected
    case subscriptionRenewal
    case softEngagement
    case monthStart
    case weeklyReminder
    case highSpendingToday
}

struct SmartNotificationPayload {
    let id: String
    let title: String
    let body: String
    let kind: SmartNotificationKind
    let delay: TimeInterval
    let priority: Int
    var calendar: DateComponents?
    var repeats: Bool = false
}

@MainActor
enum NotificationBehaviorEngine {
    private static let weekdayNames = ["", "Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]

    /// Returns at most `limit` highly relevant notifications — quality over quantity.
    static func scheduledPayloads(for store: FinanceStore, limit: Int = 4) -> [SmartNotificationPayload] {
        let prefs = store.notificationPreferences
        var candidates: [SmartNotificationPayload] = []

        if prefs.monthStartReminder, let p = monthStartSalaryReminder() {
            candidates.append(p)
        }
        if prefs.weeklyReminder {
            candidates.append(weeklyLoggingReminder(learning: store.notificationLearning))
        }
        if prefs.weekdayPatterns, let p = todayWeekdayWarning(for: store) {
            candidates.append(p)
        }
        if prefs.weekdayPatterns, let p = highSpendingToday(for: store) {
            candidates.append(p)
        }
        if prefs.subscriptionReminders {
            candidates.append(contentsOf: subscriptionReminders(for: store))
        }
        if prefs.softEngagement, let p = adaptiveCheckIn(for: store) {
            candidates.append(p)
        }

        return Array(candidates.sorted { $0.priority > $1.priority }.prefix(limit))
    }

    static func monthStartSalaryReminder() -> SmartNotificationPayload? {
        SmartNotificationPayload(
            id: "month-start-salary",
            title: "Neuer Monat",
            body: "Du hast gerade dein Gehalt bekommen 💸 Trag es ein und plane deinen Monat gut. Versuch es nicht direkt auszugeben.",
            kind: .monthStart,
            delay: 0,
            priority: 100,
            calendar: DateComponents(day: 1, hour: 9, minute: 0),
            repeats: true
        )
    }

    static func weeklyLoggingReminder(learning: NotificationLearning) -> SmartNotificationPayload {
        let hour = min(max(learning.typicalLogHour, 8), 21)
        return SmartNotificationPayload(
            id: "weekly-logging",
            title: "Live Cash",
            body: "Hast du deine Ausgaben schon eingetragen?",
            kind: .weeklyReminder,
            delay: 0,
            priority: 80,
            calendar: DateComponents(weekday: 2, hour: hour, minute: 0),
            repeats: true
        )
    }

    static func todayWeekdayWarning(for store: FinanceStore) -> SmartNotificationPayload? {
        let cal = Calendar.current
        let todayWD = cal.component(.weekday, from: Date())
        let expenses = store.accountFilteredTransactions.filter { $0.type == .expense }
        guard expenses.count >= 10 else { return nil }

        var totals: [Int: Double] = [:]
        for tx in expenses {
            totals[cal.component(.weekday, from: tx.date), default: 0] += tx.amount
        }
        guard let peak = totals.max(by: { $0.value < $1.value }),
              peak.key == todayWD,
              let avg = totals.values.isEmpty ? nil : totals.values.reduce(0, +) / Double(totals.count),
              peak.value > avg * 1.2 else { return nil }

        let name = weekdayNames[peak.key]
        return SmartNotificationPayload(
            id: "weekday-today-\(todayWD)",
            title: "Ausgaben-Muster",
            body: "\(name)s sind bei dir oft ausgabenstark — behalte heute dein Budget im Blick.",
            kind: .weekdayPattern,
            delay: 60 * 60 * 10,
            priority: 60
        )
    }

    static func highSpendingToday(for store: FinanceStore) -> SmartNotificationPayload? {
        let today = store.todayExpenses
        guard today > 0 else { return nil }
        let avg = store.dailyAverageExpenses
        guard avg > 5, today > avg * 1.45 else { return nil }
        return SmartNotificationPayload(
            id: "high-spending-today",
            title: "Heute",
            body: String(format: "Du gibst heute mehr aus als üblich (%.0f€ vs. Ø %.0f€).", today, avg),
            kind: .highSpendingToday,
            delay: 60 * 60 * 4,
            priority: 70
        )
    }

    static func spontaneousSpendingAlert(recentWindow store: FinanceStore) -> SmartNotificationPayload? {
        let hourAgo = Date().addingTimeInterval(-3600)
        let recent = store.accountFilteredTransactions.filter { $0.type == .expense && $0.date >= hourAgo }
        guard recent.count >= 4 else { return nil }
        let total = recent.reduce(0) { $0 + $1.amount }
        return SmartNotificationPayload(
            id: "spontaneous-\(Int(Date().timeIntervalSince1970 / 3600))",
            title: "Spontan-Ausgaben",
            body: String(format: "Du gibst gerade ungewöhnlich viel auf einmal aus (%.0f€). Möchtest du kurz prüfen?", total),
            kind: .spontaneousSpending,
            delay: 5,
            priority: 90
        )
    }

    static func incomeReaction(for transaction: Transaction, store: FinanceStore) -> SmartNotificationPayload? {
        guard transaction.type == .income else { return nil }
        let goalHint = store.goals.first.map { " Tipp: Lege einen Teil für „\($0.name)“ zurück." } ?? ""
        return SmartNotificationPayload(
            id: "income-\(transaction.id.uuidString)",
            title: "Einnahme erkannt",
            body: String(format: "+%.0f€ · %@.%@", transaction.amount, transaction.merchant, goalHint),
            kind: .incomeDetected,
            delay: 3,
            priority: 85
        )
    }

    static func subscriptionReminders(for store: FinanceStore) -> [SmartNotificationPayload] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return store.subscriptions.compactMap { sub -> SmartNotificationPayload? in
            guard let last = sub.lastSeen ?? store.transactions.first(where: {
                $0.merchant.lowercased().contains(sub.name.lowercased())
            })?.date else { return nil }

            let daysUntil: Int
            switch sub.frequency {
            case .weekly:
                daysUntil = max(7 - ((cal.dateComponents([.day], from: cal.startOfDay(for: last), to: today).day ?? 0) % 7), 0)
            case .monthly:
                let next = cal.date(byAdding: .month, value: 1, to: last) ?? last
                daysUntil = max(cal.dateComponents([.day], from: today, to: cal.startOfDay(for: next)).day ?? 99, 0)
            case .yearly:
                let next = cal.date(byAdding: .year, value: 1, to: last) ?? last
                daysUntil = max(cal.dateComponents([.day], from: today, to: cal.startOfDay(for: next)).day ?? 99, 0)
            }

            guard daysUntil <= 2 else { return nil }
            return SmartNotificationPayload(
                id: "sub-\(sub.id.uuidString)",
                title: "Abo-Erinnerung",
                body: "\(sub.name) wird in \(daysUntil == 0 ? "heute" : "\(daysUntil) Tag\(daysUntil == 1 ? "" : "en")") erneut abgebucht.",
                kind: .subscriptionRenewal,
                delay: 60 * 60 * 12,
                priority: 55
            )
        }
    }

    static func adaptiveCheckIn(for store: FinanceStore) -> SmartNotificationPayload? {
        let cal = Calendar.current
        guard !cal.isDateInToday(store.lastTransactionDate ?? .distantPast) else { return nil }
        let hour = min(max(store.notificationLearning.typicalLogHour, 8), 21)
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return SmartNotificationPayload(
            id: "adaptive-checkin",
            title: "Live Cash",
            body: "Hast du heute schon Ausgaben eingetragen?",
            kind: .softEngagement,
            delay: 0,
            priority: 50,
            calendar: components,
            repeats: false
        )
    }

    static func recordLoggingHour(_ hour: Int, learning: inout NotificationLearning) {
        let clamped = min(max(hour, 0), 23)
        if learning.logSampleCount == 0 {
            learning.typicalLogHour = clamped
        } else {
            learning.typicalLogHour = (learning.typicalLogHour * 6 + clamped) / 7
        }
        learning.logSampleCount += 1
    }
}
