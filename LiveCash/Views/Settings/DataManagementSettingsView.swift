import SwiftUI
import UniformTypeIdentifiers

struct DataManagementSettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var importMerge = true
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var showResetConfirm = false

    var body: some View {
        List {
            Section {
                Text("Nur lokale Backups — Export, Import und Reset.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Section("Backup") {
                Button("Exportieren (JSON)") { exportData() }
                Button("Importieren") { showImporter = true }
                Toggle("Beim Import zusammenführen", isOn: $importMerge)
            }

            Section {
                Button("Alles zurücksetzen", role: .destructive) {
                    showResetConfirm = true
                }
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.income)
                }
            }
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.expense)
                }
            }
        }
        .navigationTitle("Daten verwalten")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Alles zurücksetzen?", isPresented: $showResetConfirm) {
            Button("Löschen", role: .destructive) { store.resetAllData() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle Daten und Einstellungen werden gelöscht.")
        }
        .fileExporter(
            isPresented: $showExporter,
            document: BackupFileDocument(url: exportURL),
            contentType: .json,
            defaultFilename: DataBackupService.exportFileName
        ) { result in
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try DataBackupService.importData(from: url, into: store, merge: importMerge)
                    statusMessage = importMerge ? "Daten zusammengeführt" : "Daten ersetzt"
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportData() {
        do {
            exportURL = try DataBackupService.exportData(from: store)
            showExporter = true
            statusMessage = "Backup erstellt"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BackupFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let url: URL?

    init(url: URL?) { self.url = url }

    init(configuration: ReadConfiguration) throws {
        url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url, let data = try? Data(contentsOf: url) else {
            return FileWrapper(regularFileWithContents: Data())
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
