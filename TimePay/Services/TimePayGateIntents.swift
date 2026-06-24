import AppIntents
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Deep-link helpers (Icon long-press, Widgets, Siri)

private func queueDeepLink(_ action: String) {
    TimePaySharedStorage.defaults?.set(action, forKey: TimePayKeys.pendingDeepLinkKey)
}

struct OpenUnlockIntent: AppIntent {
    static var title: LocalizedStringResource = "Zeit abbuchen"
    static var description = IntentDescription("TimePay öffnen und Apps freischalten.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("unlock")
        return .result()
    }
}

struct OpenEarnIntent: AppIntent {
    static var title: LocalizedStringResource = "Session starten"
    static var description = IntentDescription("Focus-Session starten und Zeit verdienen.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("earn")
        return .result()
    }
}

struct EndUnlockEarlyIntent: AppIntent {
    static var title: LocalizedStringResource = "Freigabe beenden"
    static var description = IntentDescription("Freigabe stoppen und Restzeit erstatten.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("end")
        return .result()
    }
}

struct IsGateOpenIntent: AppIntent {
    static var title: LocalizedStringResource = "TimePay Gate prüfen"
    static var description = IntentDescription(
        "Gibt wahr zurück, wenn Apps gerade freigeschaltet sind. Nur für eigene Kurzbefehle — für Automation „Gate durchsetzen“ nutzen."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        return .result(value: ShortcutGateManager.isGateOpen)
    }
}

/// Eine Aktion für Personal Automation — kein eigener Kurzbefehl nötig.
struct EnforceTimePayGateIntent: AppIntent {
    static var title: LocalizedStringResource = "Gate durchsetzen"
    static var description = IntentDescription(
        "Für Automation „App wird geöffnet“: Ohne Freigabe öffnet TimePay. Mit Freigabe passiert nichts."
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
    static var title: LocalizedStringResource = "TimePay Restzeit"
    static var description = IntentDescription("Verbleibende Freigabe-Minuten.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let seconds = TimePaySharedStorage.remainingUnlockSeconds()
        return .result(value: max(0, (seconds + 59) / 60))
    }
}

struct EndUnlockSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Freigabe beenden"
    static var description = IntentDescription("Beendet die Freigabe frühzeitig und erstattet ungenutzte Zeit.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        TimePaySharedStorage.defaults?.set(true, forKey: TimePayKeys.pendingEndUnlockKey)
        return .result()
    }
}

struct TimePayShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenUnlockIntent(),
            phrases: [
                "Zeit abbuchen in \(.applicationName)",
                "Apps freischalten mit \(.applicationName)",
            ],
            shortTitle: "Zeit abbuchen",
            systemImageName: "lock.open.fill"
        )
        AppShortcut(
            intent: OpenEarnIntent(),
            phrases: [
                "Session starten in \(.applicationName)",
                "Zeit verdienen mit \(.applicationName)",
            ],
            shortTitle: "Session starten",
            systemImageName: "play.circle.fill"
        )
        AppShortcut(
            intent: EndUnlockEarlyIntent(),
            phrases: [
                "Freigabe beenden in \(.applicationName)",
                "Gate schließen mit \(.applicationName)",
            ],
            shortTitle: "Freigabe beenden",
            systemImageName: "stop.circle.fill"
        )
        AppShortcut(
            intent: EnforceTimePayGateIntent(),
            phrases: [
                "TimePay Gate durchsetzen mit \(.applicationName)",
                "Apps schützen mit \(.applicationName)",
            ],
            shortTitle: "Gate durchsetzen",
            systemImageName: "lock.shield.fill"
        )
        AppShortcut(
            intent: IsGateOpenIntent(),
            phrases: [
                "Prüfe TimePay Gate mit \(.applicationName)",
                "Ist TimePay Gate offen in \(.applicationName)",
            ],
            shortTitle: "Gate prüfen",
            systemImageName: "lock.shield"
        )
    }
}
