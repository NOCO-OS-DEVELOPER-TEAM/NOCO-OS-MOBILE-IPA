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
            DashboardView()
                .tabItem { Label("Start", systemImage: "house.fill") }
                .tag(0)

            TransactionsListView()
                .tabItem { Label("Buchungen", systemImage: "list.bullet.rectangle") }
                .tag(1)

            MoneyMapView()
                .tabItem { Label("Karte", systemImage: "map.fill") }
                .tag(2)

            MoreView()
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle.fill") }
                .tag(3)
        }
        .tint(LiveCashTheme.accent)
        .onChange(of: store.pendingQuickAction) { _, action in
            guard let action else { return }
            switch action {
            case .addTransaction:
                selectedTab = 0
                showAddMenu = true
            case .openAssistant:
                selectedTab = 0
                store.focusInputOnAppear = true
            case .openOverview:
                selectedTab = 0
                store.showInsight(for: .monthlySummary)
            case .openGoals:
                selectedTab = 3
                store.pendingMoreDestination = .goals
            }
            store.pendingQuickAction = nil
        }
        .onChange(of: store.pendingTabSelection) { _, tab in
            if let tab {
                selectedTab = tab
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
            GoalContributionView(prefilledAmount: store.pendingGoalContributionAmount)
                .onDisappear {
                    store.pendingGoalContributionAmount = nil
                    store.showGoalContributionSheet = false
                }
        }
        .sheet(isPresented: $showReceiptScan) {
            ReceiptScanView()
        }
    }
}
