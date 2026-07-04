import SwiftUI

@main
struct LiveCashApp: App {
    @StateObject private var store = FinanceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
