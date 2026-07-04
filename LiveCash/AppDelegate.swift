import UIKit

enum LiveCashQuickAction: String, Equatable {
    case addTransaction
    case openAssistant
    case openOverview

    var type: String { rawValue }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: LiveCashQuickAction.addTransaction.type,
                localizedTitle: "Neue Buchung",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: LiveCashQuickAction.openAssistant.type,
                localizedTitle: "Smart Assistant",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "sparkles"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: LiveCashQuickAction.openOverview.type,
                localizedTitle: "Übersicht",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "chart.bar.fill"),
                userInfo: nil
            )
        ]

        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            QuickActionRouter.pending = LiveCashQuickAction(rawValue: item.type)
        }
        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionRouter.pending = LiveCashQuickAction(rawValue: shortcutItem.type)
        completionHandler(true)
    }
}

enum QuickActionRouter {
    static var pending: LiveCashQuickAction?
}
