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

    /// Kurz-Anleitung — nur noch Automation, kein eigener Kurzbefehl.
    static let setupSteps: [(icon: String, title: String, detail: String)] = [
        ("apps.iphone", "Apps wählen", "Tab „Apps“ → z. B. „Empfohlen“ tippen."),
        ("bolt.fill", "Automation", "App öffnet → eine Aktion: „Gate durchsetzen“ (TimePay)."),
        ("checkmark.seal", "Fertig", "Sofort ausführen AN · Vor Ausführen AUS."),
    ]

    static let automationRecipeSteps: [(icon: String, title: String, detail: String)] = [
        ("plus.circle.fill", "Neue Automation", "Automation → Persönliche Automation → App."),
        ("app.badge.checkmark", "Apps wählen", "Deine geschützten Apps (mehrere möglich)."),
        ("hand.tap.fill", "Ist geöffnet", "Trigger: „Wird geöffnet“."),
        ("lock.shield.fill", "Eine Aktion", "Aktion hinzufügen → TimePay → „Gate durchsetzen“."),
        ("checkmark.seal.fill", "Einstellungen", "„Sofort ausführen“ AN · „Vor Ausführen fragen“ AUS."),
    ]

    static func automationClipboardText(apps: [ProtectedApp]) -> String {
        let names = apps.map(\.name).joined(separator: ", ")
        return """
        NOCO TimePay — Automation (2 Min.)

        Apps: \(names)

        1. Automation → App → \(names) → Wird geöffnet
        2. Aktion: TimePay → „Gate durchsetzen“
        3. Sofort ausführen AN · Vor Ausführen AUS

        Kein eigener Kurzbefehl nötig.
        """
    }

    static let quickSetupSteps = setupSteps

    /// Optional: vorgefertigten Kurzbefehl aus dem Bundle teilen (falls du lieber einen Kurzbefehl importierst).
    static func bundledGateShortcutURL() -> URL? {
        Bundle.main.url(forResource: "NOCOTimePayGate", withExtension: "shortcut")
    }

    static func presentShareGateShortcut(from presenter: UIViewController) {
        guard let url = bundledGateShortcutURL() else { return }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: 80, width: 1, height: 1)
        }
        presenter.present(activity, animated: true)
    }
}

/// Share-Sheet für den optionalen Gate-Kurzbefehl.
struct GateShortcutShareButton: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    static func share(from root: UIViewController?) {
        guard let root else { return }
        ShortcutInstaller.presentShareGateShortcut(from: root)
    }
}
