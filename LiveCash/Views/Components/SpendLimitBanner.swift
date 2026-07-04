import SwiftUI

struct SpendLimitBanner: View {
    let warning: PendingSpendLimit
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        LiveCashGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Limit-Warnung", systemImage: "exclamationmark.triangle.fill")
                    .font(LiveCashTheme.headlineFont)
                    .foregroundStyle(LiveCashTheme.expense)

                Text(warning.message)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button(action: onConfirm) {
                        Text("Trotzdem speichern")
                            .font(LiveCashTheme.captionFont.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(LiveCashTheme.expenseSoft)
                            .foregroundStyle(LiveCashTheme.expense)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onCancel) {
                        Text("Abbrechen")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
