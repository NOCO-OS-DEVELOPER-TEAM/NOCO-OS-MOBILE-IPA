import SwiftUI
import UniformTypeIdentifiers

struct DataManagementSettingsView: View {
    @EnvironmentObject private var store: FinanceStore
    @ObservedObject private var cloud = CloudSyncService.shared
    @ObservedObject private var appleSignIn = AppleSignInService.shared

    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var importMerge = true
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Exportiere alle Daten als Backup oder spiele sie auf einem neuen Gerät wieder ein.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Section("Backup") {
                Button("Daten exportieren (JSON)") {
                    exportData()
                }
                Button("Daten importieren") {
                    showImporter = true
                }
                Toggle("Beim Import zusammenführen", isOn: $importMerge)
            }

            Section("iCloud") {
                Toggle("iCloud Sync", isOn: Binding(
                    get: { store.appSettings.cloud.iCloudSyncEnabled },
                    set: { enabled in
                        var settings = store.appSettings
                        settings.cloud.iCloudSyncEnabled = enabled
                        store.setAppSettings(settings)
                        if enabled {
                            CloudSyncService.shared.push(store: store)
                        }
                    }
                ))
                if let last = cloud.lastSyncDate {
                    LabeledContent("Letzter Sync", value: last.formatted(date: .abbreviated, time: .shortened))
                }
                if let err = cloud.syncError {
                    Text(err).font(LiveCashTheme.captionFont).foregroundStyle(LiveCashTheme.expense)
                }
                Button("Jetzt synchronisieren") {
                    CloudSyncService.shared.push(store: store)
                    statusMessage = "Sync ausgelöst"
                }
            }

            Section("Apple ID") {
                if appleSignIn.isSignedIn {
                    LabeledContent("Angemeldet", value: "Aktiv")
                    Button("Abmelden", role: .destructive) {
                        appleSignIn.signOut()
                    }
                } else {
                    Button("Mit Apple anmelden") {
                        appleSignIn.signIn()
                    }
                }
                Toggle("Sign in with Apple nutzen", isOn: Binding(
                    get: { store.appSettings.cloud.signInWithAppleEnabled },
                    set: { value in
                        var settings = store.appSettings
                        settings.cloud.signInWithAppleEnabled = value
                        store.setAppSettings(settings)
                    }
                ))
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
