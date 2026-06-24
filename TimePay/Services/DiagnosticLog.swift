import Foundation

@MainActor
enum DiagnosticLog {
    static func export(store: TimePayStore, gate: ShortcutGateManager) -> String {
        var lines: [String] = []
        let formatter = ISO8601DateFormatter()
        lines.append("NOCO TimePay Diagnose")
        lines.append("Zeit: \(formatter.string(from: Date()))")
        lines.append("Version: \(TimePayEnvironmentDiagnostics.appVersion)")
        lines.append("Modus: Kurzbefehl-Gate (ohne Bildschirmzeit)")
        lines.append("---")
        lines.append("Gate offen: \(ShortcutGateManager.isGateOpen)")
        lines.append("Gate Rest (s): \(TimePaySharedStorage.remainingUnlockSeconds())")
        lines.append("Geschützte Apps aktiv: \(gate.enabledApps.count)")
        lines.append("Kurzbefehl-Setup erledigt: \(gate.setupCompleted)")
        lines.append("App-Gruppe: \(TimePayEnvironmentDiagnostics.appGroupAvailable ? "OK" : "FEHLT")")
        lines.append(TimePayEnvironmentDiagnostics.embeddedPlugInReport)
        lines.append("---")
        lines.append("Guthaben (Min): \(store.balanceMinutes)")
        lines.append("Freigabe UI Rest (s): \(store.unlockSessionRemaining)")
        lines.append("Live Activities: \(LiveActivityManager.isSupported)")
        lines.append("---")
        lines.append("Aktive Apps:")
        for app in gate.enabledApps {
            lines.append("  • \(app.name)")
        }
        lines.append("---")
        lines.append(ShortcutGateManager.shortcutBuildGuide)
        return lines.joined(separator: "\n")
    }
}
