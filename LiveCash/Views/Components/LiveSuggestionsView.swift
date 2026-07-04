import SwiftUI

struct LiveSuggestionsView: View {
    let suggestions: [LiveSuggestion]
    var mode: AssistantMode = .suggestion
    let onSelect: (LiveSuggestion) -> Void

    private var limit: Int { 3 }

    private var header: String {
        switch mode {
        case .input: return "Schnell speichern"
        case .question: return "Antworten"
        case .suggestion: return "Fertige Fragen"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(LiveCashTheme.accent)
                Text(header)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            ForEach(suggestions.prefix(limit)) { suggestion in
                Button {
                    onSelect(suggestion)
                } label: {
                    HStack {
                        Text(suggestion.title)
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(LiveCashTheme.accent.opacity(0.7))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(LiveCashTheme.glassBorder, lineWidth: 0.5)
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
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                if let amount = interpretation.amount {
                    Text(String(format: "%.2f€", amount))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(interpretation.type == .income ? LiveCashTheme.income : LiveCashTheme.expense)
                }
            }
            .foregroundStyle(interpretation.confidence == .safe ? .secondary : indicatorColor)
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

                Text(detailLine)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)

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
                        .foregroundStyle(.secondary)
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
