import SwiftUI
import UIKit

enum ShortcutInstaller {
    /// Einziger Kurzbefehl für die Automation — prüft Zeit, öffnet TimePay nur ohne Freigabe.
    static let gateShortcutName = "TimePay — Apps sperren"
    /// App-Intent-Titel in Kurzbefehle (gleicher Name wie im importierten Kurzbefehl).
    static let automationActionTitle = "Apps sperren"
    static let gateDeepLink = "timepay://gate"
    static let hostedShortcutURL =
        "https://raw.githubusercontent.com/NOCO-OS-DEVELOPER-TEAM/NOCO-OS-MOBILE-IPA/main/TimePay/Resources/NOCOTimePayGate.shortcut"

    static let howItWorksShort = """
    Ohne Freigabe-Zeit: TimePay öffnet sich — du gibst dir Minuten oder gehst zurück.
    Mit Freigabe (z. B. 1 Min): nichts passiert — Instagram, App Store & Co. bleiben offen.
    """

    static let setupSteps: [(icon: String, title: String, detail: String)] = [
        ("apps.iphone", "Apps wählen", "Welche Apps sollen geschützt werden?"),
        ("lock.shield.fill", "Sperre einrichten", "Kurzbefehl importieren oder TimePay-Aktion direkt nutzen."),
        ("bolt.fill", "Automation", "Wenn App geöffnet → Sperre ausführen · Sofort AN"),
    ]

    static let automationRecipeSteps: [(icon: String, title: String, detail: String)] = [
        ("plus.circle.fill", "Neue Automation", "Automation → Persönliche Automation → App."),
        ("app.badge.checkmark", "Apps wählen", "Z. B. App Store, Instagram — deine geschützten Apps."),
        ("hand.tap.fill", "Wird geöffnet", "Trigger: „Wird geöffnet“ (nicht geschlossen)."),
        ("lock.shield.fill", "Sperre ausführen", "Aktion: „Apps sperren“ (TimePay) — oder Kurzbefehl „\(gateShortcutName)“."),
        ("checkmark.seal.fill", "Wichtig", "„Sofort ausführen“ AN · „Vor Ausführen fragen“ AUS."),
    ]

    static let directAutomationSteps: [(icon: String, title: String, detail: String)] = [
        ("1.circle.fill", "Automation öffnen", "Persönliche Automation → App."),
        ("2.circle.fill", "Apps & Trigger", "App Store (Test) → „Wird geöffnet“."),
        ("3.circle.fill", "Aktion hinzufügen", "Suche: TimePay → tippe „Apps sperren“."),
        ("4.circle.fill", "Fertig", "Sofort ausführen AN. Kein Kurzbefehl-Import nötig."),
    ]

    static func automationClipboardText(apps: [ProtectedApp]) -> String {
        let names = apps.map(\.name).joined(separator: ", ")
        return """
        TimePay — Automation einrichten

        \(howItWorksShort)

        1. Automation → App → \(names) → Wird geöffnet
        2. Aktion: TimePay → „Apps sperren“
           (Alternativ: Kurzbefehl „\(gateShortcutName)“ ausführen)
        3. Sofort ausführen AN · Vor Ausführen AUS
        """
    }

    static let quickSetupSteps = setupSteps

    @discardableResult
    static func openShortcutsApp() -> Bool {
        openURL("shortcuts://")
    }

    static func openTimePayInShortcuts() {
        openURL("shortcuts://menu/app-shortcuts")
    }

    static func openAutomations() {
        openURL("shortcuts://automations") ?? openShortcutsApp()
    }

    /// Bevorzugt: zur Laufzeit erzeugte Datei mit korrekter Bundle-ID (Sideload).
    static func gateShortcutFileURL() -> URL? {
        writeRuntimeGateShortcut() ?? bundledGateShortcutURL()
    }

    static func bundledGateShortcutURL() -> URL? {
        Bundle.main.url(forResource: "NOCOTimePayGate", withExtension: "shortcut")
    }

    /// Import: zuerst Teilen-Dialog (zuverlässig), dann iCloud-Link.
    @MainActor
    static func importPrebuiltGateShortcut(completion: ((Bool) -> Void)? = nil) {
        guard writeRuntimeGateShortcut() != nil || bundledGateShortcutURL() != nil else {
            completion?(false)
            return
        }

        if let root = topViewController() {
            presentShareGateShortcut(from: root)
            completion?(true)
            return
        }

        if let importURL = makeImportShortcutURL(remote: hostedShortcutURL) {
            UIApplication.shared.open(importURL) { opened in
                completion?(opened)
            }
            return
        }
        completion?(false)
    }

    /// Teilen-Dialog mit Kurzbefehl-Datei.
    @MainActor
    static func importViaShareSheet(completion: ((Bool) -> Void)? = nil) {
        guard let root = topViewController() else {
            completion?(false)
            return
        }
        guard gateShortcutFileURL() != nil else {
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

    // MARK: - Runtime shortcut (App Intent — nur ohne Freigabe TimePay öffnen)

    private static var teamIdentifier: String? {
        guard let prefix = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String else { return nil }
        let trimmed = prefix.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func appIntentDescriptor() -> [String: Any] {
        var descriptor: [String: Any] = [
            "AppIntentIdentifier": "EnforceTimePayGateIntent",
            "BundleIdentifier": Bundle.main.bundleIdentifier ?? "de.noco.timepay",
            "Name": automationActionTitle,
        ]
        if let team = teamIdentifier {
            descriptor["TeamIdentifier"] = team
        }
        return descriptor
    }

    @discardableResult
    static func writeRuntimeGateShortcut() -> URL? {
        let action: [String: Any] = [
            "WFWorkflowActionIdentifier": "is.workflow.actions.appintentexecution",
            "WFWorkflowActionParameters": [
                "AppIntentDescriptor": appIntentDescriptor(),
                "ShowWhenRun": false,
            ],
        ]

        let plist: [String: Any] = [
            "WFWorkflowActions": [action],
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
            .appendingPathComponent("TimePayAppsSperren.shortcut")
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
