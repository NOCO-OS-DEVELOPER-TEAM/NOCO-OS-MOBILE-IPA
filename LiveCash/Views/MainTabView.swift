import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedTab = 0
    @State private var showAddTransaction = false

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
                selectedTab = 1
                showAddTransaction = true
            case .openAssistant:
                selectedTab = 0
            case .openOverview:
                selectedTab = 0
                store.showInsight(for: .monthlySummary)
            }
            store.pendingQuickAction = nil
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }
}
