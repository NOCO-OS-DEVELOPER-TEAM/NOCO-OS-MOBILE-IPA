import AppIntents

// MARK: - Deep-link helpers (Icon long-press, Widgets)

private func queueDeepLink(_ action: String) {
    TimePaySharedStorage.queuePendingDeepLink(action)
}

struct OpenUnlockIntent: AppIntent {
    static var title: LocalizedStringResource = "Zeit abbuchen"
    static var description = IntentDescription("Öffnet TimePay zum Freischalten.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("unlock")
        return .result()
    }
}

struct OpenEarnIntent: AppIntent {
    static var title: LocalizedStringResource = "Session starten"
    static var description = IntentDescription("Startet eine Verdien-Session.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("earn")
        return .result()
    }
}

struct EndUnlockEarlyIntent: AppIntent {
    static var title: LocalizedStringResource = "Freigabe beenden"
    static var description = IntentDescription("Beendet die laufende Freigabe.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        queueDeepLink("end")
        return .result()
    }
}

/// Automation-Aktion — öffnet TimePay nur ohne aktive Freigabe.
struct EnforceTimePayGateIntent: AppIntent {
    static var title: LocalizedStringResource = "Apps sperren"
    static var description = IntentDescription(
        "Für Automation: Ohne Freigabe öffnet sich TimePay. Mit Freigabe passiert nichts."
    )
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        GateEngine.syncExpiredUnlock()
        if GateEngine.isOpen {
            return .result()
        }
        GateEngine.requestBlock()
        return .result()
    }
}

struct EndUnlockSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Freigabe beenden"
    static var description = IntentDescription("Beendet die Freigabe vom Sperrbildschirm.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TimePaySharedStorage.queuePendingEndUnlock()
        return .result()
    }
}

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
