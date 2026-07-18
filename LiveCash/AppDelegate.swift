import UIKit

enum LiveCashQuickAction: String, Equatable {
    case addTransaction
    case openAssistant
    case openOverview
    case openGoals

    var type: String { rawValue }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: LiveCashQuickAction.openOverview.type,
                localizedTitle: "Übersicht",
                localizedSubtitle: "Zur Startseite",
                icon: UIApplicationShortcutIcon(systemImageName: "house.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: LiveCashQuickAction.openAssistant.type,
                localizedTitle: "Smart Assistant",
                localizedSubtitle: "Fragen & Tipps",
                icon: UIApplicationShortcutIcon(systemImageName: "sparkles"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: LiveCashQuickAction.addTransaction.type,
                localizedTitle: "Neue Buchung",
                localizedSubtitle: "Ausgabe oder Einnahme",
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"),
                userInfo: nil
            )
        ]

        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            QuickActionRouter.enqueue(LiveCashQuickAction(rawValue: item.type))
        }
        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionRouter.enqueue(LiveCashQuickAction(rawValue: shortcutItem.type))
        completionHandler(true)
    }
}

enum QuickActionRouter {
    static var pending: LiveCashQuickAction?

    static func enqueue(_ action: LiveCashQuickAction?) {
        pending = action
        NotificationCenter.default.post(name: .liveCashQuickAction, object: action)
    }

    static func consume() -> LiveCashQuickAction? {
        let action = pending
        pending = nil
        return action
    }
}
