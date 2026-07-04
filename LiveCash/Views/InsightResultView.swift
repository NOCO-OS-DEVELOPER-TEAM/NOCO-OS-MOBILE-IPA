import SwiftUI

struct InsightResultView: View {
    @EnvironmentObject private var store: FinanceStore
    let insight: FinanceInsight
    var onDismiss: () -> Void

    var body: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(LiveCashTheme.accent)
                    Text(insight.title)
                        .font(LiveCashTheme.headlineFont)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(Array(insight.rows.enumerated()), id: \.offset) { _, row in
                    HStack {
                        Text(row.0)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(row.1)
                            .fontWeight(.medium)
                    }
                    .font(LiveCashTheme.bodyFont)
                }

                if let tip = insight.insight {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(LiveCashTheme.accent)
                        Text(tip)
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.primary.opacity(0.85))
                    }
                    .padding(.top, 4)
                }

                if !insight.followUpActions.isEmpty {
                    Divider().opacity(0.5)
                    Text("Weiter")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(insight.followUpActions, id: \.self) { action in
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    store.showInsight(for: action)
                                }
                            } label: {
                                Text(FinanceAssistant.shared.actionTitle(action))
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(LiveCashTheme.accentSoft)
                                    .foregroundStyle(LiveCashTheme.accent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
