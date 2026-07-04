import Foundation

struct AppData: Codable {
    var transactions: [Transaction]
    var goals: [SavingsGoal]
    var subscriptions: [Subscription]
    var locationEnabled: Bool

    static let empty = AppData(
        transactions: [],
        goals: [],
        subscriptions: [],
        locationEnabled: false
    )
}

final class PersistenceService {
    static let shared = PersistenceService()

    private let fileName = "livecash_data.json"
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

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    func load() -> AppData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .empty }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(AppData.self, from: data)
        } catch {
            return .empty
        }
    }

    func save(_ data: AppData) {
        do {
            let encoded = try encoder.encode(data)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            // Silent fail — local-first, no cloud
        }
    }
}
