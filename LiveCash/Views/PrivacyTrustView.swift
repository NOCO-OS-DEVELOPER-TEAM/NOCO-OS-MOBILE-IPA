import SwiftUI

struct PrivacyTrustView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dein Geld. Deine Daten.")
                        .font(LiveCashTheme.headlineFont)
                    Text("Live Cash speichert Finanzen lokal auf diesem Gerät. Es gibt keine Cloud-Analyse deiner Buchungen und keinen Verkauf von Daten.")
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Sicherheit") {
                Label("Face ID / App-Sperre in den Einstellungen", systemImage: "faceid")
                Label("Kontostand kann unscharf dargestellt werden", systemImage: "eye.slash")
                Label("Keine Konten-Login bei Banken nötig", systemImage: "building.columns")
            }

            Section("Kontrolle") {
                NavigationLink {
                    DataManagementSettingsView()
                } label: {
                    Label("Backup & Export", systemImage: "externaldrive")
                }
                NavigationLink {
                    SecuritySettingsView()
                } label: {
                    Label("Sicherheitseinstellungen", systemImage: "lock.fill")
                }
            }

            Section("Reset") {
                Text("Unter Einstellungen → Datenverwaltung kannst du die App vollständig zurücksetzen. Das löscht alle lokalen Buchungen unwiderruflich.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
    }
}
