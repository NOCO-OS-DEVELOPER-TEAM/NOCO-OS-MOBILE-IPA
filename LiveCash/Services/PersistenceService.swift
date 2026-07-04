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

    static let empty = AppData(
        transactions: [],
        goals: [],
        subscriptions: [],
        locationEnabled: false,
        savingsStreakDays: 0,
        lastActiveDate: nil,
        notificationsEnabled: true,
        shortcuts: [],
        spendingLimits: .default
    )

    enum CodingKeys: String, CodingKey {
        case transactions, goals, subscriptions, locationEnabled
        case savingsStreakDays, lastActiveDate, notificationsEnabled
        case shortcuts, spendingLimits
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
        spendingLimits: SpendingLimits = .default
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
