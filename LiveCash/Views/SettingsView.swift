import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showResetConfirm = false
    @State private var newAccountName = ""
    @State private var showAddAccount = false

    var body: some View {
        List {
            Section {
                Text("Control Center — hier wird alles konfiguriert. Der Start-Tab bleibt zum Nutzen.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Section("System") {
                NavigationLink {
                    AssistantSettingsView()
                } label: {
                    Label("Smart System", systemImage: "brain.head.profile")
                }
                NavigationLink {
                    SecuritySettingsView()
                } label: {
                    Label("Sicherheit & Privatsphäre", systemImage: "faceid")
                }
                NavigationLink {
                    ShortcutSettingsView()
                } label: {
                    Label("Shortcuts", systemImage: "square.grid.2x2.fill")
                }
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Benachrichtigungen", systemImage: "bell.badge")
                }
            }

            Section("Bereiche") {
                NavigationLink {
                    MoneyCardSettingsView()
                } label: {
                    Label("Money Card & Widget", systemImage: "creditcard.fill")
                }
                NavigationLink {
                    SavingsSettingsView()
                } label: {
                    Label("Sparziele", systemImage: "target")
                }
                NavigationLink {
                    MapSettingsView()
                } label: {
                    Label("Geldkarte", systemImage: "map.fill")
                }
                NavigationLink {
                    UISettingsView()
                } label: {
                    Label("UI & Design", systemImage: "paintbrush")
                }
            }

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
}
