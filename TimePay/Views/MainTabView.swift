import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LiquidGlassTabBar(selection: $selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, TabBarMetrics.bottomPadding)
        }
        .onChange(of: selectedTab) { old, new in
            if old != new {
                settings.selection()
            }
        }
        .onChange(of: store.openSetupTab) { _, open in
            if open {
                selectedTab = .setup
                store.openSetupTab = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .timePayQuickAction)) { note in
            if note.object as? String == TimePayQuickAction.setup {
                selectedTab = .setup
            }
        }
        .onAppear {
            store.syncWidgetData()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeTabView()
        case .apps:
            GateTabView()
        case .setup:
            OneTapSetupView(embeddedInTab: true, onSwitchToAppsTab: {
                selectedTab = .apps
            })
        case .settings:
            SettingsView()
        }
    }
}
