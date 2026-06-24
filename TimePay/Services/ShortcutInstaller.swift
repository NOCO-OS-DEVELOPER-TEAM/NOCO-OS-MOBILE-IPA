import SwiftUI
import UIKit

enum ShortcutInstaller {
    /// Raw shortcut on GitHub — updates when pushed to main.
    static let hostedShortcutURL = URL(
        string: "https://raw.githubusercontent.com/noco-os-developer-team/NOCO-OS-MOBILE-IPA/main/TimePay/Resources/NOCOTimePayGate.shortcut"
    )

    static func importGateShortcut() {
        if let hosted = hostedShortcutURL,
           let encoded = hosted.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "shortcuts://import-shortcut?url=\(encoded)") {
            UIApplication.shared.open(url)
            return
        }
        openShortcutsApp()
    }

    static func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }

    static func bundledShortcutURL() -> URL? {
        Bundle.main.url(forResource: "NOCOTimePayGate", withExtension: "shortcut")
    }

    static func automationClipboardText(apps: [ProtectedApp]) -> String {
        let names = apps.map(\.name).joined(separator: ", ")
        return """
        TimePay Automation — Apps für Kurzbefehle:
        \(names)

        Kurzbefehle → Automation → + → App → diese Apps wählen → „NOCO TimePay Gate“ ausführen → Sofort ausführen AN
        """
    }

    static let quickSetupSteps: [(icon: String, title: String, detail: String)] = [
        ("1.circle.fill", "Kurzbefehl hinzufügen", "Ein Tippen → in Kurzbefehle „Hinzufügen“ bestätigen."),
        ("2.circle.fill", "Automation verknüpfen", "Apps aus deiner Liste wählen → Gate-Kurzbefehl starten."),
        ("3.circle.fill", "Fertig", "TimePay steuert Freigabe-Zeit — kein Fokus-Modus."),
    ]
}
