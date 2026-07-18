import SwiftUI

// MARK: - Binding Helpers

private extension FinanceStore {
    func assistantBinding<T>(_ keyPath: WritableKeyPath<AssistantSettings, T>) -> Binding<T> {
        Binding(
            get: { self.appSettings.assistant[keyPath: keyPath] },
            set: { newValue in
                var settings = self.appSettings
                settings.assistant[keyPath: keyPath] = newValue
                self.setAppSettings(settings)
            }
        )
    }

    func securityBinding<T>(_ keyPath: WritableKeyPath<SecuritySettings, T>) -> Binding<T> {
        Binding(
            get: { self.appSettings.security[keyPath: keyPath] },
            set: { newValue in
                var settings = self.appSettings
                settings.security[keyPath: keyPath] = newValue
                self.setAppSettings(settings)
            }
        )
    }

    func mapBinding<T>(_ keyPath: WritableKeyPath<MapSettings, T>) -> Binding<T> {
        Binding(
            get: { self.appSettings.map[keyPath: keyPath] },
            set: { newValue in
                var settings = self.appSettings
                settings.map[keyPath: keyPath] = newValue
                self.setAppSettings(settings)
            }
        )
    }

    func savingsBinding<T>(_ keyPath: WritableKeyPath<SavingsSettings, T>) -> Binding<T> {
        Binding(
            get: { self.appSettings.savings[keyPath: keyPath] },
            set: { newValue in
                var settings = self.appSettings
                settings.savings[keyPath: keyPath] = newValue
                self.setAppSettings(settings)
            }
        )
    }

    func moneyCardBinding<T>(_ keyPath: WritableKeyPath<MoneyCardSettings, T>) -> Binding<T> {
        Binding(
            get: { self.appSettings.moneyCard[keyPath: keyPath] },
            set: { newValue in
                var settings = self.appSettings
                settings.moneyCard[keyPath: keyPath] = newValue
                self.setAppSettings(settings)
            }
        )
    }

    func uiBinding<T>(_ keyPath: WritableKeyPath<UISettings, T>) -> Binding<T> {
        Binding(
            get: { self.appSettings.ui[keyPath: keyPath] },
            set: { newValue in
                var settings = self.appSettings
                settings.ui[keyPath: keyPath] = newValue
                self.setAppSettings(settings)
            }
        )
    }

    func shortcutSettingsBinding<T>(_ keyPath: WritableKeyPath<ShortcutSettings, T>) -> Binding<T> {
        Binding(
            get: { self.appSettings.shortcuts[keyPath: keyPath] },
            set: { newValue in
                var settings = self.appSettings
                settings.shortcuts[keyPath: keyPath] = newValue
                self.setAppSettings(settings)
            }
        )
    }

    func notificationBinding<T>(_ keyPath: WritableKeyPath<NotificationPreferences, T>) -> Binding<T> {
        Binding(
            get: { self.notificationPreferences[keyPath: keyPath] },
            set: { newValue in
                var prefs = self.notificationPreferences
                prefs[keyPath: keyPath] = newValue
                self.setNotificationPreferences(prefs)
            }
        )
    }

    func widgetBinding<T>(_ keyPath: WritableKeyPath<WidgetPreferences, T>) -> Binding<T> {
        Binding(
            get: { self.widgetPreferences[keyPath: keyPath] },
            set: { newValue in
                var prefs = self.widgetPreferences
                prefs[keyPath: keyPath] = newValue
                self.setWidgetPreferences(prefs)
            }
        )
    }
}

// MARK: - Assistant Settings

struct AssistantSettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section {
                Toggle("Live-Vorschläge", isOn: store.assistantBinding(\.suggestionsEnabled))
                Picker("Intensität", selection: store.assistantBinding(\.suggestionIntensity)) {
                    ForEach(SuggestionIntensity.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            } footer: {
                Text("Vorschläge erscheinen nur beim Tippen — nie bei leerem Feld.")
            }

            Section("Rückfragen") {
                Picker("Modus", selection: store.assistantBinding(\.confirmationMode)) {
                    ForEach(ConfirmationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                VStack(alignment: .leading) {
                    Text("Confidence-Schwelle: \(store.appSettings.assistant.confidenceThreshold)%")
                    Slider(
                        value: Binding(
                            get: { Double(store.appSettings.assistant.confidenceThreshold) },
                            set: {
                                var s = store.appSettings
                                s.assistant.confidenceThreshold = Int($0)
                                store.setAppSettings(s)
                                HapticService.selection(store: store)
                            }
                        ),
                        in: 40...95,
                        step: 5
                    )
                }
            }

            Section("Erkennung") {
                Toggle("Einnahme/Ausgabe Auto-Detection", isOn: store.assistantBinding(\.autoDetectIncomeExpense))
                Toggle("Abo-Erkennung", isOn: store.assistantBinding(\.subscriptionDetection))
                Toggle("Mustererkennung", isOn: store.assistantBinding(\.patternDetection))
            }

            Section("Standard-Modus") {
                Picker("Assistant-Modus", selection: Binding(
                    get: { store.assistantModePreference },
                    set: { store.setAssistantModePreference($0) }
                )) {
                    ForEach(AssistantMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
            }
        }
        .navigationTitle("Smart System")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Security Settings

struct SecuritySettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section("Face ID") {
                Toggle("App-Sperre", isOn: store.securityBinding(\.faceIDEnabled))
                if store.appSettings.security.faceIDEnabled {
                    Picker("Wann sperren", selection: store.securityBinding(\.faceIDLockMode)) {
                        ForEach(FaceIDLockMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    if store.appSettings.security.faceIDLockMode == .onInactivity {
                        Stepper(
                            "Inaktivität: \(store.appSettings.security.inactivityLockMinutes) Min.",
                            value: store.securityBinding(\.inactivityLockMinutes),
                            in: 1...30
                        )
                    }
                }
            }

            Section {
                Picker("Blur-Modus", selection: store.securityBinding(\.balanceBlurMode)) {
                    ForEach(BalanceBlurMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                Toggle("Face ID zum Anzeigen", isOn: store.securityBinding(\.requireFaceIDToRevealBalance))
            } footer: {
                Text("Tippe auf den verdeckten Saldo zum kurzen Anzeigen. Beim Verlassen der App wird er wieder verborgen.")
            }
        }
        .navigationTitle("Sicherheit")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shortcut Settings

struct ShortcutSettingsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var editingShortcut: QuickShortcut?

    var body: some View {
        List {
            Section {
                Toggle("Auto-Shortcuts", isOn: store.shortcutSettingsBinding(\.autoShortcutsEnabled))
                Stepper(
                    "Aktive Shortcuts: \(store.appSettings.shortcuts.maxActiveShortcuts)",
                    value: store.shortcutSettingsBinding(\.maxActiveShortcuts),
                    in: 3...6
                )
            } footer: {
                Text("Shortcuts sind nur hier editierbar. Der Start-Tab zeigt sie nur zum Ausführen.")
            }

            Section("Shortcuts") {
                ForEach(store.shortcuts) { shortcut in
                    Button {
                        editingShortcut = shortcut
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(shortcut.merchant)
                                    .foregroundStyle(.primary)
                                Text(shortcut.actionType.label)
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if shortcut.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(LiveCashTheme.accent)
                            }
                            if shortcut.actionType == .book {
                                Text(String(format: "%.0f€", shortcut.amount))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions {
                        Button(shortcut.isPinned ? "Lösen" : "Pinnen") {
                            store.toggleShortcutPin(shortcut)
                        }
                        .tint(LiveCashTheme.accent)
                    }
                }
                .onDelete { idx in
                    idx.map { store.shortcuts[$0] }.forEach(store.deleteShortcut)
                }
                .onMove { source, dest in
                    store.reorderShortcuts(from: source, to: dest)
                }
            }
        }
        .navigationTitle("Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingShortcut = QuickShortcut(merchant: "Neu", amount: 5, isUserDefined: true)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingShortcut) { shortcut in
            ShortcutEditView(shortcut: shortcut)
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section {
                Toggle("Smarte Hinweise", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { store.setNotificationsEnabled($0) }
                ))
            }

            if store.notificationsEnabled {
                Section("Zeitgesteuert") {
                    Toggle("Monatsstart (Gehalt)", isOn: store.notificationBinding(\.monthStartReminder))
                    Toggle("Spar-Reminder Monat", isOn: store.notificationBinding(\.savingsMonthReminder))
                    Toggle("Wöchentliche Erinnerung", isOn: store.notificationBinding(\.weeklyReminder))
                    Toggle("Finanz-Check wöchentlich", isOn: store.notificationBinding(\.financeCheckWeekly))
                }

                Section("Verhalten") {
                    Toggle("Hohe Ausgaben", isOn: store.notificationBinding(\.highSpendingAlerts))
                    Toggle("Ungewöhnliche Aktivität", isOn: store.notificationBinding(\.unusualActivityAlerts))
                    Toggle("Wochentags-Muster", isOn: store.notificationBinding(\.weekdayPatterns))
                    Toggle("Spontan-Ausgaben", isOn: store.notificationBinding(\.spontaneousSpending))
                    Toggle("Abo-Erinnerungen", isOn: store.notificationBinding(\.subscriptionReminders))
                    Toggle("Sparziel-Fortschritt", isOn: store.notificationBinding(\.goalProgressAlerts))
                }

                Section("Sonstiges") {
                    Toggle("Einnahmen-Reaktion", isOn: store.notificationBinding(\.incomeReactions))
                    Toggle("Freundliche Reminder", isOn: store.notificationBinding(\.softEngagement))
                }

                if store.appSettings.assistant.patternDetection {
                    Section("Lernsystem") {
                        LabeledContent("Typische Buchungszeit", value: "\(store.notificationLearning.typicalLogHour):00")
                        LabeledContent("Gelernte Samples", value: "\(store.notificationLearning.logSampleCount)")
                        Text("Das System passt Erinnerungen an dein Verhalten an.")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Benachrichtigungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Money Card Settings

struct MoneyCardSettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section("Anzeige") {
                Picker("Detailstufe", selection: store.moneyCardBinding(\.displayLevel)) {
                    ForEach(MoneyCardDisplayLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                Text("Einnahmen = grün, Ausgaben = rot — feste Konsistenzregel.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Section("Animation") {
                Toggle("Smooth Animations", isOn: store.moneyCardBinding(\.smoothAnimations))
            }

            Section("Widget") {
                Toggle("Kontostand", isOn: store.widgetBinding(\.showBalance))
                Toggle("Ausgaben", isOn: store.widgetBinding(\.showExpenses))
                Toggle("Sparziel", isOn: store.widgetBinding(\.showSavings))
                Toggle("Abo-Kosten", isOn: store.widgetBinding(\.showSubscriptions))
                Toggle("Letzte Ausgabe", isOn: store.widgetBinding(\.showRecentExpense))
                Picker("Update-Intervall", selection: store.widgetBinding(\.refreshIntervalMinutes)) {
                    Text("15 Min").tag(15)
                    Text("30 Min").tag(30)
                    Text("60 Min").tag(60)
                }
                Button("Widgets aktualisieren") {
                    store.refreshWidgets()
                    HapticService.success(store: store)
                }
                .buttonStyle(PremiumPressStyle())
                Text("Schreibt Kontostand, Sparziel, Score, Coins und Wochenbudget neu in die Widgets.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Money Card")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Savings Settings

struct SavingsSettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section("Sparziele") {
                Stepper("Max. Ziele: \(store.appSettings.savings.maxGoals)", value: store.savingsBinding(\.maxGoals), in: 1...10)
                Toggle("Fortschrittsanzeige", isOn: store.savingsBinding(\.showProgress))
            }

            Section("Smart Savings") {
                Toggle("Insights", isOn: store.savingsBinding(\.smartInsightsEnabled))
            }

            Section("Alerts") {
                Toggle("Fortschritt erreicht", isOn: store.savingsBinding(\.progressAlerts))
                Toggle("Ziel fast erreicht", isOn: store.savingsBinding(\.nearGoalAlerts))
                Toggle("Zu langsamer Fortschritt", isOn: store.savingsBinding(\.slowProgressAlerts))
                Toggle("Schnelles Tempo", isOn: store.savingsBinding(\.fastProgressAlerts))
            }

            Section("Live Features") {
                Toggle("Lock Screen Live Activity", isOn: store.savingsBinding(\.liveActivityEnabled))
                Button("Erneut aktivieren") {
                    store.retrySavingsLiveActivity()
                }
                Text("Startet die Sparziel-Live-Activity neu — falls die Anzeige auf dem Sperrbildschirm hängt.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sparziele")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Map Settings

struct MapSettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section("Verhalten") {
                Toggle("Filter beim Öffnen zurücksetzen", isOn: store.mapBinding(\.resetFilterOnOpen))
                Toggle("Zeitverlauf", isOn: store.mapBinding(\.timelineHistoryEnabled))
            }

            Section("Interaktion") {
                Toggle("Pin-Zoom", isOn: store.mapBinding(\.pinZoomEnabled))
                Toggle("Cluster-Modus", isOn: store.mapBinding(\.clusterModeEnabled))
                Picker("Detailstufe", selection: store.mapBinding(\.detailLevel)) {
                    ForEach(MapDetailLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section("Standort") {
                Toggle("Standort bei Buchungen", isOn: Binding(
                    get: { store.locationEnabled },
                    set: { store.setLocationEnabled($0) }
                ))
            }
        }
        .navigationTitle("Geldkarte")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UI Settings

struct UISettingsView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List {
            Section("Darstellung") {
                Picker("Animationen", selection: store.uiBinding(\.animationLevel)) {
                    ForEach(AnimationLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .onChange(of: store.appSettings.ui.animationLevel) { _, _ in
                    HapticService.selection(store: store)
                }
                Toggle("Haptisches Feedback", isOn: store.uiBinding(\.hapticsEnabled))
                    .onChange(of: store.appSettings.ui.hapticsEnabled) { _, enabled in
                        if enabled { HapticService.success(store: store) }
                    }
                Toggle("Compact Mode", isOn: store.uiBinding(\.compactMode))
                    .onChange(of: store.appSettings.ui.compactMode) { _, _ in
                        HapticService.selection(store: store)
                    }
            }
        }
        .navigationTitle("UI & Design")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shortcut Edit (Settings only)

struct ShortcutEditView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State var shortcut: QuickShortcut
    @State private var amountText: String
    @State private var showMapPicker = false
    @State private var lat: Double?
    @State private var lon: Double?
    @State private var locationLabel = ""

    init(shortcut: QuickShortcut) {
        _shortcut = State(initialValue: shortcut)
        _amountText = State(initialValue: String(format: "%.2f", shortcut.amount))
        _lat = State(initialValue: shortcut.location?.latitude)
        _lon = State(initialValue: shortcut.location?.longitude)
        _locationLabel = State(initialValue: shortcut.location?.label ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shortcut") {
                    TextField("Name", text: $shortcut.merchant)
                    if shortcut.actionType == .book {
                        TextField("Betrag", text: $amountText)
                            .keyboardType(.decimalPad)
                        Picker("Typ", selection: $shortcut.type) {
                            Text("Ausgabe").tag(TransactionType.expense)
                            Text("Einnahme").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        Picker("Kategorie", selection: $shortcut.category) {
                            ForEach(FinanceCategory.allCases.filter { cat in
                                shortcut.type == .income ? cat == .income : cat != .income
                            }) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                    }
                    Picker("Aktion", selection: $shortcut.actionType) {
                        ForEach(ShortcutActionType.allCases) { action in
                            Text(action.label).tag(action)
                        }
                    }
                    Toggle("Festpinnen", isOn: $shortcut.isPinned)
                    Picker("Farbe", selection: $shortcut.accent) {
                        ForEach(ShortcutAccent.allCases) { accent in
                            Text(accent.rawValue).tag(accent)
                        }
                    }
                }
                if shortcut.actionType == .book {
                    Section("Standort") {
                        Button("Auf Karte wählen") { showMapPicker = true }
                        if lat != nil {
                            Text(locationLabel.isEmpty ? "Standort gesetzt" : locationLabel)
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Shortcut bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showMapPicker) {
                LocationMapPickerView(latitude: $lat, longitude: $lon, label: $locationLabel)
            }
        }
    }

    private func save() {
        if shortcut.actionType == .book,
           let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) {
            shortcut.amount = abs(amount)
        }
        shortcut.isUserDefined = true
        if shortcut.type == .income { shortcut.category = .income }
        if let lat, let lon {
            shortcut.location = TransactionLocation(latitude: lat, longitude: lon, label: locationLabel)
        } else {
            shortcut.location = nil
        }
        if store.shortcuts.contains(where: { $0.id == shortcut.id }) {
            store.updateShortcut(shortcut)
        } else {
            store.addShortcut(shortcut)
        }
        dismiss()
    }
}
