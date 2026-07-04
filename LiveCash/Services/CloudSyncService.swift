import Foundation

@MainActor
final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: String?

    private let cloudFileName = "livecash_icloud_backup.json"

    private var cloudURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent(cloudFileName)
    }

    func push(store: FinanceStore) {
        guard store.appSettings.cloud.iCloudSyncEnabled else { return }
        guard let url = cloudURL else {
            syncError = "iCloud nicht verfügbar"
            return
        }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try PersistenceService.shared.exportAppData(buildFrom: store)
            try data.write(to: url, options: .atomic)
            lastSyncDate = Date()
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }

    func pull(into store: FinanceStore) {
        guard store.appSettings.cloud.iCloudSyncEnabled else { return }
        guard let url = cloudURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            try PersistenceService.shared.importAppData(data, into: store, merge: true)
            lastSyncDate = Date()
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }
}
