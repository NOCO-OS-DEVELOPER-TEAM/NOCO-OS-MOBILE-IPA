import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView()
                .tabItem {
                    Label("Start", systemImage: "house.fill")
                }
                .tag(0)

            AppsTabView()
                .tabItem {
                    Label("Sperren", systemImage: "lock.app.dashed.fill")
                }
                .tag(1)

            MoreTabView()
                .tabItem {
                    Label("iOS", systemImage: "square.grid.2x2.fill")
                }
                .tag(2)
        }
        .tint(NOCOTheme.teal)
    }
}
