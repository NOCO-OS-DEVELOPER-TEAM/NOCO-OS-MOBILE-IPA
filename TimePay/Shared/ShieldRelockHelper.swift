import Foundation

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings

enum ShieldRelockHelper {
    static let storeName = ManagedSettingsStore.Name(TimePayKeys.shieldStoreName)

    static func clearShields() {
        let store = ManagedSettingsStore(named: storeName)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    static func applySavedShield() {
        guard !TimePaySharedStorage.isUnlocked else {
            clearShields()
            return
        }
        guard let selection = loadSelection() else {
            clearShields()
            return
        }
        applyShield(selection: selection)
    }

    static func applyShield(selection: FamilyActivitySelection) {
        let store = ManagedSettingsStore(named: storeName)
        if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            return
        }
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            TimePaySharedStorage.defaults?.set(data, forKey: TimePayKeys.selectionData)
        }
    }

    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = TimePaySharedStorage.defaults?.data(forKey: TimePayKeys.selectionData),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func relockAll() {
        GateEngine.closeUnlock()
        applySavedShield()
    }

    static func syncUnlockStateIfExpired() {
        GateEngine.syncExpiredUnlock()
        guard GateEngine.isOpen else {
            applySavedShield()
            return
        }
        clearShields()
    }
}
#endif
