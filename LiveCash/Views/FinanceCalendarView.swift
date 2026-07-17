import SwiftUI

enum FinanceCalendarScope: String, CaseIterable, Identifiable {
    case week = "Woche"
    case month = "Monat"
    case year = "Jahr"
    var id: String { rawValue }
}

enum CalendarMarkerKind: Hashable {
    case expense
    case income
    case salary
    case goal
    case subscription

    var color: Color {
        switch self {
        case .expense: return LiveCashTheme.expense
        case .income: return LiveCashTheme.income
        case .salary: return Color.green
        case .goal: return LiveCashTheme.accent
        case .subscription: return .purple
        }
    }

    var symbol: String {
        switch self {
        case .expense: return "arrow.down.circle.fill"
        case .income: return "arrow.up.circle.fill"
        case .salary: return "banknote.fill"
        case .goal: return "target"
        case .subscription: return "doc.fill"
        }
    }

    var label: String {
        switch self {
        case .expense: return "Ausgabe"
        case .income: return "Einnahme"
        case .salary: return "Gehalt"
        case .goal: return "Sparziel"
        case .subscription: return "Abo"
        }
    }
}

struct FinanceCalendarDaySummary: Identifiable {
    let id: Date
    let date: Date
    let markers: Set<CalendarMarkerKind>
    let expenseTotal: Double
    let incomeTotal: Double
    let goalTotal: Double
    let transactions: [Transaction]
    let subscriptions: [Subscription]
}

struct FinanceCalendarView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var scope: FinanceCalendarScope = .month
    @State private var visibleMonth = Date()
    @State private var selectedDay: FinanceCalendarDaySummary?

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            Picker("Ansicht", selection: $scope) {
                ForEach(FinanceCalendarScope.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            legend
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            switch scope {
            case .month:
                monthHeader
                weekdayHeader
                monthGrid
            case .week:
                weekList
            case .year:
                yearGrid
            }

            Spacer(minLength: 0)
        }
        .background(LiveCashTheme.screenBackground)
        .navigationTitle("Kalender")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDay) { day in
            FinanceCalendarDaySheet(summary: day)
        }
    }

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                legendItem(.expense)
                legendItem(.income)
                legendItem(.salary)
                legendItem(.goal)
                legendItem(.subscription)
            }
        }
    }

    private func legendItem(_ kind: CalendarMarkerKind) -> some View {
        HStack(spacing: 4) {
            Circle().fill(kind.color).frame(width: 8, height: 8)
            Text(kind.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                visibleMonth = cal.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                .font(LiveCashTheme.headlineFont)
            Spacer()
            Button {
                visibleMonth = cal.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }

    private var monthGrid: some View {
        let days = monthDays(for: visibleMonth)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date {
                    let summary = daySummary(for: date)
                    Button {
                        selectedDay = summary
                        HapticService.light(store: store)
                    } label: {
                        dayCell(summary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 54)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private func dayCell(_ summary: FinanceCalendarDaySummary) -> some View {
        let isToday = cal.isDateInToday(summary.date)
        return VStack(spacing: 4) {
            Text("\(cal.component(.day, from: summary.date))")
                .font(.system(size: 14, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(isToday ? LiveCashTheme.accent : .primary)
            HStack(spacing: 3) {
                ForEach(Array(summary.markers.prefix(4)), id: \.self) { marker in
                    Circle()
                        .fill(marker.color)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isToday ? LiveCashTheme.accent.opacity(0.1) : Color.primary.opacity(0.04))
        )
    }

    private var weekList: some View {
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        return List {
            ForEach(days, id: \.self) { date in
                let summary = daySummary(for: date)
                Button {
                    selectedDay = summary
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.wide).day().month()))
                                .font(LiveCashTheme.headlineFont)
                                .foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                ForEach(Array(summary.markers).sorted(by: { $0.label < $1.label }), id: \.self) { marker in
                                    Image(systemName: marker.symbol)
                                        .font(.caption2)
                                        .foregroundStyle(marker.color)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if summary.expenseTotal > 0 {
                                Text(String(format: "-%.0f€", summary.expenseTotal))
                                    .foregroundStyle(LiveCashTheme.expense)
                            }
                            if summary.incomeTotal > 0 {
                                Text(String(format: "+%.0f€", summary.incomeTotal))
                                    .foregroundStyle(LiveCashTheme.income)
                            }
                        }
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var yearGrid: some View {
        let year = cal.component(.year, from: visibleMonth)
        return ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    let date = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
                    let stats = monthStats(for: date)
                    Button {
                        visibleMonth = date
                        scope = .month
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(date.formatted(.dateTime.month(.abbreviated)))
                                .font(LiveCashTheme.captionFont.weight(.semibold))
                            Text(String(format: "-%.0f€", stats.expenses))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LiveCashTheme.expense)
                            Text(String(format: "+%.0f€", stats.income))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LiveCashTheme.income)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Data

    private func monthDays(for month: Date) -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start) // 1=Sun
        // Convert to Monday-first offset
        let mondayOffset = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: mondayOffset)
        var day = interval.start
        while day < interval.end {
            days.append(day)
            day = cal.date(byAdding: .day, value: 1, to: day) ?? interval.end
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func daySummary(for date: Date) -> FinanceCalendarDaySummary {
        let dayStart = cal.startOfDay(for: date)
        let txs = store.accountFilteredTransactions.filter { cal.isDate($0.date, inSameDayAs: date) }
        var markers = Set<CalendarMarkerKind>()
        var expense = 0.0
        var income = 0.0
        var goal = 0.0

        for tx in txs {
            if FinanceStore.isGoalContribution(tx) {
                if tx.merchant.hasPrefix("Sparziel Entnahme:") || tx.rawInput?.hasPrefix("goal-withdraw:") == true {
                    markers.insert(.goal)
                    // withdrawal restores available — still a sparbewegung
                } else {
                    markers.insert(.goal)
                    goal += tx.amount
                }
            } else if tx.type == .expense {
                markers.insert(.expense)
                expense += tx.amount
                if tx.category == .subscription {
                    markers.insert(.subscription)
                }
            } else {
                if isSalary(tx) {
                    markers.insert(.salary)
                } else {
                    markers.insert(.income)
                }
                income += tx.amount
            }
        }

        let subs = store.subscriptions.filter { sub in
            guard let next = approximateBillingDate(for: sub, around: date) else { return false }
            return cal.isDate(next, inSameDayAs: date)
        }
        if !subs.isEmpty { markers.insert(.subscription) }

        return FinanceCalendarDaySummary(
            id: dayStart,
            date: date,
            markers: markers,
            expenseTotal: expense,
            incomeTotal: income,
            goalTotal: goal,
            transactions: txs.sorted { $0.date > $1.date },
            subscriptions: subs
        )
    }

    private func monthStats(for month: Date) -> (expenses: Double, income: Double) {
        let txs = store.transactions(inMonth: month)
        let expenses = txs.filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }.reduce(0) { $0 + $1.amount }
        let income = txs.filter { $0.type == .income && !FinanceStore.isGoalContribution($0) }.reduce(0) { $0 + $1.amount }
        return (expenses, income)
    }

    private func isSalary(_ tx: Transaction) -> Bool {
        let m = tx.merchant.lowercased()
        return tx.type == .income && (m.contains("gehalt") || m.contains("salary") || m.contains("lohn") || tx.amount >= 800)
    }

    private func approximateBillingDate(for sub: Subscription, around date: Date) -> Date? {
        // Approximate next/current billing by aligning startDate day-of-month or weekly cycle.
        let start = sub.startDate
        switch sub.frequency {
        case .monthly, .yearly:
            var comps = cal.dateComponents([.year, .month], from: date)
            comps.day = min(cal.component(.day, from: start), 28)
            return cal.date(from: comps)
        case .weekly:
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: date)).day ?? 0
            if days % 7 == 0 { return cal.startOfDay(for: date) }
            return nil
        }
    }
}

struct FinanceCalendarDaySheet: View {
    @EnvironmentObject private var store: FinanceStore
    let summary: FinanceCalendarDaySummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Tagesübersicht") {
                    LabeledContent("Ausgaben", value: String(format: "%.2f€", summary.expenseTotal))
                    LabeledContent("Einnahmen", value: String(format: "%.2f€", summary.incomeTotal))
                    LabeledContent("Sparbewegungen", value: String(format: "%.2f€", summary.goalTotal))
                }

                if !summary.markers.isEmpty {
                    Section("Markierungen") {
                        ForEach(Array(summary.markers).sorted(by: { $0.label < $1.label }), id: \.self) { marker in
                            Label(marker.label, systemImage: marker.symbol)
                                .foregroundStyle(marker.color)
                        }
                    }
                }

                if !summary.subscriptions.isEmpty {
                    Section("Abos an diesem Tag") {
                        ForEach(summary.subscriptions) { sub in
                            HStack {
                                Text(sub.name)
                                Spacer()
                                Text(String(format: "-%.2f€", sub.amount))
                                    .foregroundStyle(LiveCashTheme.expense)
                            }
                        }
                    }
                }

                Section("Buchungen") {
                    if summary.transactions.isEmpty {
                        Text("Keine Buchungen an diesem Tag.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(summary.transactions) { tx in
                            TransactionRow(transaction: tx)
                                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                }

                Section("Notizen") {
                    Text(dayNote)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(summary.date.formatted(date: .complete, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var dayNote: String {
        if summary.expenseTotal == 0 && summary.incomeTotal == 0 && summary.goalTotal == 0 {
            return "Ruhiger Tag — keine erfassten Bewegungen."
        }
        if summary.goalTotal > 0 {
            return String(format: "Du hast %.0f€ Richtung Sparziel bewegt.", summary.goalTotal)
        }
        if summary.incomeTotal > summary.expenseTotal {
            return "Netto positiv — guter Tag für die Übersicht."
        }
        return String(format: "Netto −%.0f€ an diesem Tag.", max(summary.expenseTotal - summary.incomeTotal, 0))
    }
}
