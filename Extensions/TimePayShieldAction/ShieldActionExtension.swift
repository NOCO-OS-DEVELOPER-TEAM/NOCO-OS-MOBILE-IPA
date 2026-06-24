import ManagedSettings
import ManagedSettingsUI
import UIKit

final class TimePayShieldActionHandler: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, completionHandler: completionHandler)
    }

    private func handle(action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            TimePaySharedStorage.defaults?.set(true, forKey: TimePayKeys.pendingUnlock)
            openHostApp()
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    private func openHostApp() {
        guard let url = URL(string: "timepay://unlock") else { return }
        let openSelector = NSSelectorFromString("openURL:")
        guard
            let applicationClass = NSClassFromString("UIApplication") as? NSObject.Type,
            let application = applicationClass
                .perform(NSSelectorFromString("sharedApplication"))?
                .takeUnretainedValue() as? NSObject
        else { return }
        _ = application.perform(openSelector, with: url)
    }
}
