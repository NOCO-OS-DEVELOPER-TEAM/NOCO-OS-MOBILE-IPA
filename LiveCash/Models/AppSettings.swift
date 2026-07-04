import Foundation

// MARK: - Enums

enum SuggestionIntensity: String, Codable, CaseIterable, Identifiable {
    case low = "Niedrig"
    case medium = "Mittel"
    case high = "Hoch"
    var id: String { rawValue }
}

enum ConfirmationMode: String, Codable, CaseIterable, Identifiable {
    case off = "Aus"
    case smart = "Smart"
    case strict = "Strikt"
    var id: String { rawValue }
}

enum BalanceBlurMode: String, Codable, CaseIterable, Identifiable {
    case always = "Immer versteckt"
    case homeOnly = "Nur Start"
    case never = "Nie versteckt"
    var id: String { rawValue }
}

enum FaceIDLockMode: String, Codable, CaseIterable, Identifiable {
    case off = "Aus"
    case onLaunch = "Beim Öffnen"
    case onInactivity = "Nach Inaktivität"
    var id: String { rawValue }
}

enum AnimationLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Wenig"
    case medium = "Mittel"
    case high = "Viel"
    var id: String { rawValue }
}

enum MoneyCardDisplayLevel: String, Codable, CaseIterable, Identifiable {
    case simple = "Einfach"
    case standard = "Standard"
    case advanced = "Erweitert"
    var id: String { rawValue }
}

enum MapDetailLevel: String, Codable, CaseIterable, Identifiable {
    case minimal = "Minimal"
    case standard = "Standard"
    case detailed = "Detailliert"
    var id: String { rawValue }
}

// MARK: - Section Settings

struct AssistantSettings: Codable, Equatable {
    var suggestionsEnabled: Bool = true
    var suggestionIntensity: SuggestionIntensity = .medium
    var confirmationMode: ConfirmationMode = .smart
    var autoDetectIncomeExpense: Bool = true
    var subscriptionDetection: Bool = true
    var patternDetection: Bool = true
    var confidenceThreshold: Int = 70
}

struct SecuritySettings: Codable, Equatable {
    var faceIDEnabled: Bool = false
    var faceIDLockMode: FaceIDLockMode = .off
    var inactivityLockMinutes: Int = 5
    var balanceBlurMode: BalanceBlurMode = .never
    var requireFaceIDToRevealBalance: Bool = false
}

struct ShortcutSettings: Codable, Equatable {
    var maxActiveShortcuts: Int = 6
    var autoShortcutsEnabled: Bool = true
}

struct MapSettings: Codable, Equatable {
    var resetFilterOnOpen: Bool = true
    var timelineHistoryEnabled: Bool = true
    var pinZoomEnabled: Bool = true
    var clusterModeEnabled: Bool = true
    var detailLevel: MapDetailLevel = .standard
}

struct SavingsSettings: Codable, Equatable {
    var maxGoals: Int = 10
    var showProgress: Bool = true
    var smartInsightsEnabled: Bool = true
    var progressAlerts: Bool = true
    var nearGoalAlerts: Bool = true
    var slowProgressAlerts: Bool = true
}

struct MoneyCardSettings: Codable, Equatable {
    var displayLevel: MoneyCardDisplayLevel = .standard
    var smoothAnimations: Bool = true
}

struct UISettings: Codable, Equatable {
    var animationLevel: AnimationLevel = .medium
    var hapticsEnabled: Bool = true
    var compactMode: Bool = false
}

struct AppSettings: Codable, Equatable {
    var assistant: AssistantSettings = AssistantSettings()
    var security: SecuritySettings = SecuritySettings()
    var shortcuts: ShortcutSettings = ShortcutSettings()
    var map: MapSettings = MapSettings()
    var savings: SavingsSettings = SavingsSettings()
    var moneyCard: MoneyCardSettings = MoneyCardSettings()
    var ui: UISettings = UISettings()
}
