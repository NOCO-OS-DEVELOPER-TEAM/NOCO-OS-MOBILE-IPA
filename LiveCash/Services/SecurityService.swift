import LocalAuthentication
import SwiftUI

@MainActor
final class SecurityService: ObservableObject {
    static let shared = SecurityService()

    @Published private(set) var isUnlocked = true
    @Published var balanceRevealed = false
    private var lastActiveAt = Date()

    func lock() {
        isUnlocked = false
    }

    func resetLockState(for settings: SecuritySettings) {
        guard settings.faceIDEnabled, settings.faceIDLockMode != .off else {
            isUnlocked = true
            return
        }
        if settings.faceIDLockMode == .onLaunch {
            isUnlocked = false
        }
    }

    func lockBalanceIfNeeded(settings: SecuritySettings) {
        balanceRevealed = false
    }

    func recordActivity() {
        lastActiveAt = Date()
    }

    func shouldLockForInactivity(settings: SecuritySettings) -> Bool {
        guard settings.faceIDEnabled, settings.faceIDLockMode == .onInactivity else { return false }
        let elapsed = Date().timeIntervalSince(lastActiveAt)
        return elapsed >= Double(settings.inactivityLockMinutes * 60)
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        guard context.canEvaluatePolicy(policy, error: &error) else { return false }
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if success { isUnlocked = true }
            return success
        } catch {
            return false
        }
    }

    func revealBalance(settings: SecuritySettings) async -> Bool {
        if settings.requireFaceIDToRevealBalance {
            let ok = await authenticate(reason: "Kontostand anzeigen")
            if ok { balanceRevealed = true }
            return ok
        }
        balanceRevealed = true
        return true
    }

    /// Tap-to-toggle blur on the home balance.
    func toggleBalanceReveal(settings: SecuritySettings) async {
        if balanceRevealed {
            balanceRevealed = false
            return
        }
        _ = await revealBalance(settings: settings)
    }
}
