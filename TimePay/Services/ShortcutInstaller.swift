import SwiftUI
import UIKit

enum ShortcutInstaller {
    static let gateShortcutName = "NOCO TimePay Gate"
    static let gateDeepLink = "timepay://gate"
    static let hostedShortcutURL =
        "https://raw.githubusercontent.com/NOCO-OS-DEVELOPER-TEAM/NOCO-OS-MOBILE-IPA/main/TimePay/Resources/NOCOTimePayGate.shortcut"

    static func openShortcutsApp() {
        openURL("shortcuts://")
    }

    static func openTimePayInShortcuts() {
        openURL("shortcuts://menu/app-shortcuts")
    }

    static func openAutomations() {
        openURL("shortcuts://automations") ?? openShortcutsApp()
    }

    static let setupSteps: [(icon: String, title: String, detail: String)] = [
        ("apps.iphone", "Apps wählen", "Empfohlen tippen oder im Apps-Tab auswählen."),
        ("arrow.down.circle.fill", "Kurzbefehl", "Ein Tippen → „Hinzufügen“ in Kurzbefehle."),
        ("bolt.fill", "Automation", "App öffnet → Kurzbefehl „NOCO TimePay Gate“ ausführen."),
    ]

    static let automationRecipeSteps: [(icon: String, title: String, detail: String)] = [
        ("plus.circle.fill", "Neue Automation", "Automation → Persönliche Automation → App."),
        ("app.badge.checkmark", "Apps wählen", "Deine geschützten Apps (mehrere möglich)."),
        ("hand.tap.fill", "Ist geöffnet", "Trigger: „Wird geöffnet“."),
        ("play.fill", "Kurzbefehl starten", "Aktion: Kurzbefehl ausführen → „NOCO TimePay Gate“."),
        ("checkmark.seal.fill", "Einstellungen", "„Sofort ausführen“ AN · „Vor Ausführen fragen“ AUS."),
    ]

    static func automationClipboardText(apps: [ProtectedApp]) -> String {
        let names = apps.map(\.name).joined(separator: ", ")
        return """
        NOCO TimePay — Setup

        1. Kurzbefehl „NOCO TimePay Gate“ in der App hinzufügen
        2. Automation → App → \(names) → Wird geöffnet
        3. Kurzbefehl ausführen: NOCO TimePay Gate
        4. Sofort ausführen AN
        """
    }

    static let quickSetupSteps = setupSteps

    /// Bevorzugt: vorgefertigte Datei aus dem Bundle (funktioniert auch bei Sideload).
    static func gateShortcutFileURL() -> URL? {
        writeRuntimeGateShortcut() ?? bundledGateShortcutURL()
    }

    static func bundledGateShortcutURL() -> URL? {
        Bundle.main.url(forResource: "NOCOTimePayGate", withExtension: "shortcut")
    }

    /// Ein Tippen → Kurzbefehle-Import wie bei iCloud-Links (`shortcuts://import-shortcut?url=…&name=…`).
    @MainActor
    static func importPrebuiltGateShortcut(completion: ((Bool) -> Void)? = nil) {
        if let importURL = makeImportShortcutURL(remote: hostedShortcutURL) {
            UIApplication.shared.open(importURL) { opened in
                if opened {
                    completion?(true)
                } else {
                    importViaShareSheet(completion: completion)
                }
            }
            return
        }
        importViaShareSheet(completion: completion)
    }

    /// Teilen-Dialog mit Kurzbefehl-Datei (Fallback wie bei vielen Shortcut-Apps).
    @MainActor
    static func importViaShareSheet(completion: ((Bool) -> Void)? = nil) {
        guard let root = topViewController() else {
            completion?(false)
            return
        }
        presentShareGateShortcut(from: root)
        completion?(true)
    }

    static func presentShareGateShortcut(from presenter: UIViewController) {
        guard let url = gateShortcutFileURL() else { return }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        }
        presenter.present(activity, animated: true)
    }

    // MARK: - Runtime shortcut (Open URL — kein Bundle-ID-Problem bei Sideload)

    @discardableResult
    static func writeRuntimeGateShortcut() -> URL? {
        let plist: [String: Any] = [
            "WFWorkflowActions": [
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.openurl",
                    "WFWorkflowActionParameters": [
                        "WFURL": gateDeepLink,
                        "Show-WFInput": false,
                    ],
                ],
            ],
            "WFWorkflowClientRelease": "3.0",
            "WFWorkflowClientVersion": "900",
            "WFWorkflowIcon": [
                "WFWorkflowIconGlyphNumber": 59511,
                "WFWorkflowIconStartColor": 431817727,
            ],
            "WFWorkflowImportQuestions": [] as [Any],
            "WFWorkflowMinimumClientVersion": 900,
            "WFWorkflowName": gateShortcutName,
            "WFWorkflowTypes": ["NCWidget", "WatchKit"],
        ]

        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        ) else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NOCOTimePayGate.shortcut")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static func makeImportShortcutURL(remote: String) -> URL? {
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "import-shortcut"
        components.queryItems = [
            URLQueryItem(name: "url", value: remote),
            URLQueryItem(name: "name", value: gateShortcutName),
        ]
        return components.url
    }

    @discardableResult
    private static func openURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        UIApplication.shared.open(url)
        return true
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow }
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}

struct GateShortcutShareLink: View {
    var body: some View {
        if let url = ShortcutInstaller.gateShortcutFileURL() {
            ShareLink(
                item: url,
                preview: SharePreview(ShortcutInstaller.gateShortcutName, image: Image(systemName: "lock.shield.fill"))
            ) {
                Label("Kurzbefehl-Datei teilen", systemImage: "square.and.arrow.up")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(NOCOSecondaryButtonStyle())
        }
    }
}
