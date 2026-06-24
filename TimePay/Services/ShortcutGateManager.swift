import Foundation
import SwiftUI

@MainActor
final class ShortcutGateManager: ObservableObject {
    @Published var protectedApps: [ProtectedApp] = []
    @Published var setupCompleted = false
    @Published var lastInterceptedApp: String?
    @Published var searchQuery = ""
    @Published var selectedCategory: AppCategory?

    private let appsKey = TimePayKeys.protectedAppsKey
    private let setupKey = TimePayKeys.shortcutSetupCompletedKey

    init() {
        loadProtectedApps()
        setupCompleted = TimePaySharedStorage.defaults?.bool(forKey: setupKey) ?? false
        syncBlockedCountWidget()
    }

    static var isGateOpen: Bool {
        TimePaySharedStorage.isUnlocked && TimePaySharedStorage.remainingUnlockSeconds() > 0
    }

    var enabledApps: [ProtectedApp] {
        protectedApps.filter(\.isEnabled)
    }

    var filteredApps: [ProtectedApp] {
        protectedApps.filter { app in
            let categoryMatch = selectedCategory == nil || app.category == selectedCategory
            return categoryMatch && app.matches(searchQuery)
        }
    }

    var gateStatusLabel: String {
        if Self.isGateOpen {
            let s = TimePaySharedStorage.remainingUnlockSeconds()
            return "Offen · \(s / 60):\(String(format: "%02d", s % 60))"
        }
        return "Geschlossen"
    }

    func openGate(minutes: Int) {
        Self.openGate(minutes: minutes)
    }

    func closeGate() {
        Self.closeGate()
    }

    static func openGate(minutes: Int) {
        guard minutes > 0 else { return }
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        TimePaySharedStorage.isUnlocked = true
        TimePaySharedStorage.unlockUntilDate = end
    }

    static func closeGate() {
        TimePaySharedStorage.isUnlocked = false
        TimePaySharedStorage.unlockUntilDate = nil
    }

    func markSetupCompleted() {
        setupCompleted = true
        TimePaySharedStorage.defaults?.set(true, forKey: setupKey)
    }

    func resetSetup() {
        setupCompleted = false
        TimePaySharedStorage.defaults?.set(false, forKey: setupKey)
    }

    func toggleApp(_ id: String) {
        guard let index = protectedApps.firstIndex(where: { $0.id == id }) else { return }
        protectedApps[index].isEnabled.toggle()
        persistProtectedApps()
        syncBlockedCountWidget()
    }

    func addCustomApp(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let id = "custom.\(trimmed.lowercased().replacingOccurrences(of: " ", with: "-"))"
        guard !protectedApps.contains(where: { $0.id == id }) else { return }
        let app = ProtectedApp(
            id: id,
            name: trimmed,
            symbol: "app.fill",
            category: .other,
            keywords: [trimmed.lowercased()],
            isEnabled: true,
            isCustom: true
        )
        protectedApps.append(app)
        persistProtectedApps()
        syncBlockedCountWidget()
    }

    func removeCustomApp(_ id: String) {
        guard let index = protectedApps.firstIndex(where: { $0.id == id && $0.isCustom }) else { return }
        protectedApps.remove(at: index)
        persistProtectedApps()
        syncBlockedCountWidget()
    }

    func handleIncomingURL(_ url: URL, store: TimePayStore) {
        guard url.scheme == "timepay" else { return }
        switch url.host {
        case "gate", "unlock":
            let app = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "app" })?
                .value?
                .removingPercentEncoding
            lastInterceptedApp = app
            store.openUnlockFromShortcut(appName: app)
        default:
            break
        }
    }

    func syncBlockedCountWidget() {
        TimePaySharedStorage.defaults?.set(enabledApps.count, forKey: TimePayKeys.widgetBlockedCount)
    }

    private func loadProtectedApps() {
        guard
            let data = TimePaySharedStorage.defaults?.data(forKey: appsKey),
            let decoded = try? JSONDecoder().decode([ProtectedApp].self, from: data),
            !decoded.isEmpty
        else {
            protectedApps = ProtectedApp.catalog
            persistProtectedApps()
            return
        }
        protectedApps = mergeWithCatalog(decoded)
    }

    private func mergeWithCatalog(_ saved: [ProtectedApp]) -> [ProtectedApp] {
        let savedByID = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
        var merged = ProtectedApp.catalog.map { app in
            var copy = app
            if let savedApp = savedByID[app.id] {
                copy.isEnabled = savedApp.isEnabled
            }
            return copy
        }
        let catalogIDs = Set(ProtectedApp.catalog.map(\.id))
        let customs = saved.filter { $0.isCustom && !catalogIDs.contains($0.id) }
        merged.append(contentsOf: customs)
        return merged
    }

    private func persistProtectedApps() {
        guard let data = try? JSONEncoder().encode(protectedApps) else { return }
        TimePaySharedStorage.defaults?.set(data, forKey: appsKey)
    }

    static let shortcutBuildGuide = """
    KURZBEFEHL „NOCO TimePay Gate“ (einmal anlegen)
    ─────────────────────────────────────────────
    1. App „Kurzbefehle“ öffnen → + → Name: NOCO TimePay Gate

    2. Aktion hinzufügen: „TimePay Gate prüfen“
       (unter Apps → NOCO TimePay / TimePay suchen)

    3. Aktion „Wenn“ hinzufügen:
       • Bedingung: Ergebnis von „TimePay Gate prüfen“ ist falsch

    4. UNTER „Wenn“ (dann-Zweig):
       a) „URL öffnen“ → timepay://gate?app=App
          (Optional: Variable „App“ aus Automation nutzen)
       b) „Zum Home-Bildschirm“

    5. „Sonst“-Zweig: leer lassen (App darf öffnen)

    AUTOMATION (pro App oder mehrere zusammen)
    ─────────────────────────────────────────────
    1. Kurzbefehle → Automation → + → App
    2. Apps wählen (z. B. Instagram, TikTok, …)
    3. „Ist geöffnet“ → Weiter
    4. Aktion: „Kurzbefehl ausführen“ → NOCO TimePay Gate
    5. „Sofort ausführen“ AN, „Vor Ausführen fragen“ AUS

    WICHTIG: Kein Fokus-Modus nötig!
    TimePay speichert die Freigabe-Zeit intern.
    Der Kurzbefehl prüft nur: Gate offen? → App bleibt.
    Gate zu? → TimePay öffnen + zurück zum Home-Bildschirm.

    Nach Freischaltung in TimePay ist das Gate zeitlich offen —
    du musst die Automation NICHT manuell ausschalten.
    """

    static let howItWorks = """
    So funktioniert’s:

    1. Du öffnest Instagram (oder eine andere geschützte App).
    2. Die Automation startet den Kurzbefehl „NOCO TimePay Gate“.
    3. TimePay prüft: Läuft gerade eine Freigabe?
       • Ja → nichts passiert, App bleibt offen.
       • Nein → TimePay öffnet sich, du gibst dir Minuten.
    4. Nach der Zeit schließt TimePay das Gate automatisch.
       Beim nächsten App-Öffnen landest du wieder in TimePay.
    """
}
