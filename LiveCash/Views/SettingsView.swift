import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section("Standort") {
                Toggle("Standort bei Buchungen speichern", isOn: Binding(
                    get: { store.locationEnabled },
                    set: { store.setLocationEnabled($0) }
                ))
                Text("Für die Geldkarte. Optional und nur lokal gespeichert.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Section("Benachrichtigungen") {
                Toggle("Smarte Hinweise", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { store.setNotificationsEnabled($0) }
                ))
                Text("Fortschritt, Ausgaben-Warnungen und Erinnerungen — nur lokal.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Section("Daten") {
                LabeledContent("Buchungen", value: "\(store.transactions.count)")
                LabeledContent("Sparziele", value: "\(store.goals.count)")
                LabeledContent("Abos", value: "\(store.subscriptions.count)")
            }

            Section("Hinweise") {
                Text("Tippe auf eine Buchung für Details und Bearbeitung. Standort, Betrag und Kategorie lassen sich jederzeit ändern.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text("Alle Daten bleiben auf deinem Gerät. Live Cash verbindet sich nicht mit Banken oder externen APIs.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}
