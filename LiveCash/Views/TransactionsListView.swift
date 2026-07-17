import SwiftUI
import UIKit

enum TransactionListFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case expenses = "Nur Ausgaben"
    case income = "Nur Einnahmen"
    case savings = "Nur Sparbewegungen"
    case subscriptions = "Nur Abonnements"

    var id: String { rawValue }
}

enum TransactionSortMode: String, CaseIterable, Identifiable {
    case newest = "Neueste zuerst"
    case highestExpense = "Höchste Ausgaben"
    case lowestExpense = "Niedrigste Ausgaben"
    case highestIncome = "Höchste Einnahmen"
    case biggestSavings = "Größte Sparbewegungen"

    var id: String { rawValue }
}

struct TransactionsListView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showFilter = false
    @State private var showAddTransaction = false
    @State private var showGoalContribution = false
    @State private var showReceiptScan = false
    @State private var showAddMenu = false

    @State private var filter: TransactionListFilter = .all
    @State private var categoryFilter: FinanceCategory?
    @State private var dateFrom: Date?
    @State private var dateTo: Date?
    @State private var sortMode: TransactionSortMode = .newest

    private var displayed: [Transaction] {
        var list = store.accountFilteredTransactions

        switch filter {
        case .all: break
        case .expenses:
            list = list.filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }
        case .income:
            list = list.filter { $0.type == .income && !FinanceStore.isGoalContribution($0) }
        case .savings:
            list = list.filter { FinanceStore.isGoalContribution($0) }
        case .subscriptions:
            list = list.filter { $0.category == .subscription || $0.merchant.lowercased().contains("abo") }
        }

        if let categoryFilter {
            list = list.filter { $0.category == categoryFilter }
        }
        if let dateFrom {
            list = list.filter { $0.date >= Calendar.current.startOfDay(for: dateFrom) }
        }
        if let dateTo {
            let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: dateTo) ?? dateTo
            list = list.filter { $0.date <= end }
        }

        switch sortMode {
        case .newest:
            return list.sorted { $0.date > $1.date }
        case .highestExpense:
            return list.filter { $0.type == .expense }.sorted { $0.amount > $1.amount }
                + list.filter { $0.type != .expense }
        case .lowestExpense:
            return list.filter { $0.type == .expense }.sorted { $0.amount < $1.amount }
                + list.filter { $0.type != .expense }
        case .highestIncome:
            return list.filter { $0.type == .income }.sorted { $0.amount > $1.amount }
                + list.filter { $0.type != .income }
        case .biggestSavings:
            return list.filter { FinanceStore.isGoalContribution($0) }.sorted { $0.amount > $1.amount }
                + list.filter { !FinanceStore.isGoalContribution($0) }
        }
    }

    private var groupedSections: [(title: String, items: [Transaction])] {
        guard sortMode == .newest else {
            return [("Alle", displayed)]
        }
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .full
        var sections: [(title: String, items: [Transaction])] = []
        for tx in displayed {
            let day = cal.startOfDay(for: tx.date)
            let title: String
            if cal.isDateInToday(day) {
                title = "Heute"
            } else if cal.isDateInYesterday(day) {
                title = "Gestern"
            } else {
                title = formatter.string(from: day)
            }
            if let idx = sections.firstIndex(where: { $0.title == title }) {
                sections[idx].items.append(tx)
            } else {
                sections.append((title, [tx]))
            }
        }
        return sections
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                quickControls
                Group {
                    if displayed.isEmpty {
                        ContentUnavailableView(
                            store.transactions.isEmpty ? "Deine Finanzreise beginnt heute 🚀" : "Keine Treffer",
                            systemImage: store.transactions.isEmpty ? "airplane.departure" : "tray",
                            description: Text(store.transactions.isEmpty
                                ? "Erste Ausgabe unten tippen — z. B. „Kaffee 4,50“ — oder den Assistenten fragen."
                                : "Passe Filter oder Sortierung an.")
                        )
                    } else {
                        List {
                            ForEach(groupedSections, id: \.title) { section in
                                Section {
                                    ForEach(Array(section.items.enumerated()), id: \.element.id) { index, tx in
                                        NavigationLink {
                                            TransactionDetailView(transactionID: tx.id)
                                        } label: {
                                            TransactionRow(transaction: tx)
                                        }
                                        .simultaneousGesture(TapGesture().onEnded {
                                            HapticService.navigate(store: store)
                                        })
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                HapticService.warning(store: store)
                                                withAnimation(LiveCashMotion.snappy) {
                                                    store.deleteTransaction(tx)
                                                }
                                            } label: {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                        }
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .listRowAppear(index: min(index, 8))
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                    }
                                } header: {
                                    Text(section.title)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .animation(LiveCashMotion.crossfade, value: sortMode)
                        .animation(LiveCashMotion.crossfade, value: filter)
                    }
                }
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Buchungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showAddMenu = true
                            HapticService.medium(store: store)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(LiveCashTheme.accent)
                        }
                        .buttonStyle(PremiumPressStyle(scale: 0.9))
                        Button {
                            showReceiptScan = true
                            HapticService.light(store: store)
                        } label: {
                            Image(systemName: "camera")
                        }
                        .buttonStyle(PremiumPressStyle(scale: 0.9))
                    }
                }
            }
            .sheet(isPresented: $showFilter) {
                TransactionFilterSheet(
                    filter: $filter,
                    categoryFilter: $categoryFilter,
                    dateFrom: $dateFrom,
                    dateTo: $dateTo
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showReceiptScan) { ReceiptScanView() }
            .sheet(isPresented: $showAddMenu) {
                AddActionSheet { action in
                    switch action {
                    case .transaction: showAddTransaction = true
                    case .goalContribution: showGoalContribution = true
                    case .receipt: showReceiptScan = true
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) { AddTransactionView() }
            .sheet(isPresented: $showGoalContribution) {
                GoalContributionView(prefilledAmount: nil)
            }
        }
    }

    private var quickControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    showFilter = true
                    HapticService.light(store: store)
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PremiumPressStyle())
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(filterActive ? LiveCashTheme.accent.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
                )

                Button {
                    cycleSortMode()
                } label: {
                    Label("Sortierung", systemImage: "arrow.up.arrow.down.circle")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PremiumPressStyle())
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }

            Text("Aktuell: \(sortMode.rawValue)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func cycleSortMode() {
        let all = TransactionSortMode.allCases
        guard let idx = all.firstIndex(of: sortMode) else { return }
        sortMode = all[(idx + 1) % all.count]
        HapticService.selection(store: store)
    }

    private var filterActive: Bool {
        filter != .all || categoryFilter != nil || dateFrom != nil || dateTo != nil
    }
}

private struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filter: TransactionListFilter
    @Binding var categoryFilter: FinanceCategory?
    @Binding var dateFrom: Date?
    @Binding var dateTo: Date?
    @State private var useDateRange = false

    var body: some View {
        NavigationStack {
            List {
                Section("Art") {
                    ForEach(TransactionListFilter.allCases) { item in
                        Button {
                            filter = item
                        } label: {
                            HStack {
                                Text(item.rawValue).foregroundStyle(.primary)
                                Spacer()
                                if filter == item {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(LiveCashTheme.accent)
                                }
                            }
                        }
                    }
                }

                Section("Kategorie") {
                    Button("Alle Kategorien") { categoryFilter = nil }
                    ForEach(FinanceCategory.allCases.filter { $0 != .income }) { cat in
                        Button {
                            categoryFilter = cat
                        } label: {
                            HStack {
                                Label(cat.rawValue, systemImage: cat.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if categoryFilter == cat {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(LiveCashTheme.accent)
                                }
                            }
                        }
                    }
                }

                Section("Zeitraum") {
                    Toggle("Zeitraum einschränken", isOn: $useDateRange)
                    if useDateRange {
                        DatePicker("Von", selection: Binding(
                            get: { dateFrom ?? Date() },
                            set: { dateFrom = $0 }
                        ), displayedComponents: .date)
                        DatePicker("Bis", selection: Binding(
                            get: { dateTo ?? Date() },
                            set: { dateTo = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zurücksetzen") {
                        filter = .all
                        categoryFilter = nil
                        dateFrom = nil
                        dateTo = nil
                        useDateRange = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        if !useDateRange {
                            dateFrom = nil
                            dateTo = nil
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                useDateRange = dateFrom != nil || dateTo != nil
            }
        }
    }
}
