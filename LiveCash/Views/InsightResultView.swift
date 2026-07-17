import SwiftUI
import Charts

struct InsightResultView: View {
    @EnvironmentObject private var store: FinanceStore
    let insight: FinanceInsight
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(LiveCashTheme.accent)
                Text(insight.title)
                    .font(LiveCashTheme.headlineFont)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    HapticService.soft(store: store)
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.primary.opacity(0.35))
                }
                .buttonStyle(PremiumPressStyle(scale: 0.88))
            }

            if let series = insight.chartSeries, !series.isEmpty, let style = insight.chartStyle {
                chartView(series: series, style: style)
                    .frame(height: style == .donut ? 140 : 110)
                    .padding(.vertical, 4)
                    .appearScale(delay: 0.05)
            }

            ForEach(Array(insight.rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.0)
                        .foregroundStyle(Color.primary.opacity(0.55))
                    Spacer()
                    Text(row.1)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .font(LiveCashTheme.bodyFont)
                .listRowAppear(index: index)
            }

            if let tip = insight.insight {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(LiveCashTheme.accent)
                    Text(tip)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.primary)
                }
                .padding(.top, 2)
            }

            if !insight.followUpActions.isEmpty {
                Divider().opacity(0.35)
                Text("Weiter")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(Color.primary.opacity(0.5))
                FlowLayout(spacing: 6) {
                    ForEach(insight.followUpActions, id: \.self) { action in
                        Button {
                            HapticService.selection(store: store)
                            withAnimation(LiveCashMotion.snappy) {
                                store.showInsight(for: action)
                            }
                        } label: {
                            Text(FinanceAssistant.shared.actionTitle(action))
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(LiveCashTheme.accent.opacity(0.14))
                                .foregroundStyle(LiveCashTheme.accent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PremiumPressStyle(scale: 0.94))
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 0.96))
        ))
        .appearScale()
    }

    @ViewBuilder
    private func chartView(series: [(label: String, value: Double)], style: FinanceInsight.ChartStyle) -> some View {
        switch style {
        case .donut:
            Chart(Array(series.enumerated()), id: \.offset) { _, item in
                SectorMark(
                    angle: .value("Wert", item.value),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.2
                )
                .foregroundStyle(by: .value("Label", item.label))
            }
            .chartLegend(position: .bottom, spacing: 4)
        case .bar:
            Chart(Array(series.enumerated()), id: \.offset) { _, item in
                BarMark(
                    x: .value("Label", item.label),
                    y: .value("Wert", item.value)
                )
                .foregroundStyle(LiveCashTheme.accent.gradient)
                .cornerRadius(6)
            }
            .chartXAxis(.hidden)
        case .line:
            Chart(Array(series.enumerated()), id: \.offset) { idx, item in
                LineMark(
                    x: .value("i", idx),
                    y: .value("Wert", item.value)
                )
                .foregroundStyle(LiveCashTheme.accent)
                PointMark(
                    x: .value("i", idx),
                    y: .value("Wert", item.value)
                )
                .foregroundStyle(LiveCashTheme.income)
            }
            .chartXAxis(.hidden)
        }
    }
}
