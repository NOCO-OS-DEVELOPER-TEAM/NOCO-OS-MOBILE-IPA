import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var settings: AppSettings
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

            OneTapSetupView(embeddedInTab: true, onSwitchToAppsTab: {
                selectedTab = 1
            })
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
        .onChange(of: selectedTab) { old, new in
            if old != new {
                settings.selection()
            }
        }
        .onChange(of: store.openSetupTab) { _, open in
            if open {
                selectedTab = 2
                store.openSetupTab = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .timePayQuickAction)) { note in
            if note.object as? String == TimePayQuickAction.setup {
                selectedTab = 2
            }
        }
        .onAppear {
            configureGlassTabBar()
        }
    }

    private func configureGlassTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(NOCOTheme.midnight).withAlphaComponent(0.55)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
