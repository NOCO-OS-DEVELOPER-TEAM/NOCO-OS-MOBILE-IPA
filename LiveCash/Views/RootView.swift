import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        MainTabView()
            .preferredColorScheme(nil)
            .onShake()
            .onAppear(perform: handleQuickAction)
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
                    Text("\(tx.merchant)\n\(sign)\(String(format: "%.2f€", tx.amount)) · \(tx.category.rawValue)\n\(tx.date.formatted(date: .abbreviated, time: .shortened))")
                }
            }
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
        }
    }
}

extension Notification.Name {
    static let liveCashQuickAction = Notification.Name("liveCashQuickAction")
}
