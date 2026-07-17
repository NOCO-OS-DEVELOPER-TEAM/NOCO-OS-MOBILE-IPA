import SwiftUI

private struct SettingsSearchItem: Identifiable {
    let id: String
    let title: String
    let keywords: [String]
    let section: String
    let destination: SettingsDestination
}

private enum SettingsDestination: Hashable {
    case assistant
    case security
    case shortcuts
    case notifications
    case limits
    case categories
    case moneyCard
    case savings
    case savingsOptions
    case map
    case ui
    case data
    case profile
}

struct SettingsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showResetConfirm = false
    @State private var newAccountName = ""
    @State private var showAddAccount = false
    @State private var searchText = ""

    private var catalog: [SettingsSearchItem] {
        [
            .init(id: "assistant", title: "Smart Assistant", keywords: ["assistant", "vorschläge", "vorschlag", "analyse", "smart"], section: "Smart Assistant", destination: .assistant),
            .init(id: "security", title: "Sicherheit & Privatsphäre", keywords: ["faceid", "sicherheit", "sperre", "privacy"], section: "Profil & Konto", destination: .security),
            .init(id: "shortcuts", title: "Shortcuts", keywords: ["shortcut", "schnell"], section: "Smart Assistant", destination: .shortcuts),
            .init(id: "notifications", title: "Benachrichtigungen", keywords: ["benachrichtigung", "notification", "erinnerung", "warnung"], section: "Benachrichtigungen", destination: .notifications),
            .init(id: "limits", title: "Ausgabenlimits", keywords: ["limit", "budget", "ausgaben"], section: "Geld & Sparen", destination: .limits),
            .init(id: "categories", title: "Kategorien", keywords: ["kategorie", "tags"], section: "Geld & Sparen", destination: .categories),
            .init(id: "money", title: "Money Card & Widget", keywords: ["widget", "money", "karte", "card"], section: "Design", destination: .moneyCard),
            .init(id: "savings", title: "Sparziele", keywords: ["sparziel", "sparen", "ziel", "live activity"], section: "Geld & Sparen", destination: .savings),
            .init(id: "savings-options", title: "Sparziel-Optionen", keywords: ["live activity", "fortschritt", "sparziel einstellungen"], section: "Geld & Sparen", destination: .savingsOptions),
            .init(id: "map", title: "Geldkarte", keywords: ["karte", "map", "pin", "standort"], section: "Design", destination: .map),
            .init(id: "ui", title: "UI & Design", keywords: ["design", "animation", "haptic", "liquid", "glass", "darstellung"], section: "Design", destination: .ui),
            .init(id: "data", title: "Daten verwalten", keywords: ["export", "import", "backup", "reset", "zurücksetzen"], section: "Daten", destination: .data),
            .init(id: "profile", title: "Profil & Konto", keywords: ["profil", "konto", "name", "account"], section: "Profil & Konto", destination: .profile)
        ]
    }

    private var searchResults: [SettingsSearchItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return catalog.filter { item in
            item.title.lowercased().contains(q)
                || item.keywords.contains(where: { $0.contains(q) || q.contains($0) })
                || item.section.lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            if !searchText.isEmpty {
                Section("Suchergebnisse") {
                    if searchResults.isEmpty {
                        Text("Keine Einstellungen gefunden.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(searchResults) { item in
                            NavigationLink(value: item.destination) {
                                Label(item.title, systemImage: icon(for: item.destination))
                            }
                        }
                    }
                }
            } else {
                Section {
                    profileSummary
                } header: {
                    Text("Profil & Konto")
                }

                Section("Smart Assistant") {
                    settingsLink(.assistant, title: "Vorschläge & Verhalten", icon: "brain.head.profile")
                    settingsLink(.shortcuts, title: "Shortcuts", icon: "square.grid.2x2.fill")
                }

                Section("Geld & Sparen") {
                    NavigationLink {
                        GoalsView()
                    } label: {
                        Label("Sparziele", systemImage: "target")
                    }
                    settingsLink(.savingsOptions, title: "Sparziel-Optionen", icon: "slider.horizontal.3")
                    settingsLink(.limits, title: "Limits", icon: "gauge.with.dots.needle.67percent")
                    settingsLink(.categories, title: "Kategorien", icon: "tag.fill")
                }

                Section("Benachrichtigungen") {
                    settingsLink(.notifications, title: "Erinnerungen & Warnungen", icon: "bell.badge")
                }

                Section("Design") {
                    settingsLink(.ui, title: "Darstellung & Animationen", icon: "paintbrush")
                    settingsLink(.moneyCard, title: "Money Card & Widget", icon: "creditcard.fill")
                    settingsLink(.map, title: "Geldkarte", icon: "map.fill")
                }

                Section("Daten verwalten") {
                    settingsLink(.data, title: "Exportieren / Importieren", icon: "externaldrive")
                    Button("Alles zurücksetzen", role: .destructive) {
                        HapticService.warning(store: store)
                        showResetConfirm = true
                    }
                }

                Section("Übersicht") {
                    LabeledContent("Buchungen", value: "\(store.accountFilteredTransactions.count)")
                    LabeledContent("Sparziele", value: "\(store.goals.count)")
                    LabeledContent("Login-Serie", value: "\(store.loginReward.loginStreakDays) Tage")
                    LabeledContent("Coins", value: "\(store.loginReward.coins)")
                }
            }
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Einstellungen durchsuchen")
        .navigationDestination(for: SettingsDestination.self) { destination in
            destinationView(destination)
        }
        .alert("Alle Daten löschen?", isPresented: $showResetConfirm) {
            Button("Löschen", role: .destructive) {
                HapticService.error(store: store)
                store.resetAllData()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Buchungen, Ziele, Abos und Einstellungen werden gelöscht. Die App startet wie neu.")
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

    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let account = store.activeAccount {
                LabeledContent("Aktives Konto", value: account.name)
            }
            Picker("Konto", selection: Binding(
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
            NavigationLink(value: SettingsDestination.security) {
                Label("Sicherheit & Privatsphäre", systemImage: "faceid")
            }
            if let profile = store.onboardingProfile {
                LabeledContent("Fokus", value: profile.focusGoal)
            }
            LabeledContent("Finanzprofil", value: AnalyzeMeEngine.analyze(store: store).financeType)
        }
    }

    private func settingsLink(_ destination: SettingsDestination, title: String, icon: String) -> some View {
        NavigationLink(value: destination) {
            Label(title, systemImage: icon)
        }
        .simultaneousGesture(TapGesture().onEnded {
            HapticService.navigate(store: store)
        })
    }

    @ViewBuilder
    private func destinationView(_ destination: SettingsDestination) -> some View {
        switch destination {
        case .assistant: AssistantSettingsView()
        case .security: SecuritySettingsView()
        case .shortcuts: ShortcutSettingsView()
        case .notifications: NotificationSettingsView()
        case .limits: SpendingLimitsView()
        case .categories: CategoriesSettingsView()
        case .moneyCard: MoneyCardSettingsView()
        case .savings: GoalsView()
        case .savingsOptions: SavingsSettingsView()
        case .map: MapSettingsView()
        case .ui: UISettingsView()
        case .data: DataManagementSettingsView()
        case .profile:
            List { profileSummary }
                .navigationTitle("Profil & Konto")
        }
    }

    private func icon(for destination: SettingsDestination) -> String {
        switch destination {
        case .assistant: return "brain.head.profile"
        case .security: return "faceid"
        case .shortcuts: return "square.grid.2x2.fill"
        case .notifications: return "bell.badge"
        case .limits: return "gauge.with.dots.needle.67percent"
        case .categories: return "tag.fill"
        case .moneyCard: return "creditcard.fill"
        case .savings: return "target"
        case .savingsOptions: return "slider.horizontal.3"
        case .map: return "map.fill"
        case .ui: return "paintbrush"
        case .data: return "externaldrive"
        case .profile: return "person.crop.circle"
        }
    }
}
