import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var navigateToGoals = false
    @State private var navigateToSubscriptions = false

    var body: some View {
        NavigationStack {
            List {
                Section("Finanzen") {
                    NavigationLink {
                        GoalsView()
                    } label: {
                        Label("Sparziele", systemImage: "target")
                    }
                    NavigationLink {
                        SubscriptionsView()
                    } label: {
                        Label("Abonnements", systemImage: "repeat.circle")
                    }
                    NavigationLink {
                        FutureSimulationView()
                    } label: {
                        Label("Zukunfts-Simulation", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    NavigationLink {
                        SpendingLimitsView()
                    } label: {
                        Label("Ausgaben-Limits", systemImage: "gauge.with.dots.needle.67percent")
                    }
                }

                Section("Insights") {
                    NavigationLink {
                        FinancialStoryView()
                    } label: {
                        Label("Financial Story", systemImage: "sparkles.rectangle.stack")
                    }
                }

                Section("App") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Einstellungen", systemImage: "gearshape")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Cash")
                            .font(LiveCashTheme.headlineFont)
                        Text("Adaptives Finanz-Verhaltenssystem — lokal, privat, unter deiner Kontrolle.")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Mehr")
            .onChange(of: store.pendingMoreDestination) { _, destination in
                guard let destination else { return }
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
    }
}
