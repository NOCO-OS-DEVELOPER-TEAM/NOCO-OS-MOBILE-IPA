import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showResetConfirm = false
    @State private var newAccountName = ""
    @State private var showAddAccount = false

    var body: some View {
        List {
            Section("Profil") {
                if let account = store.activeAccount {
                    LabeledContent("Aktives Konto", value: account.name)
                }
                Picker("Konto wechseln", selection: Binding(
                    get: { store.activeAccountId ?? store.accounts.first!.id },
                    set: { id in
                        if let account = store.accounts.first(where: { $0.id == id }) {
                            store.setActiveAccount(account)
                        }
                    }
                )) {
                    ForEach(store.accounts) { account in
                        Label(account.name, systemImage: account.icon).tag(account.id)
                    }
                }
                Button("Neues Konto") { showAddAccount = true }
            }

            Section("Standort") {
                Toggle("Standort bei Buchungen speichern", isOn: Binding(
                    get: { store.locationEnabled },
                    set: { store.setLocationEnabled($0) }
                ))
            }

            Section("Benachrichtigungen") {
                Toggle("Smarte Hinweise", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { store.setNotificationsEnabled($0) }
                ))
                if store.notificationsEnabled {
                    Toggle("Monatsstart (Gehalt)", isOn: binding(\.monthStartReminder))
                    Toggle("Wöchentliche Erinnerung", isOn: binding(\.weeklyReminder))
                    Toggle("Wochentags-Muster", isOn: binding(\.weekdayPatterns))
                    Toggle("Spontan-Ausgaben", isOn: binding(\.spontaneousSpending))
                    Toggle("Einnahmen-Reaktion", isOn: binding(\.incomeReactions))
                    Toggle("Abo-Erinnerungen", isOn: binding(\.subscriptionReminders))
                    Toggle("Freundliche Reminder", isOn: binding(\.softEngagement))
                }
            }

            Section("Smart Assistant") {
                Picker("Standard-Modus", selection: Binding(
                    get: { store.assistantModePreference },
                    set: { store.setAssistantModePreference($0) }
                )) {
                    ForEach(AssistantMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                Toggle("Vorschläge bei leerem Feld", isOn: binding(\.assistantSuggestionsOnIdle))
            }

            Section("Daten") {
                LabeledContent("Buchungen", value: "\(store.accountFilteredTransactions.count)")
                LabeledContent("Sparziele", value: "\(store.goals.count)")
                LabeledContent("Abos", value: "\(store.subscriptions.count)")
                LabeledContent("Spar-Streak", value: "\(store.savingsStreakDays) Tage")
                NavigationLink("Ausgaben-Limits") {
                    SpendingLimitsView()
                }
            }

            Section {
                Button("Alle Daten zurücksetzen", role: .destructive) {
                    showResetConfirm = true
                }
            }
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Alle Daten löschen?", isPresented: $showResetConfirm) {
            Button("Löschen", role: .destructive) { store.resetAllData() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Buchungen, Ziele, Abos und Einstellungen werden unwiderruflich gelöscht.")
        }
        .alert("Neues Konto", isPresented: $showAddAccount) {
            TextField("Name", text: $newAccountName)
            Button("Hinzufügen") {
                let name = newAccountName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                store.addAccount(name: name)
                newAccountName = ""
            }
            Button("Abbrechen", role: .cancel) { newAccountName = "" }
        }
    }

    private func binding(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.notificationPreferences[keyPath: keyPath] },
            set: {
                var prefs = store.notificationPreferences
                prefs[keyPath: keyPath] = $0
                store.setNotificationPreferences(prefs)
            }
        )
    }
}
