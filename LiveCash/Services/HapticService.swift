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

    /// Soft tick for scrubbing / continuous gestures.
    @MainActor
    static func soft(store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.55)
    }

    @MainActor
    static func rigid(store: FinanceStore) {
        impact(.rigid, store: store)
    }

    @MainActor
    static func heavy(store: FinanceStore) {
        impact(.heavy, store: store)
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

    @MainActor
    static func warning(store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    @MainActor
    static func error(store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Double-tap feel for important confirms (save, goal reached).
    @MainActor
    static func celebrate(store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            guard store.appSettings.ui.hapticsEnabled else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// Tab / segment switch — slightly stronger than plain selection.
    @MainActor
    static func tabChange(store: FinanceStore) {
        guard store.appSettings.ui.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
    }

    /// Navigation row / list open.
    @MainActor
    static func navigate(store: FinanceStore) {
        light(store: store)
    }
}
