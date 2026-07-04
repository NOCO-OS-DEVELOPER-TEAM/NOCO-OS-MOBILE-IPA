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
                        Text("Lokale Finanzübersicht — keine Bankverbindung, keine Cloud.")
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
