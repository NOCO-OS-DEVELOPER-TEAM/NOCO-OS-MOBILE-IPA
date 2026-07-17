import SwiftUI

struct LiveSuggestionsView: View {
    let suggestions: [LiveSuggestion]
    var mode: AssistantMode = .suggestion
    let onSelect: (LiveSuggestion) -> Void

    private var limit: Int { 3 }

    private var header: String {
        switch mode {
        case .input: return "Schnell speichern"
        case .question: return "Passende Fragen"
        case .suggestion: return "Vorschläge"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.55))

            ForEach(suggestions.prefix(limit)) { suggestion in
                Button {
                    onSelect(suggestion)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: mode == .input ? "checkmark.circle.fill" : "text.bubble.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LiveCashTheme.accent)
                            .padding(.top, 2)
                        Text(suggestion.title)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeOut(duration: 0.15), value: suggestions.map(\.id))
    }
}

struct InterpretationChip: View {
    let interpretation: InputInterpretation

    private var indicatorColor: Color {
        switch interpretation.confidence {
        case .safe: return LiveCashTheme.accent
        case .uncertain: return .orange
        case .highRisk: return LiveCashTheme.expense
        }
    }

    var body: some View {
        if let hint = interpretation.hint {
            HStack(spacing: 6) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 6, height: 6)
                Text(hint)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                if let amount = interpretation.amount {
                    Text(String(format: "%.2f€", amount))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(interpretation.type == .income ? LiveCashTheme.income : LiveCashTheme.expense)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct ConfirmationBanner: View {
    let confirmation: PendingConfirmation
    var onExpense: () -> Void
    var onIncome: () -> Void
    var onOption: ((ConfirmationOption) -> Void)?
    var onCancel: () -> Void

    var body: some View {
        LiveCashGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(confirmation.message)
                    .font(LiveCashTheme.headlineFont)
                    .foregroundStyle(.primary)

                Text(detailLine)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(Color.primary.opacity(0.55))

                if confirmation.confidence == .highRisk, !confirmation.options.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(confirmation.options) { option in
                            Button {
                                onOption?(option)
                            } label: {
                                Text(option.title)
                                    .font(LiveCashTheme.captionFont.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(LiveCashTheme.accentSoft)
                                    .foregroundStyle(LiveCashTheme.accent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Button(action: onExpense) {
                            Text("Ausgabe")
                                .font(LiveCashTheme.captionFont.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(LiveCashTheme.expenseSoft)
                                .foregroundStyle(LiveCashTheme.expense)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onIncome) {
                            Text("Einnahme")
                                .font(LiveCashTheme.captionFont.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(LiveCashTheme.incomeSoft)
                                .foregroundStyle(LiveCashTheme.income)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(action: onCancel) {
                    Text("Abbrechen")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(Color.primary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var detailLine: String {
        let sign = confirmation.draft.type == .income ? "+" : "-"
        return "\(confirmation.draft.merchant) · \(sign)\(String(format: "%.2f€", confirmation.draft.amount))"
    }
}
