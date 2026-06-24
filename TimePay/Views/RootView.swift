import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            LiquidGlassBackground()
            MainTabView()
        }
        .task {
            store.resumeUnlockTimerIfNeeded()
            store.resumeEarnSessionIfNeeded()
            store.consumePendingDeepLink()
            store.syncWidgetData()
            store.spendMinutes = Double(settings.defaultUnlockMinutes)
            if !settings.hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OneTapSetupView(isOnboarding: true, onSwitchToAppsTab: nil) {
                settings.hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .sheet(isPresented: $store.showUnlockSheet) {
            UnlockSheetView()
        }
        .sheet(isPresented: $store.showEarnSheet) {
            EarnTimeView()
        }
        .overlay(alignment: .top) {
            if let toast = store.toastMessage {
                GlassToast(message: toast)
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: store.toastMessage)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.resumeUnlockTimerIfNeeded()
                store.resumeEarnSessionIfNeeded()
                store.consumePendingDeepLink()
                store.syncWidgetData()
            }
        }
    }
}
