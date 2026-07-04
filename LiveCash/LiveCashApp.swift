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
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.onAppBecameActive()
                    }
                }
        }
    }
}
