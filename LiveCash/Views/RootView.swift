import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: FinanceStore
    @ObservedObject private var security = SecurityService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if !store.hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainContent
            }

            if let claim = store.pendingDailyLoginClaim {
                DailyLoginRewardOverlay(result: claim) {
                    store.dismissDailyLoginClaim()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.pendingDailyLoginClaim != nil)
        .onShake()
        .onAppear {
            security.resetLockState(for: store.appSettings.security)
            handleQuickAction()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                security.lockBalanceIfNeeded(settings: store.appSettings.security)
                if store.appSettings.security.faceIDEnabled,
                   store.appSettings.security.faceIDLockMode == .onLaunch {
                    security.lock()
                }
            case .active:
                security.recordActivity()
                if security.shouldLockForInactivity(settings: store.appSettings.security) {
                    security.lock()
                }
            @unknown default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .liveCashQuickAction)) { _ in
            handleQuickAction()
        }
        .onReceive(NotificationCenter.default.publisher(for: .liveCashDeviceDidShake)) { _ in
            store.handleDeviceShake()
        }
        .alert("Letzte Buchung rückgängig machen?", isPresented: shakeUndoPresented) {
            Button("Rückgängig", role: .destructive) { store.confirmShakeUndo() }
            Button("Abbrechen", role: .cancel) { store.cancelShakeUndo() }
        } message: {
            if let undo = store.pendingShakeUndo {
                let tx = undo.transaction
                let sign = tx.type == .income ? "+" : "-"
                Text("\(tx.merchant)\n\(sign)\(String(format: "%.2f€", tx.amount)) · \(store.categoryName(for: tx))\n\(tx.date.formatted(date: .abbreviated, time: .shortened))")
            }
        }
    }

    private var needsLockOverlay: Bool {
        store.appSettings.security.faceIDEnabled
            && store.appSettings.security.faceIDLockMode != .off
            && !security.isUnlocked
    }

    private var shakeUndoPresented: Binding<Bool> {
        Binding(
            get: { store.pendingShakeUndo != nil },
            set: { if !$0 { store.cancelShakeUndo() } }
        )
    }

    private func handleQuickAction() {
        guard let action = QuickActionRouter.pending else { return }
        QuickActionRouter.pending = nil
        switch action {
        case .addTransaction:
            store.pendingQuickAction = .addTransaction
        case .openAssistant:
            store.pendingQuickAction = .openAssistant
            store.focusInputOnAppear = true
        case .openOverview:
            store.pendingQuickAction = .openOverview
        case .openGoals:
            store.pendingQuickAction = .openGoals
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            MainTabView()
                .preferredColorScheme(nil)
                .blur(radius: needsLockOverlay ? 12 : 0)
                .disabled(needsLockOverlay)

            if needsLockOverlay {
                AppLockOverlay()
            }
        }
    }
}

private struct AppLockOverlay: View {
    @ObservedObject private var security = SecurityService.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                Text("Live Cash gesperrt")
                    .font(.headline)
                    .foregroundStyle(.white)
                Button("Entsperren") {
                    Task {
                        await security.authenticate(reason: "Live Cash entsperren")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

extension Notification.Name {
    static let liveCashQuickAction = Notification.Name("liveCashQuickAction")
}
