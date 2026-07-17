import SwiftUI

/// Liquid-glass daily login celebration — flame + coin award.
struct DailyLoginRewardOverlay: View {
    let result: DailyLoginClaimResult
    let onDismiss: () -> Void

    @State private var flameScale: CGFloat = 0.2
    @State private var flameOpacity: Double = 0
    @State private var coinOffset: CGFloat = 40
    @State private var coinOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var coinSpin: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(0.35),
                                    Color.orange.opacity(0.08),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(flameScale)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, Color(red: 0.95, green: 0.35, blue: 0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(flameScale)
                        .opacity(flameOpacity)
                        .shadow(color: .orange.opacity(0.45), radius: 18, y: 4)
                        .symbolEffect(.pulse, options: .repeating.speed(0.55), value: flameOpacity)
                }

                VStack(spacing: 8) {
                    Text("Täglicher Check-in")
                        .font(LiveCashTheme.headlineFont)
                    Text(streakLabel)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                .opacity(contentOpacity)

                HStack(spacing: 10) {
                    Image(systemName: "circle.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        )
                        .rotationEffect(.degrees(coinSpin))
                    Text("+\(result.coinsAwarded) Coin")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text("· \(result.totalCoins) gesamt")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(LiveCashTheme.glassBorder, lineWidth: 0.8)
                )
                .offset(y: coinOffset)
                .opacity(coinOpacity)

                Button("Weiter") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(LiveCashTheme.accent)
                    .opacity(contentOpacity)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, y: 12)
            .padding(.horizontal, 32)
        }
        .onAppear { animateIn() }
    }

    private var streakLabel: String {
        if result.streakDays >= 30 {
            return "\(result.streakDays) Tage Serie — starke Disziplin"
        }
        if result.streakDays >= 7 {
            return "\(result.streakDays) Tage Serie — weiter so"
        }
        return "\(result.streakDays) Tag\(result.streakDays == 1 ? "" : "e") Login-Serie"
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
            flameScale = 1
            flameOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.18)) {
            coinOffset = 0
            coinOpacity = 1
            coinSpin = 360
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
            contentOpacity = 1
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            flameOpacity = 0
            coinOpacity = 0
            contentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}
