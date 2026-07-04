import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        MainTabView()
            .preferredColorScheme(nil)
            .onAppear(perform: handleQuickAction)
            .onReceive(NotificationCenter.default.publisher(for: .liveCashQuickAction)) { _ in
                handleQuickAction()
            }
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
