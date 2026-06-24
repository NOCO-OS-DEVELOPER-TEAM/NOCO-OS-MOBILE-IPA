import UIKit

/// Öffnet Kurzbefehle — Automation nutzt `timepay://gate` (zuverlässig) oder TimePay-Aktion.
enum ShortcutInstaller {
    static let gateURL = GateEngine.gateURL
    static let automationActionTitle = "Apps sperren"

    static func setupClipboardText() -> String {
        """
        TimePay — Apps sperren (3 Schritte)

        1. TimePay → Empfohlene Apps aktivieren
        2. Kurzbefehle → Automation → + → App → Ist geöffnet
        3. Aktion: URL öffnen → \(gateURL)
           Sofort ausführen AN · Vor Ausführen fragen AUS

        Alternativ statt URL: TimePay → Apps sperren
        """
    }

    @discardableResult
    static func openShortcutsApp() -> Bool {
        openURL("shortcuts://")
    }

    static func openAutomations() {
        openURL("shortcuts://automations") ?? openShortcutsApp()
    }

    static func copyGateURL() {
        UIPasteboard.general.string = gateURL
    }

    @discardableResult
    private static func openURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        UIApplication.shared.open(url)
        return true
    }
}
