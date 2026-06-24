import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager

    var body: some View {
        ZStack {
            LiquidGlassBackground()
            DashboardView()
        }
        .task { await screenTime.bootstrap() }
        .sheet(isPresented: $store.showUnlockSheet) {
            UnlockSheetView()
        }
        .sheet(isPresented: $store.showEarnSheet) {
            EarnTimeView()
        }
        .onChange(of: store.pendingUnlockFromShield) { _, pending in
            if pending {
                store.showUnlockSheet = true
                store.pendingUnlockFromShield = false
            }
        }
        .overlay(alignment: .top) {
            if let toast = store.toastMessage {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: store.toastMessage)
    }
}
