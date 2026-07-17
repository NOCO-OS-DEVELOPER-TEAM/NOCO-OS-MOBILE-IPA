import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var navigateToGoals = false
    @State private var navigateToSubscriptions = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            List {
                Section("Finanzen") {
                    moreLink("Smart Assistant", icon: "brain.head.profile") { SmartAssistantHubView() }
                    moreLink("Sparziele", icon: "target") { GoalsView() }
                    moreLink("Abonnements", icon: "repeat.circle") { SubscriptionsView() }
                    moreLink("Zukunfts-Simulation", icon: "chart.line.uptrend.xyaxis") { FutureSimulationView() }
                    moreLink("Ausgaben-Limits", icon: "gauge.with.dots.needle.67percent") { SpendingLimitsView() }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Section("Insights") {
                    moreLink("Mein Finanzbericht", icon: "doc.text.magnifyingglass") { FinanceReportView() }
                    moreLink("Analyse", icon: "chart.xyaxis.line") { AnalyticsCenterView() }
                    moreLink("Analyze Me", icon: "person.crop.circle.badge.questionmark") { AnalyzeMeView() }
                    moreLink("Kalender", icon: "calendar") { FinanceCalendarView() }
                    moreLink("Financial Story", icon: "sparkles.rectangle.stack") { FinancialStoryView() }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

                Section("App") {
                    moreLink("Einstellungen", icon: "gearshape") { SettingsView() }
                    moreLink("Datenschutz & Vertrauen", icon: "lock.shield") { PrivacyTrustView() }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

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
                .opacity(appeared ? 1 : 0)
            }
            .navigationTitle("Mehr")
            .onAppear {
                withAnimation(LiveCashMotion.appearEase) {
                    appeared = true
                }
            }
            .onChange(of: store.pendingMoreDestination) { _, destination in
                guard let destination else { return }
                HapticService.navigate(store: store)
                switch destination {
                case .goals: navigateToGoals = true
                case .subscriptions: navigateToSubscriptions = true
                }
                store.pendingMoreDestination = nil
            }
            .navigationDestination(isPresented: $navigateToGoals) {
                GoalsView()
            }
            .navigationDestination(isPresented: $navigateToSubscriptions) {
                SubscriptionsView()
            }
        }
        .id(store.moreNavigationEpoch)
    }

    private func moreLink<Destination: View>(
        _ title: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            Label(title, systemImage: icon)
        }
        .simultaneousGesture(TapGesture().onEnded {
            HapticService.navigate(store: store)
        })
    }
}
