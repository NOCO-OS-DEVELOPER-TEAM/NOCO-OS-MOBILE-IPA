import SwiftUI

struct InputTypeToggle: View {
    let isIncome: Bool
    let action: () -> Void

    private var accent: Color {
        isIncome ? LiveCashTheme.income : LiveCashTheme.expense
    }

    private var accentSoft: Color {
        isIncome ? LiveCashTheme.incomeSoft : LiveCashTheme.expenseSoft
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(accentSoft)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(accent.opacity(0.35), lineWidth: 1)
                    )
                    .scaleEffect(isIncome ? 1.04 : 1)
                Text(isIncome ? "+" : "–")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
            }
        }
        .buttonStyle(PremiumPressStyle(scale: 0.88))
        .accessibilityLabel(isIncome ? "Einnahme" : "Ausgabe")
        .animation(LiveCashMotion.pressSpring, value: isIncome)
    }
}
