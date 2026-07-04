import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var accentColor: Color {
        transaction.type == .income ? LiveCashTheme.income : LiveCashTheme.expense
    }

    private var accentSoft: Color {
        transaction.type == .income ? LiveCashTheme.incomeSoft : LiveCashTheme.expenseSoft
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: transaction.category.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(width: 40, height: 40)
                .background(accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(LiveCashTheme.headlineFont)
                HStack(spacing: 6) {
                    Text(transaction.type == .income ? "Einnahme" : "Ausgabe")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentSoft)
                        .foregroundStyle(accentColor)
                        .clipShape(Capsule())
                    Text(transaction.category.rawValue)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(accentColor)
                Text(transaction.date, style: .date)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accentSoft, lineWidth: 1)
        )
    }
}
