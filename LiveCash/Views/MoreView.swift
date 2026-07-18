import SwiftUI

/// Reliable "Mehr" hub — NavigationLink(value:) only, no opacity traps, no competing gestures.
struct MoreView: View {
    @EnvironmentObject private var store: FinanceStore
    var isSelected: Bool = true
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Finanzen") {
                    navRow("Smart Assistant", icon: "brain.head.profile", route: .assistant)
                    navRow("Sparziele", icon: "target", route: .goals)
                    navRow("Abonnements", icon: "repeat.circle", route: .subscriptions)
                    navRow("Zukunfts-Simulation", icon: "chart.line.uptrend.xyaxis", route: .future)
                    navRow("Ausgaben-Limits", icon: "gauge.with.dots.needle.67percent", route: .limits)
                }

                Section("Insights") {
                    navRow("Mein Finanzbericht", icon: "doc.text.magnifyingglass", route: .financeReport)
                    navRow("Analyse", icon: "chart.xyaxis.line", route: .analytics)
                    navRow("Analyze Me", icon: "person.crop.circle.badge.questionmark", route: .analyzeMe)
                    navRow("Kalender", icon: "calendar", route: .calendar)
                    navRow("Financial Story", icon: "sparkles.rectangle.stack", route: .story)
                }

                Section("App") {
                    navRow("Einstellungen", icon: "gearshape", route: .settings)
                    navRow("Datenschutz & Vertrauen", icon: "lock.shield", route: .privacy)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Cash")
                            .font(LiveCashTheme.headlineFont)
                        Text("Adaptives Finanz-Verhaltenssystem — lokal, privat, unter deiner Kontrolle.")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            Text("Version \(version) (\(build))")
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.tertiary)
                        }
                        Text("Designed by Noah Pohlmann")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Mehr")
            .navigationDestination(for: MoreRoute.self) { route in
                destination(for: route)
            }
            .onAppear { pushPendingIfNeeded() }
            .onChange(of: isSelected) { _, on in
                if on { pushPendingIfNeeded() }
            }
            .onChange(of: store.pendingMoreDestination) { _, _ in
                pushPendingIfNeeded()
            }
            .onChange(of: store.moreNavigationEpoch) { _, _ in
                path = NavigationPath()
            }
        }
    }

    private func navRow(_ title: String, icon: String, route: MoreRoute) -> some View {
        NavigationLink(value: route) {
            Label(title, systemImage: icon)
        }
    }

    private func pushPendingIfNeeded() {
        guard let destination = store.pendingMoreDestination else { return }
        store.pendingMoreDestination = nil
        let route: MoreRoute = {
            switch destination {
            case .goals: return .goals
            case .subscriptions: return .subscriptions
            }
        }()
        DispatchQueue.main.async {
            path.append(route)
            HapticService.navigate(store: store)
        }
    }

    @ViewBuilder
    private func destination(for route: MoreRoute) -> some View {
        switch route {
        case .assistant: SmartAssistantHubView()
        case .goals: GoalsView()
        case .subscriptions: SubscriptionsView()
        case .future: FutureSimulationView()
        case .limits: SpendingLimitsView()
        case .financeReport: FinanceReportView()
        case .analytics: AnalyticsCenterView()
        case .analyzeMe: AnalyzeMeView()
        case .calendar: FinanceCalendarView()
        case .story: FinancialStoryView()
        case .settings: SettingsView()
        case .privacy: PrivacyTrustView()
        }
    }
}

enum MoreRoute: Hashable {
    case assistant, goals, subscriptions, future, limits
    case financeReport, analytics, analyzeMe, calendar, story
    case settings, privacy
}
