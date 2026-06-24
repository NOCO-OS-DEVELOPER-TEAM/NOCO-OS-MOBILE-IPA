import SwiftUI

@main
struct TimePayApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = TimePayStore()
    @StateObject private var screenTime = ScreenTimeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if url.host == "unlock" {
                        store.pendingUnlockFromShield = true
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.checkPendingUnlockFromShield()
                        store.resumeUnlockTimerIfNeeded(
                            onRelock: { screenTime.relock() }
                        )
                    }
                }
        }
    }
}
