import Foundation
import CoreLocation
import Combine

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
    @Published var focusInputOnAppear = false
    @Published var pendingQuickAction: LiveCashQuickAction?

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
        refreshSubscriptions()
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            inputMode = inputMode == .expense ? .income : .expense
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        transactions.insert(tx, at: 0)
        recordDailyActivity()
        persist()
        refreshSubscriptions()
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
            transactions.insert(tx, at: 0)
        }
        recordDailyActivity()
        persist()
        refreshSubscriptions()
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

    func saveDraft(_ draft: ParsedTransactionDraft, rawInput: String?) {
        var resolved = draft
        if let raw = rawInput {
            SmartInputParser.shared.applyPreferredType(inputMode, to: &resolved, text: raw)
        }
        let tx = Transaction(
            amount: resolved.amount,
            type: resolved.type,
            category: resolved.category,
            merchant: resolved.merchant,
            date: resolved.date,
            rawInput: rawInput
        )
        addTransaction(tx)
        let sign = resolved.type == .income ? "+" : "-"
        lastFeedback = String(format: "Hinzugefügt: %@ %@%.2f€ (%@)", resolved.merchant, sign, resolved.amount, resolved.category.rawValue)
        pendingConfirmation = nil
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
            if LiveIntelligenceEngine.shared.isUncertainInput(trimmed, draft: draft, preferredType: inputMode) {
                pendingConfirmation = PendingConfirmation(
                    draft: draft,
                    rawInput: trimmed,
                    message: "Ist das eine Ausgabe oder Einnahme?"
                )
                pendingIntent = nil
                activeInsight = nil
                return
            }
            saveDraft(draft, rawInput: trimmed)
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

    // MARK: - Analytics

    func transactions(inMonth date: Date) -> [Transaction] {
        let cal = Calendar.current
        return transactions.filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

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
        return transactions.filter { cal.isDateInToday($0.date) && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var dailyAverageExpenses: Double {
        let cal = Calendar.current
        let monthTx = transactions(inMonth: Date()).filter { $0.type == .expense }
        let day = max(cal.component(.day, from: Date()), 1)
        return monthTx.reduce(0) { $0 + $1.amount } / Double(day)
    }

    var lastTransactionDate: Date? {
        transactions.first?.date
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
            notificationsEnabled: notificationsEnabled
        ))
        WidgetDataSync.writeSnapshot(from: self)
    }
}
