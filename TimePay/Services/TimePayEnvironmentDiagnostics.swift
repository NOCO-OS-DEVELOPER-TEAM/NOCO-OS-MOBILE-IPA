import Foundation

enum TimePayEnvironmentDiagnostics {
    private static let requiredPlugIns = [
        "TimePayShieldConfiguration.appex",
        "TimePayShieldAction.appex",
        "TimePayMonitor.appex",
        "TimePayWidgets.appex"
    ]

    static var appGroupAvailable: Bool {
        guard let defaults = UserDefaults(suiteName: TimePayKeys.appGroup) else { return false }
        let probeKey = "__timepay_app_group_probe__"
        defaults.set("ok", forKey: probeKey)
        let ok = defaults.string(forKey: probeKey) == "ok"
        defaults.removeObject(forKey: probeKey)
        return ok
    }

    static var embeddedPlugInReport: String {
        guard let pluginsURL = Bundle.main.builtInPlugInsURL else {
            return "PlugIns-Ordner: fehlt im App-Bundle"
        }
        let names = (try? FileManager.default.contentsOfDirectory(atPath: pluginsURL.path)) ?? []
        if names.isEmpty {
            return "PlugIns-Ordner: leer (Erweiterungen fehlen)"
        }
        var lines = ["PlugIns im Bundle: \(names.sorted().joined(separator: ", "))"]
        for required in requiredPlugIns {
            let present = names.contains(required)
            lines.append("  \(required): \(present ? "OK" : "FEHLT")")
        }
        return lines.joined(separator: "\n")
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unbekannt"
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    static let screenTimeSetupGuide = """
    Bildschirmzeit braucht korrektes Signieren — nicht nur Code in der App.

    WICHTIG: Kostenlose Apple-ID (Personal Team) reicht NICHT.
    Du brauchst ein bezahltes Apple Developer Program (99 €/Jahr),
    damit „Family Controls (Development)“ im Profil enthalten ist.

    Schritt 1 — developer.apple.com (mit bezahltem Account):
    • App-IDs anlegen (exakt diese Bundle-IDs):
      - de.noco.timepay
      - de.noco.timepay.shieldconfig
      - de.noco.timepay.shieldaction
      - de.noco.timepay.monitor
      - de.noco.timepay.widgets
    • App-Gruppe: group.de.noco.timepay (allen 5 IDs zuweisen)
    • Family Controls (Development) aktivieren für:
      Haupt-App + shieldconfig + shieldaction + monitor
      (Widgets brauchen nur App-Gruppe, kein Family Controls)

    Schritt 2 — IPA signieren:
    SideStore nutzt DEIN Entwickler-Zertifikat. Der Ordner
    sidestore-entitlements/ in der IPA ist nur eine Vorlage —
    SideStore wendet ihn NICHT automatisch an.

    Option A (empfohlen): Auf dem Mac mit Xcode bauen,
    automatisches Signieren mit deinem Team, dann IPA exportieren.

    Option B: IPA mit ESign oder Feather auf dem iPhone vor-signieren,
    Entitlements aus sidestore-entitlements/ pro Binary setzen,
    danach in SideStore installieren.

    Schritt 3 — Auf dem iPhone:
    • TimePay komplett löschen, neu installieren
    • Einstellungen → Bildschirmzeit → Apps mit Bildschirmzeit-Zugriff
      → TimePay erlauben
    • TimePay öffnen → „Bildschirmzeit erlauben“

    Die Meldung „Kommunikation mit der Hilfs-App“ bedeutet fast immer:
    Mindestens eine Erweiterung (.appex) wurde OHNE Family Controls signiert.
  """
}
