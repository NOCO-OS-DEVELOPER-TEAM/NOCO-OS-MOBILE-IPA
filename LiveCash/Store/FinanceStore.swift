import Foundation
import CoreLocation
import Combine

@MainActor
final class FinanceStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var goals: [SavingsGoal] = []
    @Published private(set) var subscriptions: [Subscription] = []
    @Published var locationEnabled: Bool = false
    @Published var lastFeedback: String?
    @Published var pendingIntent: FinanceIntent?
    @Published var activeInsight: FinanceInsight?
    @Published var assistantHeadline: String = ""
    @Published var assistantActions: [InsightAction] = []

    private let persistence = PersistenceService.shared
    private let locationManager = CLLocationManager()

    init() {
        let data = persistence.load()
        transactions = data.transactions.sorted { $0.date > $1.date }
        goals = data.goals
        subscriptions = data.subscriptions
        locationEnabled = data.locationEnabled
        refreshSubscriptions()
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
        persist()
        refreshSubscriptions()
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        persist()
        refreshSubscriptions()
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

        if SmartInputParser.shared.isLikelyQuery(trimmed) {
            applyAssistant(FinanceAssistant.shared.respond(to: trimmed, store: self))
            return
        }

        if let draft = SmartInputParser.shared.parseSingle(trimmed) {
            let tx = Transaction(
                amount: draft.amount,
                type: draft.type,
                category: draft.category,
                merchant: draft.merchant,
                date: draft.date,
                rawInput: trimmed
            )
            addTransaction(tx)
            let sign = draft.type == .income ? "+" : "-"
            lastFeedback = String(format: "Hinzugefügt: %@ %@%.2f€ (%@)", draft.merchant, sign, draft.amount, draft.category.rawValue)
            pendingIntent = nil
            activeInsight = nil
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

    private func persist() {
        persistence.save(AppData(
            transactions: transactions,
            goals: goals,
            subscriptions: subscriptions,
            locationEnabled: locationEnabled
        ))
    }
}
