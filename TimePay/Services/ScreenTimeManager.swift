import Foundation
import SwiftUI
import Combine

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

@MainActor
final class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authError: String?
    @Published var blockedAppCount = 0

    #if canImport(FamilyControls)
    @Published var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore()
    private let selectionKey = "timepay.selection"
    #endif

    func bootstrap() async {
        await requestAuthorization()
        #if canImport(FamilyControls)
        loadSelection()
        applyShield()
        #endif
    }

    func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            if !isAuthorized {
                authError = "Bildschirmzeit-Zugriff nicht erlaubt."
            }
        } catch {
            authError = error.localizedDescription
            isAuthorized = false
        }
        #else
        authError = "Screen Time API nicht verfügbar."
        #endif
    }

    #if canImport(FamilyControls)
    func updateSelection(_ newValue: FamilyActivitySelection) {
        selection = newValue
        blockedAppCount = selection.applicationTokens.count + selection.categoryTokens.count
        saveSelection()
        applyShield()
    }

    func applyShield() {
        guard isAuthorized else { return }
        if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        } else {
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        }
    }

    func temporaryUnlock(minutes: Int) {
        guard isAuthorized else { return }
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    func relock() {
        applyShield()
    }

    private func saveSelection() {
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: selectionKey)
        }
    }

    private func loadSelection() {
        guard let data = UserDefaults.standard.data(forKey: selectionKey),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        selection = decoded
        blockedAppCount = selection.applicationTokens.count + selection.categoryTokens.count
    }
    #endif
}
