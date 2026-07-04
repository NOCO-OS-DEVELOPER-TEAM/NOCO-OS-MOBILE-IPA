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
                    handlePendingQuickAction()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.onAppBecameActive()
                        handlePendingQuickAction()
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "livecash" else { return }
        switch url.host {
        case "dashboard", "home":
            store.pendingTabSelection = 0
        case "widget", "balance":
            store.pendingTabSelection = 0
            store.showInsight(for: .monthlySummary)
        case "map":
            store.pendingTabSelection = 2
        case "assistant":
            store.pendingTabSelection = 0
            store.focusInputOnAppear = true
        default:
            store.pendingTabSelection = 0
        }
        WidgetDataSync.writeSnapshot(from: store)
    }

    private func handlePendingQuickAction() {
        if let action = QuickActionRouter.pending {
            store.pendingQuickAction = action
            QuickActionRouter.pending = nil
        }
    }
}
