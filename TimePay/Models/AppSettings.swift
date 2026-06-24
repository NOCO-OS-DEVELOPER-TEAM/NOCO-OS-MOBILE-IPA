import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppSettings: ObservableObject {
    @Published var hapticsEnabled: Bool {
        didSet { persist() }
    }
    @Published var defaultUnlockMinutes: Int {
        didSet { persist() }
    }
    @Published var hasSeenOnboarding: Bool {
        didSet { persist() }
    }
    @Published var shortcutImported: Bool {
        didSet { persist() }
    }
    @Published var automationConfirmed: Bool {
        didSet { persist() }
    }

    init() {
        let d = TimePaySharedStorage.defaults
        hapticsEnabled = d?.object(forKey: TimePayKeys.hapticsEnabledKey) as? Bool ?? true
        defaultUnlockMinutes = d?.integer(forKey: TimePayKeys.defaultUnlockMinutesKey).nonZero ?? 10
        hasSeenOnboarding = d?.bool(forKey: TimePayKeys.hasSeenOnboardingKey) ?? false
        shortcutImported = d?.bool(forKey: TimePayKeys.shortcutImportedKey) ?? false
        automationConfirmed = d?.bool(forKey: TimePayKeys.automationConfirmedKey) ?? false
    }

    var setupProgress: Double {
        var steps = 0.0
        if automationConfirmed { steps += 1 }
        if hasSeenOnboarding { steps += 1 }
        return steps / 2.0
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func success() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func selection() {
        guard hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func rigid() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    private func persist() {
        let d = TimePaySharedStorage.defaults
        d?.set(hapticsEnabled, forKey: TimePayKeys.hapticsEnabledKey)
        d?.set(defaultUnlockMinutes, forKey: TimePayKeys.defaultUnlockMinutesKey)
        d?.set(hasSeenOnboarding, forKey: TimePayKeys.hasSeenOnboardingKey)
        d?.set(shortcutImported, forKey: TimePayKeys.shortcutImportedKey)
        d?.set(automationConfirmed, forKey: TimePayKeys.automationConfirmedKey)
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
