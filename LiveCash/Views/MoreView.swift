import SwiftUI

struct MoreView: View {
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
                        Text("Lokale Finanzintelligenz — keine Bank, keine Cloud, kein Chatbot.")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Mehr")
        }
    }
}
