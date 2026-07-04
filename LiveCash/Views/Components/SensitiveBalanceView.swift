import SwiftUI

struct SensitiveBalanceView<Content: View>: View {
    @EnvironmentObject private var store: FinanceStore
    @ObservedObject private var security = SecurityService.shared
    let scope: BalanceBlurScope
    @ViewBuilder let content: () -> Content

    enum BalanceBlurScope {
        case home
        case anywhere
    }

    private var shouldMask: Bool {
        let mode = store.appSettings.security.balanceBlurMode
        switch mode {
        case .never: return false
        case .always: return !security.balanceRevealed
        case .homeOnly:
            guard scope == .home else { return false }
            return !security.balanceRevealed
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            content()
                .blur(radius: shouldMask ? 10 : 0)
                .opacity(shouldMask ? 0.25 : 1)
            if shouldMask {
                Text("••••••")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await security.revealBalance(settings: store.appSettings.security)
                HapticService.light(store: store)
            }
        }
    }
}
