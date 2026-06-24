import SwiftUI

@main
struct TimePayApp: App {
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
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.resumeUnlockTimerIfNeeded()
                    }
                }
        }
    }
}
