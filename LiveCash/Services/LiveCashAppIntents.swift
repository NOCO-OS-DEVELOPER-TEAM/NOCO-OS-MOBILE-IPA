import AppIntents
import Foundation

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Neue Ausgabe"
    static var description = IntentDescription("Öffnet Live Cash zum Erfassen einer Ausgabe.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.pending = .addTransaction
        NotificationCenter.default.post(name: .liveCashQuickAction, object: nil)
        return .result()
    }
}

struct OpenGoalsIntent: AppIntent {
    static var title: LocalizedStringResource = "Sparziel öffnen"
    static var description = IntentDescription("Öffnet deine Sparziele in Live Cash.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.pending = .openGoals
        NotificationCenter.default.post(name: .liveCashQuickAction, object: nil)
        return .result()
    }
}

struct LiveCashShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Neue Ausgabe in \(.applicationName)",
                "\(.applicationName) Ausgabe erfassen"
            ],
            shortTitle: "Neue Ausgabe",
            systemImageName: "minus.circle.fill"
        )
        AppShortcut(
            intent: OpenGoalsIntent(),
            phrases: [
                "Sparziel in \(.applicationName) öffnen",
                "\(.applicationName) Sparziel"
            ],
            shortTitle: "Sparziel",
            systemImageName: "target"
        )
    }
}
