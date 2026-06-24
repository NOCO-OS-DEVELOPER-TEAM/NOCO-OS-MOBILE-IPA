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

    static var isGateOpen: Bool { GateEngine.isOpen }

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
            let s = GateEngine.remainingSeconds
            return "Offen · \(s / 60):\(String(format: "%02d", s % 60))"
        }
        return "Geschlossen"
    }

    func openGate(minutes: Int) { Self.openGate(seconds: minutes * 60) }
    func openGate(seconds: Int) { Self.openGate(seconds: seconds) }
    func closeGate() { Self.closeGate() }

    static func openGate(minutes: Int) { openGate(seconds: minutes * 60) }

    static func openGate(seconds: Int) {
        GateEngine.grantUnlock(seconds: seconds)
    }

    static func closeGate() {
        GateEngine.closeUnlock()
    }

    func markSetupCompleted() {
        setupCompleted = true
        for d in TimePaySharedStorage.storageTargets() {
            d.set(true, forKey: setupKey)
        }
    }

    func resetSetup() {
        setupCompleted = false
        for d in TimePaySharedStorage.storageTargets() {
            d.set(false, forKey: setupKey)
        }
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

    func applySelectionPreset(_ preset: AppSelectionPreset) {
        let ids = preset.appIDs
        for index in protectedApps.indices {
            if preset == .none {
                protectedApps[index].isEnabled = false
            } else if ids.contains(protectedApps[index].id) {
                protectedApps[index].isEnabled = true
            }
        }
        persistProtectedApps()
        syncBlockedCountWidget()
    }

    func enableCategory(_ category: AppCategory) {
        for index in protectedApps.indices where protectedApps[index].category == category {
            protectedApps[index].isEnabled = true
        }
        persistProtectedApps()
        syncBlockedCountWidget()
    }

    func disableAllApps() {
        for index in protectedApps.indices {
            protectedApps[index].isEnabled = false
        }
        persistProtectedApps()
        syncBlockedCountWidget()
    }

    func handleIncomingURL(_ url: URL, store: TimePayStore) {
        guard url.scheme == "timepay" else { return }
        switch url.host {
        case "gate", "unlock", "block":
            let app = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "app" })?
                .value?
                .removingPercentEncoding
            lastInterceptedApp = app
            GateEngine.handleGateURL(url, store: store)
        case "earn":
            store.tryOpenEarnSheet()
        case "end":
            store.endUnlockSessionEarly()
        default:
            break
        }
    }

    func syncBlockedCountWidget() {
        for d in TimePaySharedStorage.storageTargets() {
            d.set(enabledApps.count, forKey: TimePayKeys.widgetBlockedCount)
        }
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
        for d in TimePaySharedStorage.storageTargets() {
            d.set(data, forKey: appsKey)
        }
    }

    static let shortcutBuildGuide = """
    SPERRE (3 Schritte)
    ─────────────────────────────────────────────
    1. TimePay → Empfohlene Apps aktivieren
    2. Kurzbefehle → Automation → App → Ist geöffnet
    3. Aktion: URL öffnen → timepay://gate
       (Alternativ: TimePay → Apps sperren)
       Sofort ausführen AN · Vor Ausführen fragen AUS
    """

    static let howItWorks = """
    App öffnen ohne Freigabe → TimePay erscheint → Minuten abbuchen.
    Mit Freigabe-Zeit → App bleibt offen.
    """
}
