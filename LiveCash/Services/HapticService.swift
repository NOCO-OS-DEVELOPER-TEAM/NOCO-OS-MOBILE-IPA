import UIKit

enum HapticService {
    @MainActor
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    @MainActor
    static func selection(store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @MainActor
    static func progressStep(store: FinanceStore, percent: Int) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        if percent == 50 || percent == 75 || percent == 100 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if percent % 10 == 0 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    @MainActor
    static func light(store: FinanceStore) {
        impact(.light, store: store)
    }

    @MainActor
    static func medium(store: FinanceStore) {
        impact(.medium, store: store)
    }

    @MainActor
    static func success(store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
