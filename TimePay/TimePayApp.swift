import SwiftUI

@main
struct TimePayApp: App {
    @UIApplicationDelegateAdaptor(TimePayAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = TimePayStore()
    @StateObject private var gate = ShortcutGateManager()
    @StateObject private var settings = AppSettings()

    init() {
        NotificationManager.shared.installDelegate()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(gate)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    gate.handleIncomingURL(url, store: store)
                }
                .onAppear {
                    TimePayQuickAction.register()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        GateEngine.syncExpiredUnlock()
                        store.resumeUnlockTimerIfNeeded()
                        store.checkPendingEndUnlock()
                        store.consumePendingDeepLink()
                    }
                }
        }
    }
}
