import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showReceiptScan = false
    @State private var showFinancialStory = false
    @State private var showFinanceReport = false

    private var contentSpacing: CGFloat {
        store.appSettings.ui.compactMode ? 16 : 24
    }

    private var insightTips: [PersonalFinanceInsights.Tip] {
        var tips: [PersonalFinanceInsights.Tip] = []
        if let t = PersonalFinanceInsights.categoryMonthOverMonth(store: store) { tips.append(t) }
        if let t = PersonalFinanceInsights.frequentCategory(store: store) { tips.append(t) }
        if let t = PersonalFinanceInsights.goalAccelerationTip(store: store) { tips.append(t) }
        if let t = PersonalFinanceInsights.loggingHabit(store: store) { tips.append(t) }
        if tips.isEmpty {
            let memory = AssistantMemory.build(from: store)
            if memory.prevMonthExpenses > 0 {
                let delta = memory.monthExpenses - memory.prevMonthExpenses
                tips.append(.init(
                    shortTitle: delta <= 0 ? "Weniger als Vormonat" : "Mehr als Vormonat",
                    message: delta <= 0
                        ? String(format: "Du hast %.0f€ weniger ausgegeben als letzten Monat.", abs(delta))
                        : String(format: "Du hast %.0f€ mehr ausgegeben als letzten Monat.", delta),
                    action: .monthCompare
                ))
            }
            if let wd = memory.expensiveWeekday {
                tips.append(.init(
                    shortTitle: "Teuerster Tag",
                    message: "Dein \(wd) ist typischerweise dein teuerster Tag.",
                    action: .spendingPace
                ))
            }
        }
        return Array(tips.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: contentSpacing) {
                        Color.clear.frame(height: 8)
                        headerSection
                            .appearScale(delay: 0)
                        savingsProgressSection
                            .appearFade(delay: 0.08)
                        insightsSection
                            .appearFade(delay: 0.14)
                        recentSection
                            .appearFade(delay: 0.2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(LiveCashTheme.screenBackground)
                .safeAreaInset(edge: .top, spacing: 0) {
                    persistentStatusBar
                }

                if store.isAssistantExpanded {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            HapticService.soft(store: store)
                            NotificationCenter.default.post(name: .liveCashCollapseAssistant, object: nil)
                        }
                        .transition(.opacity)
                        .zIndex(1)
                }

                SmartInputBar(showReceiptScan: $showReceiptScan)
                    .zIndex(2)
            }
            .animation(LiveCashMotion.panelSpring, value: store.isAssistantExpanded)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanView()
            }
            .sheet(isPresented: $showFinancialStory) {
                FinancialStoryView()
            }
            .sheet(isPresented: $showFinanceReport) {
                FinanceReportView()
            }
        }
    }

    private var persistentStatusBar: some View {
        HStack(spacing: 12) {
            Text("Live Cash")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Spacer(minLength: 0)

            Button {
                showFinanceReport = true
                HapticService.medium(store: store)
            } label: {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LiveCashTheme.accent)
                    .symbolEffect(.bounce, value: showFinanceReport)
            }
            .buttonStyle(PremiumPressStyle(scale: 0.9))
            .accessibilityLabel("Mein Finanzbericht")

            Button {
                showFinancialStory = true
                HapticService.medium(store: store)
            } label: {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LiveCashTheme.accent)
            }
            .buttonStyle(PremiumPressStyle(scale: 0.9))
            .accessibilityLabel("Financial Story")

            if store.loginReward.loginStreakDays > 0 {
                PulsingFlameLabel(days: store.loginReward.loginStreakDays)
                    .id("flame-\(store.loginReward.loginStreakDays)")
                    .transition(.scale.combined(with: .opacity))
            }
            SpinningCoinLabel(coins: max(store.loginReward.coins, 0))
                .id("coins-\(store.loginReward.coins)")
        }
        .animation(LiveCashMotion.softSpring, value: store.loginReward.loginStreakDays)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.35)
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
                    AnimatedMoneyText(
                        value: store.availableBalance,
                        color: store.availableBalance >= 0 ? LiveCashTheme.income : LiveCashTheme.expense,
                        prefix: store.availableBalance >= 0 ? "+" : ""
                    )
                }

                Text("Verfügbares Geld")
                    .font(LiveCashTheme.bodyFont.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Label(LiveCashTheme.money(store.currentMonthExpenses), systemImage: "arrow.down.circle.fill")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.expense)
                        .contentTransition(.numericText())
                    Label(LiveCashTheme.money(store.currentMonthIncome), systemImage: "arrow.up.circle.fill")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.income)
                        .contentTransition(.numericText())
                }
                .animation(LiveCashMotion.snappy, value: store.currentMonthExpenses)
            }
        }
    }

    private var savingsProgressSection: some View {
        Group {
            if let goal = store.activeGoals.first {
                LiveCashCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Sparfortschritt")
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(goal.name)
                                .font(LiveCashTheme.captionFont.weight(.semibold))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(LiveCashTheme.incomeSoft)
                                Capsule()
                                    .fill(LiveCashTheme.accent)
                                    .frame(width: geo.size.width * goal.progress)
                                    .animation(LiveCashMotion.softSpring, value: goal.progress)
                            }
                        }
                        .frame(height: 10)
                        HStack {
                            Text("\(goal.progressPercent)%")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(LiveCashTheme.accent)
                                .contentTransition(.numericText())
                            Spacer()
                            Text(String(format: "%.0f€ / %.0f€", goal.currentAmount, goal.targetAmount))
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if store.transactions.isEmpty && store.goals.isEmpty {
                EmptyView()
            }
        }
        .animation(LiveCashMotion.panelSpring, value: store.activeGoals.first?.id)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.transactions.isEmpty && store.goals.isEmpty {
                LiveCashCard {
                    LiveCashEmptyState(
                        title: "Deine Finanzreise beginnt heute 🚀",
                        message: "Lege dein erstes Sparziel an, erfasse eine Ausgabe — oder frag den Assistenten unten.",
                        systemImage: "airplane.departure",
                        primaryActionTitle: "Erstes Sparziel",
                        primaryAction: {
                            HapticService.medium(store: store)
                            store.pendingTabSelection = 3
                            store.pendingMoreDestination = .goals
                        },
                        secondaryActionTitle: "Finanzbericht",
                        secondaryAction: {
                            HapticService.light(store: store)
                            showFinanceReport = true
                        }
                    )
                }
            } else {
                SectionHeader(title: "Erkenntnisse")
                ForEach(Array(insightTips.enumerated()), id: \.offset) { index, tip in
                    Button {
                        store.showInsight(for: tip.action)
                        HapticService.selection(store: store)
                    } label: {
                        LiveCashCard {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(LiveCashTheme.accent)
                                    .symbolEffect(.pulse, options: .repeating.speed(0.4), value: tip.shortTitle)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tip.shortTitle)
                                        .font(LiveCashTheme.captionFont.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text(tip.message)
                                        .font(LiveCashTheme.bodyFont)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .buttonStyle(SoftPressStyle())
                    .listRowAppear(index: index)
                }

                Button {
                    HapticService.medium(store: store)
                    showFinanceReport = true
                } label: {
                    Label("Mein Finanzbericht", systemImage: "doc.text.magnifyingglass")
                        .font(LiveCashTheme.bodyFont.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LiveCashTheme.accent.opacity(0.12))
                        .foregroundStyle(LiveCashTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PremiumPressStyle())
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Zuletzt")
            if store.transactions.isEmpty {
                LiveCashCard {
                    Text("Tippe unten z. B. „Kaffee 4,50“ — oder frag: „Kann ich mir 40€ leisten?“")
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(store.accountFilteredTransactions.prefix(5).enumerated()), id: \.element.id) { index, tx in
                    NavigationLink {
                        TransactionDetailView(transactionID: tx.id)
                    } label: {
                        TransactionRow(transaction: tx)
                    }
                    .buttonStyle(SoftPressStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticService.navigate(store: store)
                    })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
                    .listRowAppear(index: index)
                }
            }
        }
        .animation(LiveCashMotion.snappy, value: store.accountFilteredTransactions.prefix(5).map(\.id))
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date()).capitalized
    }
}
