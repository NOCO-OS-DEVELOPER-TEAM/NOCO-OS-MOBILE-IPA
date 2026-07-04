import Foundation
import UniformTypeIdentifiers

enum DataBackupService {
    static let exportFileName = "LiveCash-Backup.json"

    @MainActor
    static func exportData(from store: FinanceStore) throws -> URL {
        let data = try PersistenceService.shared.exportAppData(buildFrom: store)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(exportFileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func importData(from url: URL, into store: FinanceStore, merge: Bool) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        try PersistenceService.shared.importAppData(data, into: store, merge: merge)
    }
}

extension PersistenceService {
    @MainActor
    func exportAppData(buildFrom store: FinanceStore) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(store.snapshotAppData())
    }

    @MainActor
    func importAppData(_ data: Data, into store: FinanceStore, merge: Bool) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let imported = try decoder.decode(AppData.self, from: data)
        if merge {
            store.mergeAppData(imported)
        } else {
            store.replaceAppData(imported)
        }
        save(store.snapshotAppData())
    }
}
