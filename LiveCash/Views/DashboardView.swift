import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showReceiptScan = false
    @State private var showQuickInsight = false
    @State private var showFinancialStory = false
    @State private var idleTask: Task<Void, Never>?

    private var contentSpacing: CGFloat {
        store.appSettings.ui.compactMode ? 16 : 28
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: contentSpacing) {
                    headerSection

                    if store.appSettings.moneyCard.displayLevel != .simple {
                        summaryCards
                    }

                    SmartShortcutsView()

                    if store.appSettings.moneyCard.displayLevel != .simple {
                        recentSection
                    }

                    if store.appSettings.moneyCard.displayLevel == .advanced,
                       let top = store.topCategoryThisMonth {
                        detailInsightCard(title: "Top-Kategorie", value: top.0.rawValue, subtitle: LiveCashTheme.money(top.1))
                    }

                    if store.appSettings.moneyCard.displayLevel == .advanced {
                        goalsPreview
                        subscriptionsPreview
                    }

                    if showQuickInsight {
                        QuickInsightPanel {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showQuickInsight = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Live Cash")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFinancialStory = true
                    } label: {
                        Image(systemName: "sparkles.rectangle.stack")
                            .foregroundStyle(LiveCashTheme.accent)
                    }
                    .accessibilityLabel("Finanz-Story")
                }
            }
            .safeAreaInset(edge: .bottom) {
                SmartInputBar(showReceiptScan: $showReceiptScan)
            }
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanView()
            }
            .sheet(isPresented: $showFinancialStory) {
                FinancialStoryView()
            }
            .onAppear { scheduleQuickInsight() }
            .onDisappear { idleTask?.cancel() }
            .onTapGesture { resetQuickInsightTimer() }
        }
    }

    private var headerSection: some View {
        MoneyCardGlassView {
            VStack(alignment: .leading, spacing: 12) {
                if let account = store.activeAccount, store.accounts.count > 1 {
                    Label(account.name, systemImage: account.icon)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.accent)
                }
                Text(monthTitle)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)

                SensitiveBalanceView(scope: .home) {
                    Text(balanceText)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(store.availableBalance >= 0 ? LiveCashTheme.income : LiveCashTheme.expense)
                }

                Text("Verfügbares Geld")
                    .font(LiveCashTheme.bodyFont.weight(.medium))
                    .foregroundStyle(.secondary)

                wealthOverviewRow

                if store.loginReward.loginStreakDays > 0 || store.loginReward.coins > 0 {
                    HStack(spacing: 14) {
                        Label("\(store.loginReward.loginStreakDays) Tage", systemImage: "flame.fill")
                            .font(LiveCashTheme.captionFont.weight(.semibold))
                            .foregroundStyle(.orange)
                        Label("\(store.loginReward.coins) Coins", systemImage: "circle.circle.fill")
                            .font(LiveCashTheme.captionFont.weight(.semibold))
                            .foregroundStyle(.yellow)
                        Spacer()
                    }
                }

                HStack(spacing: 16) {
                    Label(LiveCashTheme.money(store.currentMonthExpenses), systemImage: "arrow.down.circle.fill")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.expense)
                    Label(LiveCashTheme.money(store.currentMonthIncome), systemImage: "arrow.up.circle.fill")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.income)
                }
            }
        }
    }

    private var wealthOverviewRow: some View {
        HStack(spacing: 12) {
            wealthChip(title: "Geld in Sparzielen", value: store.blockedInGoals, color: LiveCashTheme.accent)
            wealthChip(title: "Gesamtvermögen", value: store.totalWealth, color: store.totalWealth >= 0 ? LiveCashTheme.income : LiveCashTheme.expense)
        }
    }

    private func wealthChip(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(LiveCashTheme.money(value))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            miniCard(title: "Heute ausgegeben", value: store.todayExpenses, color: LiveCashTheme.expense, positive: false)
            miniCard(title: "Ø pro Tag", value: store.dailyAverageExpenses, color: .secondary, positive: false)
        }
    }

    private func miniCard(title: String, value: Double, color: Color, positive: Bool) -> some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text(positive && value >= 0 ? "+\(String(format: "%.2f€", value))" : String(format: "%.2f€", value))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func detailInsightCard(title: String, value: String, subtitle: String) -> some View {
        LiveCashCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(LiveCashTheme.bodyFont.weight(.medium))
                    Text(subtitle)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.expense)
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.body)
                    .foregroundStyle(LiveCashTheme.accent.opacity(0.8))
            }
        }
    }

    private var goalsPreview: some View {
        Group {
            if !store.goals.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Sparziele")
                    ForEach(store.goals.prefix(2)) { goal in
                        GoalCard(
                            goal: goal,
                            monthlySavingsRate: store.monthlySavingsRate,
                            compact: true,
                            showProgress: store.appSettings.savings.showProgress
                        )
                    }
                }
            }
        }
    }

    private var subscriptionsPreview: some View {
        Group {
            if !store.subscriptions.isEmpty {
                LiveCashCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Abonnements")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f€ / Monat", store.monthlySubscriptionCost))
                            .font(LiveCashTheme.headlineFont)
                        Text("\(store.subscriptions.count) erkannt")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
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

    private var balanceText: String {
        let value = store.availableBalance
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f€", value))"
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
