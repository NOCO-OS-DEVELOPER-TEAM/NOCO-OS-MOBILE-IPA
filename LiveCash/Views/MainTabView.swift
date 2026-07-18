import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedTab = 0
    @State private var showAddMenu = false
    @State private var showAddTransaction = false
    @State private var showGoalContribution = false
    @State private var showReceiptScan = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(isSelected: selectedTab == 0)
                .tabItem { Label("Start", systemImage: "house.fill") }
                .tag(0)

            TransactionsListView()
                .tabItem { Label("Buchungen", systemImage: "list.bullet.rectangle") }
                .tag(1)

            MoneyMapView()
                .tabItem { Label("Karte", systemImage: "map.fill") }
                .tag(2)

            MoreView(isSelected: selectedTab == 3)
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle.fill") }
                .tag(3)
        }
        .tint(LiveCashTheme.accent)
        .onAppear {
            consumePendingQuickAction(store.pendingQuickAction)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            HapticService.tabChange(store: store)
            if oldTab == 3 && newTab != 3 {
                store.moreNavigationEpoch += 1
            }
            if newTab == 2 {
                store.mapResetEpoch += 1
            }
            if newTab != 0 {
                NotificationCenter.default.post(name: .liveCashCollapseAssistant, object: nil)
            }
        }
        .onChange(of: store.pendingQuickAction) { _, action in
            consumePendingQuickAction(action)
        }
        .onChange(of: store.pendingTabSelection) { _, tab in
            if let tab {
                withAnimation(LiveCashMotion.crossfade) {
                    selectedTab = tab
                }
                store.pendingTabSelection = nil
            }
        }
        .onChange(of: store.showGoalContributionSheet) { _, show in
            if show {
                showGoalContribution = true
            }
        }
        .sheet(isPresented: $showAddMenu) {
            AddActionSheet { action in
                switch action {
                case .transaction:
                    showAddTransaction = true
                case .goalContribution:
                    showGoalContribution = true
                case .receipt:
                    showReceiptScan = true
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .sheet(isPresented: $showGoalContribution) {
            GoalContributionView(
                prefilledAmount: store.pendingGoalContributionAmount,
                initialMode: store.pendingGoalTransferIsWithdraw ? .withdraw : .deposit
            )
            .onDisappear {
                store.pendingGoalContributionAmount = nil
                store.pendingGoalTransferIsWithdraw = false
                store.showGoalContributionSheet = false
            }
        }
        .sheet(isPresented: $showReceiptScan) {
            ReceiptScanView()
        }
        .sheet(isPresented: $store.showAnalyzeMe) {
            AnalyzeMeView()
        }
        .sheet(isPresented: $store.showFinanceReport) {
            FinanceReportView()
        }
    }

    private func consumePendingQuickAction(_ action: LiveCashQuickAction?) {
        guard let action else { return }
        switch action {
        case .addTransaction:
            selectedTab = 0
            // Skip menu — open booking form directly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showAddTransaction = true
            }
        case .openAssistant:
            selectedTab = 0
            store.focusInputOnAppear = true
            store.isAssistantExpanded = true
        case .openOverview:
            selectedTab = 0
            store.isAssistantExpanded = false
            store.activeInsight = nil
        case .openGoals:
            selectedTab = 3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                store.pendingMoreDestination = .goals
            }
        }
        store.pendingQuickAction = nil
    }
}
