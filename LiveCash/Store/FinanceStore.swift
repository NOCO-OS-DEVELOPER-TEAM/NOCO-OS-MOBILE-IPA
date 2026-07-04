import Foundation
import CoreLocation
import Combine
import UIKit

@MainActor
final class FinanceStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var goals: [SavingsGoal] = []
    @Published private(set) var subscriptions: [Subscription] = []
    @Published var locationEnabled: Bool = false
    @Published var notificationsEnabled: Bool = true
    @Published var savingsStreakDays: Int = 0
    @Published var inputMode: TransactionType = .expense
    @Published var lastFeedback: String?
    @Published var pendingIntent: FinanceIntent?
    @Published var activeInsight: FinanceInsight?
    @Published var assistantHeadline: String = ""
    @Published var assistantActions: [InsightAction] = []
    @Published var liveSuggestions: [LiveSuggestion] = []
    @Published var inputInterpretation: InputInterpretation = .empty
    @Published var pendingConfirmation: PendingConfirmation?
    @Published var pendingShakeUndo: PendingShakeUndo?
    @Published var pendingSpendLimit: PendingSpendLimit?
    @Published var shortcuts: [QuickShortcut] = []
    @Published var spendingLimits: SpendingLimits = .default
    @Published var focusInputOnAppear = false
    @Published var pendingQuickAction: LiveCashQuickAction?
    @Published var accounts: [FinanceAccount] = []
    @Published var activeAccountId: UUID?
    @Published var notificationPreferences = NotificationPreferences()
    @Published var notificationLearning = NotificationLearning()
    @Published var assistantModePreference: AssistantMode = .suggestion
    @Published var currentAssistantMode: AssistantMode = .suggestion
    @Published var pendingTabSelection: Int?
    @Published var pendingScanImage: UIImage?
    @Published var showInputSourceSheet = false

    private let persistence = PersistenceService.shared
    private let locationManager = CLLocationManager()
    private var lastActiveDate: Date?

    init() {
        let data = persistence.load()
        transactions = data.transactions.sorted { $0.date > $1.date }
        goals = data.goals
        subscriptions = data.subscriptions
        locationEnabled = data.locationEnabled
        savingsStreakDays = data.savingsStreakDays
        lastActiveDate = data.lastActiveDate
        notificationsEnabled = data.notificationsEnabled
        shortcuts = data.shortcuts
        spendingLimits = data.spendingLimits
        accounts = data.accounts
        activeAccountId = data.activeAccountId
        notificationPreferences = data.notificationPreferences
        notificationLearning = data.notificationLearning
        assistantModePreference = data.assistantModePreference
        migrateLegacyAccountIds()
        refreshSubscriptions()
        refreshShortcuts()
        persist()
        WidgetDataSync.writeSnapshot(from: self)
        NotificationService.shared.refreshNotifications(for: self, enabled: notificationsEnabled)
    }

    func onAppBecameActive() {
        let data = persistence.load()
        if data.transactions.count > transactions.count {
            transactions = data.transactions.sorted { $0.date > $1.date }
            goals = data.goals
            subscriptions = data.subscriptions
            refreshSubscriptions()
        }
        WidgetDataSync.writeSnapshot(from: self)
        NotificationService.shared.refreshNotifications(for: self, enabled: notificationsEnabled)
    }

    func toggleInputMode() {
        inputMode = inputMode == .expense ? .income : .expense
    }

    // MARK: - Transactions

    func addTransaction(_ transaction: Transaction) {
        var tx = transaction
        if locationEnabled, tx.location == nil, let loc = locationManager.location {
            tx.location = TransactionLocation(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                label: "Aktueller Standort"
            )
        }
        tx.accountId = activeAccountId ?? accounts.first(where: \.isDefault)?.id
        transactions.insert(tx, at: 0)
        let hour = Calendar.current.component(.hour, from: Date())
        NotificationBehaviorEngine.recordLoggingHour(hour, learning: &notificationLearning)
        recordDailyActivity()
        refreshSubscriptions()
        refreshShortcuts()
        persist()
        NotificationService.shared.notifyTransactionAdded(tx, store: self)
        NotificationService.shared.refreshNotifications(for: self, enabled: notificationsEnabled)
    }

    func addTransactions(_ items: [Transaction]) {
        for var tx in items {
            if locationEnabled, tx.location == nil, let loc = locationManager.location {
                tx.location = TransactionLocation(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude,
                    label: "Aktueller Standort"
                )
            }
            tx.accountId = activeAccountId ?? accounts.first(where: \.isDefault)?.id
            transactions.insert(tx, at: 0)
            NotificationService.shared.notifyTransactionAdded(tx, store: self)
        }
        recordDailyActivity()
        refreshSubscriptions()
        refreshShortcuts()
        persist()
        NotificationService.shared.refreshNotifications(for: self, enabled: notificationsEnabled)
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        persist()
        refreshSubscriptions()
    }

    func updateTransaction(_ transaction: Transaction) {
        guard let idx = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        transactions[idx] = transaction
        transactions.sort { $0.date > $1.date }
        persist()
        refreshSubscriptions()
    }

    func updateLiveIntelligence(for partial: String) {
        liveSuggestions = LiveIntelligenceEngine.shared.liveSuggestions(for: partial, store: self)
        inputInterpretation = LiveIntelligenceEngine.shared.interpret(partial, preferredType: inputMode)
    }

    func clearLiveIntelligence() {
        liveSuggestions = []
        inputInterpretation = .empty
    }

    func applyLiveSuggestion(_ suggestion: LiveSuggestion) {
        switch suggestion.action {
        case .submitText(let text):
            processInput(text)
        case .insight(let action):
            pendingConfirmation = nil
            showInsight(for: action)
        case .saveDraft(var draft):
            SmartInputParser.shared.applyPreferredType(inputMode, to: &draft, text: "")
            saveDraft(draft, rawInput: nil)
        case .addSubscription(let name):
            if subscriptions.contains(where: { $0.name.lowercased() == name.lowercased() }) {
                showInsight(for: .monthlySubCost)
            } else {
                addSubscription(name: name, amount: 9.99, frequency: .monthly)
                lastFeedback = "Abo \(name) hinzugefügt"
            }
        }
    }

    func confirmAsExpense() {
        guard var c = pendingConfirmation else { return }
        c.draft.type = .expense
        if c.draft.category == .income { c.draft.category = .other }
        saveDraft(c.draft, rawInput: c.rawInput)
    }

    func confirmAsIncome() {
        guard var c = pendingConfirmation else { return }
        c.draft.type = .income
        c.draft.category = .income
        saveDraft(c.draft, rawInput: c.rawInput)
    }

    func cancelConfirmation() {
        pendingConfirmation = nil
    }

    func confirmWithOption(_ option: ConfirmationOption) {
        guard let c = pendingConfirmation else { return }
        saveDraft(option.draft, rawInput: c.rawInput)
    }

    func handleDeviceShake() {
        guard let tx = accountFilteredTransactions.first else { return }
        pendingShakeUndo = PendingShakeUndo(transaction: tx)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func confirmShakeUndo() {
        guard let pending = pendingShakeUndo else { return }
        deleteTransaction(pending.transaction)
        lastFeedback = "Rückgängig: \(pending.transaction.merchant)"
        pendingShakeUndo = nil
        WidgetDataSync.writeSnapshot(from: self)
    }

    func cancelShakeUndo() {
        pendingShakeUndo = nil
    }

    func ensureLocationForMap() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func confirmSpendLimit() {
        guard let pending = pendingSpendLimit else { return }
        pendingSpendLimit = nil
        commitDraft(pending.draft, rawInput: pending.rawInput)
    }

    func cancelSpendLimit() {
        pendingSpendLimit = nil
    }

    func saveDraft(_ draft: ParsedTransactionDraft, rawInput: String?) {
        var resolved = draft
        if let raw = rawInput {
            SmartInputParser.shared.applyPreferredType(inputMode, to: &resolved, text: raw)
        }
        if resolved.type == .expense, let message = spendLimitExceededMessage(adding: resolved.amount) {
            pendingSpendLimit = PendingSpendLimit(draft: resolved, rawInput: rawInput, message: message)
            return
        }
        commitDraft(resolved, rawInput: rawInput)
    }

    private func commitDraft(_ resolved: ParsedTransactionDraft, rawInput: String?) {
        let tx = Transaction(
            amount: resolved.amount,
            type: resolved.type,
            category: resolved.category,
            merchant: resolved.merchant,
            date: resolved.date,
            rawInput: rawInput,
            accountId: activeAccountId
        )
        addTransaction(tx)
        let sign = resolved.type == .income ? "+" : "-"
        lastFeedback = String(format: "Hinzugefügt: %@ %@%.2f€ (%@)", resolved.merchant, sign, resolved.amount, resolved.category.rawValue)
        pendingConfirmation = nil
        pendingSpendLimit = nil
        activeInsight = nil
        pendingIntent = nil
    }

    func processInput(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.contains("\n") || trimmed.count > 80 {
            let bulk = SmartInputParser.shared.parseBulk(trimmed)
            if !bulk.isEmpty {
                addTransactions(bulk)
                lastFeedback = "\(bulk.count) Transaktionen erkannt"
                pendingIntent = nil
                activeInsight = nil
                return
            }
        }

        if var draft = SmartInputParser.shared.parseSingle(trimmed),
           SmartInputParser.shared.looksLikeTransaction(trimmed) || SmartInputParser.shared.containsAmount(trimmed) {
            SmartInputParser.shared.applyPreferredType(inputMode, to: &draft, text: trimmed)
            let engine = LiveIntelligenceEngine.shared
            let confidence = engine.classifyInputConfidence(trimmed, draft: draft, preferredType: inputMode)
            switch confidence {
            case .safe:
                saveDraft(draft, rawInput: trimmed)
            case .uncertain:
                pendingConfirmation = PendingConfirmation(
                    draft: draft,
                    rawInput: trimmed,
                    message: engine.uncertainMessage(for: draft, text: trimmed),
                    confidence: .uncertain
                )
            case .highRisk:
                pendingConfirmation = PendingConfirmation(
                    draft: draft,
                    rawInput: trimmed,
                    message: "Mehrdeutig — was meinst du?",
                    confidence: .highRisk,
                    options: engine.highRiskOptions(for: draft, text: trimmed)
                )
            }
            pendingIntent = nil
            activeInsight = nil
            return
        }

        if SmartInputParser.shared.isLikelyQuery(trimmed) {
            applyAssistant(FinanceAssistant.shared.respond(to: trimmed, store: self))
            return
        }

        if FinanceAssistant.shared.matchIntent(trimmed) != nil {
            applyAssistant(FinanceAssistant.shared.respond(to: trimmed, store: self))
            return
        }

        applyAssistant(FinanceAssistant.shared.respond(to: trimmed, store: self))
    }

    private func applyAssistant(_ response: AssistantResponse) {
        lastFeedback = nil
        switch response.mode {
        case .directInsight(let insight):
            activeInsight = insight
            pendingIntent = nil
        case .suggestions(let intent, let headline, let actions):
            pendingIntent = intent
            assistantHeadline = headline
            assistantActions = actions
            activeInsight = nil
        }
    }

    func showInsight(for action: InsightAction) {
        if case .openMap = action {
            pendingTabSelection = 2
            pendingIntent = nil
            assistantHeadline = ""
            assistantActions = []
            return
        }
        activeInsight = FinanceAssistant.shared.generateInsight(action: action, store: self)
        pendingIntent = nil
        assistantHeadline = ""
        assistantActions = []
    }

    // MARK: - Goals

    func addGoal(name: String, target: Double) {
        goals.append(SavingsGoal(name: name, targetAmount: target))
        recordDailyActivity()
        persist()
    }

    func updateGoal(_ goal: SavingsGoal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx] = goal
        persist()
    }

    func deleteGoal(_ goal: SavingsGoal) {
        goals.removeAll { $0.id == goal.id }
        persist()
    }

    func addToGoal(_ goal: SavingsGoal, amount: Double) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx].currentAmount += amount
        recordDailyActivity()
        persist()
    }

    // MARK: - Subscriptions

    func refreshSubscriptions() {
        let detected = SubscriptionDetector.shared.detect(from: transactions)
        let manual = subscriptions.filter { !$0.detectedFromTransactions }
        var merged = manual
        for d in detected {
            if !merged.contains(where: { $0.name.lowercased() == d.name.lowercased() }) {
                merged.append(d)
            } else if let idx = merged.firstIndex(where: { $0.name.lowercased() == d.name.lowercased() }) {
                merged[idx].amount = d.amount
                merged[idx].frequency = d.frequency
                merged[idx].detectedFromTransactions = true
                merged[idx].lastSeen = d.lastSeen
            }
        }
        subscriptions = merged.sorted { $0.monthlyCost > $1.monthlyCost }
        persist()
    }

    func addSubscription(name: String, amount: Double, frequency: SubscriptionFrequency) {
        subscriptions.append(Subscription(name: name, amount: amount, frequency: frequency, detectedFromTransactions: false))
        persist()
    }

    func deleteSubscription(_ sub: Subscription) {
        subscriptions.removeAll { $0.id == sub.id }
        persist()
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        persist()
        Task { await NotificationService.shared.requestAuthorizationIfNeeded() }
        NotificationService.shared.refreshNotifications(for: self, enabled: enabled)
    }

    // MARK: - Shortcuts

    func refreshShortcuts() {
        shortcuts = ShortcutGenerator.generate(from: transactions, existing: shortcuts)
    }

    func applyShortcut(_ shortcut: QuickShortcut) {
        switch shortcut.actionType {
        case .assistant:
            focusInputOnAppear = true
            currentAssistantMode = .suggestion
            updateLiveIntelligence(for: "")
            lastFeedback = "Smart Assistant"
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        case .overview:
            showInsight(for: .monthlySummary)
            lastFeedback = "Übersicht"
            return
        case .book:
            break
        }

        let draft = ParsedTransactionDraft(
            amount: shortcut.amount,
            type: shortcut.type,
            merchant: shortcut.merchant,
            category: shortcut.type == .income ? .income : shortcut.category,
            date: Date()
        )
        if shortcut.type == .expense, let message = spendLimitExceededMessage(adding: shortcut.amount) {
            pendingSpendLimit = PendingSpendLimit(draft: draft, rawInput: nil, message: message)
            return
        }
        let tx = Transaction(
            amount: draft.amount,
            type: draft.type,
            category: draft.category,
            merchant: draft.merchant,
            date: draft.date,
            location: shortcut.location
        )
        addTransaction(tx)
        lastFeedback = "Shortcut: \(shortcut.label)"
    }

    func updateShortcut(_ shortcut: QuickShortcut) {
        guard let idx = shortcuts.firstIndex(where: { $0.id == shortcut.id }) else { return }
        shortcuts[idx] = shortcut
        shortcuts.sort { $0.sortOrder < $1.sortOrder }
        persist()
    }

    func setSpendingLimitsEnabled(_ enabled: Bool) {
        spendingLimits.enabled = enabled
        persist()
    }

    func saveSpendingLimits() {
        persist()
    }

    func transactions(inMonth date: Date) -> [Transaction] {
        let cal = Calendar.current
        return accountFilteredTransactions.filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    var accountFilteredTransactions: [Transaction] {
        guard let id = activeAccountId else { return transactions }
        return transactions.filter { $0.accountId == id }
    }

    var activeAccount: FinanceAccount? {
        accounts.first { $0.id == activeAccountId } ?? accounts.first
    }

    func setActiveAccount(_ account: FinanceAccount) {
        activeAccountId = account.id
        persist()
        WidgetDataSync.writeSnapshot(from: self)
    }

    func addAccount(name: String, icon: String = "folder.fill") {
        let account = FinanceAccount(name: name, icon: icon, sortOrder: accounts.count)
        accounts.append(account)
        persist()
    }

    func deleteAccount(_ account: FinanceAccount) {
        guard accounts.count > 1 else { return }
        let fallback = accounts.first { $0.id != account.id }!
        for i in transactions.indices where transactions[i].accountId == account.id {
            transactions[i].accountId = fallback.id
        }
        accounts.removeAll { $0.id == account.id }
        if activeAccountId == account.id {
            activeAccountId = fallback.id
        }
        persist()
    }

    func setNotificationPreferences(_ prefs: NotificationPreferences) {
        notificationPreferences = prefs
        persist()
        NotificationService.shared.refreshNotifications(for: self, enabled: notificationsEnabled)
    }

    func setAssistantModePreference(_ mode: AssistantMode) {
        assistantModePreference = mode
        persist()
        updateLiveIntelligence(for: "")
    }

    func resetAllData() {
        persistence.resetAll()
        let fresh = AppData.empty
        transactions = []
        goals = []
        subscriptions = []
        shortcuts = []
        spendingLimits = .default
        accounts = fresh.accounts
        activeAccountId = fresh.activeAccountId
        notificationPreferences = fresh.notificationPreferences
        notificationLearning = fresh.notificationLearning
        assistantModePreference = fresh.assistantModePreference
        savingsStreakDays = 0
        lastActiveDate = nil
        pendingConfirmation = nil
        pendingShakeUndo = nil
        pendingSpendLimit = nil
        activeInsight = nil
        pendingIntent = nil
        refreshShortcuts()
        persist()
        WidgetDataSync.writeSnapshot(from: self)
        NotificationService.shared.refreshNotifications(for: self, enabled: notificationsEnabled)
    }

    private func migrateLegacyAccountIds() {
        guard let defaultId = accounts.first(where: \.isDefault)?.id ?? accounts.first?.id else { return }
        var changed = false
        for i in transactions.indices where transactions[i].accountId == nil {
            transactions[i].accountId = defaultId
            changed = true
        }
        if changed { persist() }
    }

    // MARK: - Analytics

    var currentMonthExpenses: Double {
        transactions(inMonth: Date()).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var currentMonthIncome: Double {
        transactions(inMonth: Date()).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var currentBalance: Double {
        currentMonthIncome - currentMonthExpenses
    }

    var todayExpenses: Double {
        let cal = Calendar.current
        return accountFilteredTransactions.filter { cal.isDateInToday($0.date) && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var dailyAverageExpenses: Double {
        let cal = Calendar.current
        let monthTx = transactions(inMonth: Date()).filter { $0.type == .expense }
        let day = max(cal.component(.day, from: Date()), 1)
        return monthTx.reduce(0) { $0 + $1.amount } / Double(day)
    }

    var lastTransactionDate: Date? {
        accountFilteredTransactions.first?.date
    }

    var monthlySavingsRate: Double {
        max(currentMonthIncome - currentMonthExpenses, 0)
    }

    var topCategoryThisMonth: (FinanceCategory, Double)? {
        let grouped = Dictionary(grouping: transactions(inMonth: Date()).filter { $0.type == .expense }, by: \.category)
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }.max(by: { $0.1 < $1.1 })
    }

    var monthlySubscriptionCost: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyCost }
    }

    var allTimeBalance: Double {
        accountFilteredTransactions.reduce(0) { $0 + $1.signedAmount }
    }

    var weeklyExpenses: Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return accountFilteredTransactions.filter { $0.date >= start && $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var weeklyIncome: Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return accountFilteredTransactions.filter { $0.date >= start && $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var weeklyNetCashflow: Double {
        weeklyIncome - weeklyExpenses
    }

    func spendLimitExceededMessage(adding amount: Double) -> String? {
        guard spendingLimits.enabled else { return nil }
        if let daily = spendingLimits.dailyLimit {
            let total = todayExpenses + amount
            if total > daily {
                return String(format: "Tageslimit %.0f€ überschritten (%.0f€ mit dieser Buchung).", daily, total)
            }
        }
        if let weekly = spendingLimits.weeklyLimit {
            let total = weeklyExpenses + amount
            if total > weekly {
                return String(format: "Wochenlimit %.0f€ überschritten (%.0f€ gesamt).", weekly, total)
            }
        }
        if let monthly = spendingLimits.monthlyLimit {
            let total = currentMonthExpenses + amount
            if total > monthly {
                return String(format: "Monatslimit %.0f€ überschritten (%.0f€ gesamt).", monthly, total)
            }
        }
        return nil
    }

    func setLocationEnabled(_ enabled: Bool) {
        locationEnabled = enabled
        if enabled {
            locationManager.requestWhenInUseAuthorization()
        }
        persist()
    }

    private func recordDailyActivity() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastActiveDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 {
                savingsStreakDays += 1
            } else if diff > 1 {
                savingsStreakDays = 1
            }
        } else {
            savingsStreakDays = max(savingsStreakDays, 1)
        }
        lastActiveDate = today
    }

    private func persist() {
        persistence.save(AppData(
            transactions: transactions,
            goals: goals,
            subscriptions: subscriptions,
            locationEnabled: locationEnabled,
            savingsStreakDays: savingsStreakDays,
            lastActiveDate: lastActiveDate,
            notificationsEnabled: notificationsEnabled,
            shortcuts: shortcuts,
            spendingLimits: spendingLimits,
            accounts: accounts,
            activeAccountId: activeAccountId,
            notificationPreferences: notificationPreferences,
            assistantModePreference: assistantModePreference,
            notificationLearning: notificationLearning
        ))
        WidgetDataSync.writeSnapshot(from: self)
    }
}
