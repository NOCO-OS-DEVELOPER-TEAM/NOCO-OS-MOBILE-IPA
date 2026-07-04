import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showReceiptScan = false
    @State private var showQuickInsight = false
    @State private var idleTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if showQuickInsight {
                        QuickInsightPanel {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showQuickInsight = false
                            }
                        }
                    }
                    headerSection
                    summaryCards
                    if let top = store.topCategoryThisMonth {
                        insightCard(title: "Top-Kategorie", value: top.0.rawValue, subtitle: LiveCashTheme.money(top.1))
                    }
                    goalsPreview
                    subscriptionsPreview
                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Live Cash")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                SmartInputBar(showReceiptScan: $showReceiptScan)
            }
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanView()
            }
            .onAppear { scheduleQuickInsight() }
            .onDisappear { idleTask?.cancel() }
            .onTapGesture { resetQuickInsightTimer() }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(monthTitle)
                .font(LiveCashTheme.captionFont)
                .foregroundStyle(.secondary)
            Text(LiveCashTheme.money(store.currentMonthExpenses))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(LiveCashTheme.expense)
            Text("Ausgaben diesen Monat")
                .font(LiveCashTheme.captionFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            miniCard(title: "Einnahmen", value: store.currentMonthIncome, color: LiveCashTheme.income, positive: true)
            miniCard(title: "Saldo", value: store.currentBalance, color: store.currentBalance >= 0 ? LiveCashTheme.income : LiveCashTheme.expense, positive: store.currentBalance >= 0)
        }
    }

    private func miniCard(title: String, value: Double, color: Color, positive: Bool) -> some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text(positive && value >= 0 ? "+\(String(format: "%.2f€", value))" : String(format: "%.2f€", value))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(color)
            }
        }
    }

    private func insightCard(title: String, value: String, subtitle: String) -> some View {
        LiveCashCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(LiveCashTheme.headlineFont)
                    Text(subtitle)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.expense)
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundStyle(LiveCashTheme.accentSoft)
                    .overlay {
                        Image(systemName: "chart.pie.fill")
                            .foregroundStyle(LiveCashTheme.accent)
                    }
            }
        }
    }

    private var goalsPreview: some View {
        Group {
            if !store.goals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Sparziele")
                    ForEach(store.goals.prefix(2)) { goal in
                        GoalCard(goal: goal, monthlySavingsRate: store.monthlySavingsRate, compact: true)
                    }
                }
            }
        }
    }

    private var subscriptionsPreview: some View {
        Group {
            if !store.subscriptions.isEmpty {
                LiveCashCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Abonnements")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f€ / Monat", store.monthlySubscriptionCost))
                            .font(LiveCashTheme.headlineFont)
                        Text("\(store.subscriptions.count) erkannt")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Zuletzt")
            if store.transactions.isEmpty {
                LiveCashCard {
                    Text("Noch keine Buchungen. Tippe unten etwas ein, z. B. „Kaffee 4,50“.")
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(store.transactions.prefix(5)) { tx in
                    NavigationLink {
                        TransactionDetailView(transactionID: tx.id)
                    } label: {
                        TransactionRow(transaction: tx)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date()).capitalized
    }

    private func scheduleQuickInsight() {
        idleTask?.cancel()
        idleTask = Task {
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    showQuickInsight = true
                }
            }
        }
    }

    private func resetQuickInsightTimer() {
        showQuickInsight = false
        scheduleQuickInsight()
    }
}
