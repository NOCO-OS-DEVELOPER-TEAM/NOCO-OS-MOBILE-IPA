import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView()
                .tabItem {
                    Label("Übersicht", systemImage: "sparkles")
                }
                .tag(0)

            GateTabView()
                .tabItem {
                    Label("Apps", systemImage: "square.grid.3x3.fill")
                }
                .tag(1)

            NavigationStack {
                OneTapSetupView()
            }
            .tabItem {
                Label("Setup", systemImage: "wand.and.stars")
            }
            .tag(2)

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(NOCOTheme.teal)
    }
}
