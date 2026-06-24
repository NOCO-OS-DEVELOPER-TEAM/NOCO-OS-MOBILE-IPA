import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            if screenTime.isAuthorized {
                DashboardView()
            } else {
                PermissionView()
            }
        }
        .task {
            await screenTime.bootstrap()
            store.resumeUnlockTimerIfNeeded(onRelock: { screenTime.relock() })
            store.checkPendingUnlockFromShield()
        }
        .sheet(isPresented: $store.showUnlockSheet) {
            UnlockSheetView()
        }
        .sheet(isPresented: $store.showEarnSheet) {
            EarnTimeView()
        }
        .onChange(of: store.pendingUnlockFromShield) { _, pending in
            if pending {
                if store.canBookTime {
                    store.showUnlockSheet = true
                }
                store.pendingUnlockFromShield = false
            }
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
                screenTime.refreshAuthorizationStatus()
                store.checkPendingUnlockFromShield()
            }
        }
    }
}
