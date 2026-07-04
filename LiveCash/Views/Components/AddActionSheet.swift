import SwiftUI

enum AddAction: Identifiable {
    case transaction
    case goalContribution
    case receipt

    var id: String {
        switch self {
        case .transaction: return "transaction"
        case .goalContribution: return "goal"
        case .receipt: return "receipt"
        }
    }
}

struct AddActionSheet: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let onSelect: (AddAction) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                actionRow(
                    title: "Buchung",
                    subtitle: "Ausgabe oder Einnahme",
                    icon: "plus.circle.fill",
                    color: LiveCashTheme.accent
                ) {
                    dismiss()
                    onSelect(.transaction)
                }

                actionRow(
                    title: "Zum Sparziel hinzufügen",
                    subtitle: "Betrag direkt einem Ziel gutschreiben",
                    icon: "target",
                    color: LiveCashTheme.income
                ) {
                    dismiss()
                    onSelect(.goalContribution)
                }

                actionRow(
                    title: "Beleg scannen",
                    subtitle: "Kamera, Galerie oder PDF",
                    icon: "doc.viewfinder",
                    color: LiveCashTheme.expense
                ) {
                    dismiss()
                    onSelect(.receipt)
                }

                Spacer()
            }
            .padding(20)
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func actionRow(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LiveCashTheme.headlineFont)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
