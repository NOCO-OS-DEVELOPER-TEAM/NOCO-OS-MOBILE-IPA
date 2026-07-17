import SwiftUI

/// Counts money up on appear — used sparingly for premium feel.
struct AnimatedMoneyText: View {
    let value: Double
    var font: Font = .system(size: 52, weight: .bold, design: .rounded)
    var color: Color = LiveCashTheme.income
    var prefix: String = ""
    var decimals: Int = 2

    @State private var displayed: Double = 0

    var body: some View {
        Text(formatted(displayed))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear {
                displayed = 0
                withAnimation(.easeOut(duration: 0.85)) {
                    displayed = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.45)) {
                    displayed = newValue
                }
            }
    }

    private func formatted(_ v: Double) -> String {
        let sign = v >= 0 ? prefix : ""
        return String(format: "%@%.\(decimals)f€", sign, v)
    }
}

struct PulsingFlameLabel: View {
    let days: Int
    @State private var pulse = false

    var body: some View {
        Label("\(days)", systemImage: "flame.fill")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.orange)
            .scaleEffect(pulse ? 1.08 : 1.0)
            .opacity(pulse ? 1 : 0.88)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

struct SpinningCoinLabel: View {
    let coins: Int
    @State private var spin = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.circle.fill")
                .rotationEffect(.degrees(spin ? 360 : 0))
                .foregroundStyle(.yellow)
            Text("\(coins)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.yellow)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                spin = true
            }
        }
    }
}

struct LiveCashEmptyState: View {
    var title: String
    var message: String
    var systemImage: String = "sparkles"
    var primaryActionTitle: String? = nil
    var primaryAction: (() -> Void)? = nil
    var secondaryActionTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(LiveCashTheme.accent)
                .symbolEffect(.pulse, options: .repeating.speed(0.4))

            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let primaryActionTitle, let primaryAction {
                Button(primaryActionTitle, action: primaryAction)
                    .buttonStyle(.borderedProminent)
                    .tint(LiveCashTheme.accent)
            }
            if let secondaryActionTitle, let secondaryAction {
                Button(secondaryActionTitle, action: secondaryAction)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}
