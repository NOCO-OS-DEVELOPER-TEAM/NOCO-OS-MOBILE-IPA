import SwiftUI

@main
struct LiveCashApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = FinanceStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onAppear {
                    Task { await NotificationService.shared.requestAuthorizationIfNeeded() }
                    deliverPendingQuickAction()
                    WidgetDataSync.writeSnapshot(from: store)
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.onAppBecameActive()
                        deliverPendingQuickAction()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .liveCashQuickAction)) { _ in
                    deliverPendingQuickAction()
                }
        }
    }

    private func deliverPendingQuickAction() {
        guard let action = QuickActionRouter.consume() else { return }
        store.pendingQuickAction = action
        switch action {
        case .openAssistant:
            store.focusInputOnAppear = true
            store.pendingTabSelection = 0
        case .openOverview:
            store.pendingTabSelection = 0
        case .addTransaction:
            store.pendingTabSelection = 0
        case .openGoals:
            store.pendingTabSelection = 3
            store.pendingMoreDestination = .goals
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "livecash" else { return }
        switch url.host {
        case "dashboard", "home", "overview":
            store.pendingTabSelection = 0
            store.pendingQuickAction = .openOverview
        case "widget", "balance":
            store.pendingTabSelection = 0
            store.pendingQuickAction = .openOverview
        case "map":
            store.pendingTabSelection = 2
        case "assistant":
            store.pendingTabSelection = 0
            store.pendingQuickAction = .openAssistant
            store.focusInputOnAppear = true
        case "add", "booking":
            store.pendingTabSelection = 0
            store.pendingQuickAction = .addTransaction
        case "goals":
            store.pendingTabSelection = 3
            store.pendingMoreDestination = .goals
        default:
            store.pendingTabSelection = 0
        }
        WidgetDataSync.writeSnapshot(from: store)
    }
}
