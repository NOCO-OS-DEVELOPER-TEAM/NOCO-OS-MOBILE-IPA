import Foundation

struct AppData: Codable {
    var transactions: [Transaction]
    var goals: [SavingsGoal]
    var subscriptions: [Subscription]
    var locationEnabled: Bool
    var savingsStreakDays: Int
    var lastActiveDate: Date?
    var notificationsEnabled: Bool
    var shortcuts: [QuickShortcut]
    var spendingLimits: SpendingLimits
    var accounts: [FinanceAccount]
    var activeAccountId: UUID?
    var notificationPreferences: NotificationPreferences
    var assistantModePreference: AssistantMode
    var notificationLearning: NotificationLearning
    var widgetPreferences: WidgetPreferences
    var appSettings: AppSettings

    static let empty = AppData(
        transactions: [],
        goals: [],
        subscriptions: [],
        locationEnabled: false,
        savingsStreakDays: 0,
        lastActiveDate: nil,
        notificationsEnabled: true,
        shortcuts: [],
        spendingLimits: .default,
        accounts: [FinanceAccount.defaultPrivate],
        activeAccountId: nil,
        notificationPreferences: NotificationPreferences(),
        assistantModePreference: .suggestion,
        notificationLearning: NotificationLearning(),
        widgetPreferences: WidgetPreferences(),
        appSettings: AppSettings()
    )

    enum CodingKeys: String, CodingKey {
        case transactions, goals, subscriptions, locationEnabled
        case savingsStreakDays, lastActiveDate, notificationsEnabled
        case shortcuts, spendingLimits, accounts, activeAccountId
        case notificationPreferences, assistantModePreference, notificationLearning
        case widgetPreferences, appSettings
    }

    init(
        transactions: [Transaction],
        goals: [SavingsGoal],
        subscriptions: [Subscription],
        locationEnabled: Bool,
        savingsStreakDays: Int = 0,
        lastActiveDate: Date? = nil,
        notificationsEnabled: Bool = true,
        shortcuts: [QuickShortcut] = [],
        spendingLimits: SpendingLimits = .default,
        accounts: [FinanceAccount] = [FinanceAccount.defaultPrivate],
        activeAccountId: UUID? = nil,
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        assistantModePreference: AssistantMode = .suggestion,
        notificationLearning: NotificationLearning = NotificationLearning(),
        widgetPreferences: WidgetPreferences = WidgetPreferences(),
        appSettings: AppSettings = AppSettings()
    ) {
        self.transactions = transactions
        self.goals = goals
        self.subscriptions = subscriptions
        self.locationEnabled = locationEnabled
        self.savingsStreakDays = savingsStreakDays
        self.lastActiveDate = lastActiveDate
        self.notificationsEnabled = notificationsEnabled
        self.shortcuts = shortcuts
        self.spendingLimits = spendingLimits
        self.accounts = accounts.isEmpty ? [FinanceAccount.defaultPrivate] : accounts
        self.activeAccountId = activeAccountId ?? self.accounts.first(where: \.isDefault)?.id ?? self.accounts.first?.id
        self.notificationPreferences = notificationPreferences
        self.assistantModePreference = assistantModePreference
        self.notificationLearning = notificationLearning
        self.widgetPreferences = widgetPreferences
        self.appSettings = appSettings
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        transactions = try c.decode([Transaction].self, forKey: .transactions)
        goals = try c.decode([SavingsGoal].self, forKey: .goals)
        subscriptions = try c.decode([Subscription].self, forKey: .subscriptions)
        locationEnabled = try c.decode(Bool.self, forKey: .locationEnabled)
        savingsStreakDays = try c.decodeIfPresent(Int.self, forKey: .savingsStreakDays) ?? 0
        lastActiveDate = try c.decodeIfPresent(Date.self, forKey: .lastActiveDate)
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        shortcuts = try c.decodeIfPresent([QuickShortcut].self, forKey: .shortcuts) ?? []
        spendingLimits = try c.decodeIfPresent(SpendingLimits.self, forKey: .spendingLimits) ?? .default
        accounts = try c.decodeIfPresent([FinanceAccount].self, forKey: .accounts) ?? [FinanceAccount.defaultPrivate]
        if accounts.isEmpty { accounts = [FinanceAccount.defaultPrivate] }
        activeAccountId = try c.decodeIfPresent(UUID.self, forKey: .activeAccountId) ?? accounts.first(where: \.isDefault)?.id ?? accounts.first?.id
        notificationPreferences = try c.decodeIfPresent(NotificationPreferences.self, forKey: .notificationPreferences) ?? NotificationPreferences()
        if let modeRaw = try c.decodeIfPresent(String.self, forKey: .assistantModePreference),
           let mode = AssistantMode(rawValue: modeRaw) {
            assistantModePreference = mode
        } else {
            assistantModePreference = .suggestion
        }
        notificationLearning = try c.decodeIfPresent(NotificationLearning.self, forKey: .notificationLearning) ?? NotificationLearning()
        widgetPreferences = try c.decodeIfPresent(WidgetPreferences.self, forKey: .widgetPreferences) ?? WidgetPreferences()
        appSettings = try c.decodeIfPresent(AppSettings.self, forKey: .appSettings) ?? AppSettings()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(transactions, forKey: .transactions)
        try c.encode(goals, forKey: .goals)
        try c.encode(subscriptions, forKey: .subscriptions)
        try c.encode(locationEnabled, forKey: .locationEnabled)
        try c.encode(savingsStreakDays, forKey: .savingsStreakDays)
        try c.encodeIfPresent(lastActiveDate, forKey: .lastActiveDate)
        try c.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try c.encode(shortcuts, forKey: .shortcuts)
        try c.encode(spendingLimits, forKey: .spendingLimits)
        try c.encode(accounts, forKey: .accounts)
        try c.encodeIfPresent(activeAccountId, forKey: .activeAccountId)
        try c.encode(notificationPreferences, forKey: .notificationPreferences)
        try c.encode(assistantModePreference.rawValue, forKey: .assistantModePreference)
        try c.encode(notificationLearning, forKey: .notificationLearning)
        try c.encode(widgetPreferences, forKey: .widgetPreferences)
        try c.encode(appSettings, forKey: .appSettings)
    }
}

final class PersistenceService {
    static let shared = PersistenceService()

    private let fileName = "livecash_data.json"
    private let backupFileName = "livecash_data_backup.json"
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var fileURL: URL {
        documentsURL.appendingPathComponent(fileName)
    }

    private var backupURL: URL {
        documentsURL.appendingPathComponent(backupFileName)
    }

    func load() -> AppData {
        if let data = readData(from: fileURL) {
            return decode(data) ?? .empty
        }
        if let backup = readData(from: backupURL) {
            return decode(backup) ?? .empty
        }
        return .empty
    }

    func save(_ data: AppData) {
        guard let encoded = encode(data) else { return }
        if FileManager.default.fileExists(atPath: fileURL.path),
           let existing = readData(from: fileURL) {
            try? existing.write(to: backupURL, options: .atomic)
        }
        try? encoded.write(to: fileURL, options: .atomic)
        mirrorToAppGroup(encoded)
    }

    func resetAll() {
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: backupURL)
    }

    private func readData(from url: URL) -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func decode(_ data: Data) -> AppData? {
        try? decoder.decode(AppData.self, from: data)
    }

    private func encode(_ data: AppData) -> Data? {
        try? encoder.encode(data)
    }

    private func mirrorToAppGroup(_ data: Data) {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: LiveCashAppGroup.identifier
        ) else { return }
        let groupFile = container.appendingPathComponent(fileName)
        try? data.write(to: groupFile, options: .atomic)
    }
}
