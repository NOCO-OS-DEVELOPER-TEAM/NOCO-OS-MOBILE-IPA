import SwiftUI

@main
struct TimePayApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = TimePayStore()
    @StateObject private var screenTime = ScreenTimeManager()

    init() {
        NotificationManager.shared.installDelegate()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(screenTime)
                .preferredColorScheme(.dark)
                .onAppear {
                    NotificationManager.shared.onShieldUnlockRequested = {
                        store.openUnlockFromShield()
                    }
                }
                .onOpenURL { url in
                    if url.host == "unlock" {
                        store.openUnlockFromShield()
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
