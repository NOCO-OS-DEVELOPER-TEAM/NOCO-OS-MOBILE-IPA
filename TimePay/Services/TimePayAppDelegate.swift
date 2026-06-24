import UIKit

/// Home-Screen Quick Actions (Icon lang gedrückt) — funktioniert auch bei Sideload, unabhängig von App Intents.
enum TimePayQuickAction {
    static let unlock = "de.noco.timepay.quick.unlock"
    static let earn = "de.noco.timepay.quick.earn"
    static let end = "de.noco.timepay.quick.end"
    static let setup = "de.noco.timepay.quick.setup"

    static func register() {
        let items: [UIApplicationShortcutItem] = [
            UIApplicationShortcutItem(
                type: unlock,
                localizedTitle: "Zeit abbuchen",
                localizedSubtitle: "Apps freischalten",
                icon: UIApplicationShortcutIcon(systemImageName: "lock.open.fill")
            ),
            UIApplicationShortcutItem(
                type: earn,
                localizedTitle: "Session starten",
                localizedSubtitle: "Zeit verdienen",
                icon: UIApplicationShortcutIcon(systemImageName: "play.circle.fill")
            ),
            UIApplicationShortcutItem(
                type: end,
                localizedTitle: "Freigabe beenden",
                localizedSubtitle: "Restzeit erstatten",
                icon: UIApplicationShortcutIcon(systemImageName: "stop.circle.fill")
            ),
            UIApplicationShortcutItem(
                type: setup,
                localizedTitle: "Setup",
                localizedSubtitle: "Automation anlegen",
                icon: UIApplicationShortcutIcon(systemImageName: "wand.and.stars")
            ),
        ]
        UIApplication.shared.shortcutItems = items
    }

    @MainActor
    static func handle(_ item: UIApplicationShortcutItem) {
        switch item.type {
        case unlock:
            TimePaySharedStorage.queuePendingDeepLink("unlock")
        case earn:
            TimePaySharedStorage.queuePendingDeepLink("earn")
        case end:
            TimePaySharedStorage.queuePendingDeepLink("end")
        case setup:
            TimePaySharedStorage.queuePendingDeepLink("setup")
        default:
            break
        }
        NotificationCenter.default.post(name: .timePayQuickAction, object: item.type)
    }
}

extension Notification.Name {
    static let timePayQuickAction = Notification.Name("timePayQuickAction")
}

final class TimePayAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        TimePayQuickAction.register()
        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            Task { @MainActor in
                TimePayQuickAction.handle(shortcut)
            }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in
            TimePayQuickAction.handle(shortcutItem)
            completionHandler(true)
        }
    }
}
