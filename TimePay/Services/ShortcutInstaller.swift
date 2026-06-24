import SwiftUI
import UIKit

enum ShortcutInstaller {
    static func openShortcutsApp() {
        UIApplication.shared.open(URL(string: "shortcuts://")!)
    }

    static func openTimePayInShortcuts() {
        let url = URL(string: "shortcuts://menu/app-shortcuts")!
        UIApplication.shared.open(url)
    }

    static func openAutomations() {
        if let url = URL(string: "shortcuts://automations") {
            UIApplication.shared.open(url)
        } else {
            openShortcutsApp()
        }
    }

    /// 3 Schritte — Kurzbefehl + Automation zusammengefasst.
    static let setupSteps: [(icon: String, title: String, detail: String)] = [
        ("apps.iphone", "Apps wählen", "Im Tab „Apps“ Schnellauswahl tippen (z. B. Empfohlen)."),
        ("plus.circle.fill", "Gate-Aktion", "Kurzbefehle → TimePay → „TimePay Gate prüfen“ hinzufügen."),
        ("bolt.fill", "Automation", "Automation → App → deine Apps → Gate-Kurzbefehl ausführen."),
    ]

    static let shortcutRecipeSteps: [(icon: String, title: String, detail: String)] = [
        ("1.circle.fill", "Neuer Kurzbefehl", "Name: NOCO TimePay Gate"),
        ("2.circle.fill", "Gate prüfen", "Aktion: TimePay Gate prüfen (unter Apps → TimePay)."),
        ("3.circle.fill", "Wenn → falsch", "Wenn Ergebnis falsch → URL timepay://gate → Zum Home-Bildschirm."),
        ("4.circle.fill", "Sonst leer", "Sonst-Zweig leer — Gate offen = App bleibt."),
    ]

    static let automationRecipeSteps: [(icon: String, title: String, detail: String)] = [
        ("plus.circle", "Automation → App", "Deine geschützten Apps auswählen."),
        ("app.badge.checkmark", "Ist geöffnet", "Trigger: App wird geöffnet."),
        ("play.fill", "Kurzbefehl", "„NOCO TimePay Gate“ ausführen."),
        ("checkmark.seal", "Einstellungen", "Sofort ausführen AN · Vor Ausführen AUS."),
    ]

    static func automationClipboardText(apps: [ProtectedApp]) -> String {
        let names = apps.map(\.name).joined(separator: ", ")
        return """
        NOCO TimePay — 3 Schritte
        Apps: \(names)

        1. Kurzbefehl „NOCO TimePay Gate“ (siehe App-Setup)
        2. Automation → App → \(names)
        3. Kurzbefehl ausführen · Sofort AN
        """
    }

    static let quickSetupSteps = setupSteps
}
