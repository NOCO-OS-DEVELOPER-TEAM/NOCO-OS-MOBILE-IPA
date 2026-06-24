import SwiftUI

@main
struct TimePayApp: App {
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
        }
    }
}
