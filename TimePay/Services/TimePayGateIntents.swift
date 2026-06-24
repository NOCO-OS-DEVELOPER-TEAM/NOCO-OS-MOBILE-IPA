import AppIntents

struct IsGateOpenIntent: AppIntent {
    static var title: LocalizedStringResource = "TimePay Gate prüfen"
    static var description = IntentDescription(
        "Gibt wahr zurück, wenn Apps gerade freigeschaltet sind. Der Kurzbefehl leitet nur um, wenn falsch."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        return .result(value: ShortcutGateManager.isGateOpen)
    }
}

struct GateRemainingMinutesIntent: AppIntent {
    static var title: LocalizedStringResource = "TimePay Restzeit (Minuten)"
    static var description = IntentDescription("Verbleibende Freigabe-Minuten als Zahl.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let seconds = TimePaySharedStorage.remainingUnlockSeconds()
        return .result(value: max(0, (seconds + 59) / 60))
    }
}

struct TimePayShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
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
