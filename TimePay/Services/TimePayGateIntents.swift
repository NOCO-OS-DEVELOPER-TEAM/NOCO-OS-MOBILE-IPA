import AppIntents
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Deep-link helpers (Icon long-press, Widgets — nicht für Automation)

private func queueDeepLink(_ action: String) {
    TimePaySharedStorage.defaults?.set(action, forKey: TimePayKeys.pendingDeepLinkKey)
}

struct OpenUnlockIntent: AppIntent {
    static var title: LocalizedStringResource = "Zeit abbuchen"
    static var description = IntentDescription("Öffnet TimePay zum Freischalten. Nur fürs App-Icon oder Widgets — nicht für Automation.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("unlock")
        return .result()
    }
}

struct OpenEarnIntent: AppIntent {
    static var title: LocalizedStringResource = "Zeit verdienen"
    static var description = IntentDescription("Startet eine Verdien-Session. Nur fürs App-Icon — nicht für Automation.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("earn")
        return .result()
    }
}

struct EndUnlockEarlyIntent: AppIntent {
    static var title: LocalizedStringResource = "Freigabe beenden"
    static var description = IntentDescription("Beendet die laufende Freigabe früh. Nur fürs App-Icon — nicht für Automation.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("end")
        return .result()
    }
}

struct IsGateOpenIntent: AppIntent {
    static var title: LocalizedStringResource = "Hat Freigabe-Zeit?"
    static var description = IntentDescription(
        "Nur für eigene Kurzbefehle mit Wenn/Dann. Für Automation immer „Apps sperren“ nutzen."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        return .result(value: ShortcutGateManager.isGateOpen)
    }
}

/// Hauptaktion für Personal Automation — prüft Zeit, öffnet TimePay nur ohne Freigabe.
struct EnforceTimePayGateIntent: AppIntent {
    static var title: LocalizedStringResource = "Apps sperren"
    static var description = IntentDescription(
        "Für Automation „App wird geöffnet“: Ohne Freigabe öffnet sich TimePay. Mit Freigabe passiert nichts — die App bleibt offen."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        if ShortcutGateManager.isGateOpen {
            return .result()
        }
        queueDeepLink("gate")
        guard let url = URL(string: "timepay://gate") else {
            return .result()
        }
        #if canImport(UIKit)
        await UIApplication.shared.open(url)
        #endif
        return .result()
    }
}

struct GateRemainingMinutesIntent: AppIntent {
    static var title: LocalizedStringResource = "Restzeit in Minuten"
    static var description = IntentDescription("Wie viele Freigabe-Minuten noch übrig sind. Nur für eigene Kurzbefehle.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let seconds = TimePaySharedStorage.remainingUnlockSeconds()
        return .result(value: max(0, (seconds + 59) / 60))
    }
}

struct EndUnlockSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Freigabe beenden"
    static var description = IntentDescription("Beendet die Freigabe vom Sperrbildschirm aus.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        TimePaySharedStorage.defaults?.set(true, forKey: TimePayKeys.pendingEndUnlockKey)
        return .result()
    }
}

/// Nur eine Siri-Kachel — die Automation-Aktion. Keine verwirrenden Extra-Kacheln.
struct TimePayShortcuts: AppShortcutsProvider {
    static var appShortcutTileColor = ShortcutTileColor.teal

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: EnforceTimePayGateIntent(),
            phrases: [
                "Apps sperren mit \(.applicationName)",
                "\(.applicationName) Sperre",
            ],
            shortTitle: "Apps sperren",
            systemImageName: "lock.shield.fill"
        )
    }
}
