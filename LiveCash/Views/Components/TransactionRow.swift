import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        LiveCashCard {
            HStack(spacing: 14) {
                Image(systemName: transaction.category.icon)
                    .font(.body)
                    .foregroundStyle(transaction.type == .income ? LiveCashTheme.income : LiveCashTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(LiveCashTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.merchant)
                        .font(LiveCashTheme.headlineFont)
                    Text(transaction.category.rawValue)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(transaction.formattedAmount)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(transaction.type == .income ? LiveCashTheme.income : .primary)
                    Text(transaction.date, style: .date)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
