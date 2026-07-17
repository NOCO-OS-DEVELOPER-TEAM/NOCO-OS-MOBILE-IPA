import SwiftUI
import Charts

/// Spotify-Wrapped-style personal finance report — the wow moment.
struct FinanceReportView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var appearScore: CGFloat = 0
    @State private var selectedSlice: String?
    @State private var chartAppear: CGFloat = 0

    private var analyze: AnalyzeMeReport { AnalyzeMeEngine.analyze(store: store) }
    private var analytics: AnalyticsReport { AnalyticsEngine.report(store: store) }
    private var memory: AssistantMemory { AssistantMemory.build(from: store) }
    private var scenarios: [WhatIfScenario] { FutureSimulationEngine.whatIfScenarios(store: store) }

    private var categorySlices: [AnalyticsCategorySlice] {
        Array(analytics.categorySlices.prefix(8))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero.appearScale(delay: 0)
                    whoAmI.appearFade(delay: 0.08)
                    spending.appearFade(delay: 0.14)
                    monthBars.appearFade(delay: 0.2)
                    strengths.appearFade(delay: 0.26)
                    changes.appearFade(delay: 0.32)
                    forecast.appearFade(delay: 0.38)
                }
                .padding(20)
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Mein Finanzbericht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        HapticService.soft(store: store)
                        dismiss()
                    }
                }
            }
            .onAppear {
                HapticService.soft(store: store)
                withAnimation(LiveCashMotion.softSpring) {
                    appearScore = CGFloat(analyze.score) / 100
                    chartAppear = 1
                }
            }
        }
    }

    private var hero: some View {
        LiveCashCard {
            VStack(spacing: 14) {
                Text("Dein persönlicher Bericht")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
                ZStack {
                    Circle()
                        .stroke(LiveCashTheme.accent.opacity(0.12), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: appearScore)
                        .stroke(LiveCashTheme.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    Text("\(analyze.score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                Text(analyze.financeType)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(analyze.personalityLine)
                    .font(LiveCashTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var whoAmI: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Wer bin ich finanziell?")
                HStack {
                    profileChip("Sparen", analytics.profile.savings, LiveCashTheme.income)
                    profileChip("Kontrolle", analytics.profile.spendingControl, .orange)
                    profileChip("Planung", analytics.profile.planning, .blue)
                }
            }
        }
    }

    private var spending: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Wo gebe ich mein Geld aus?")
                if categorySlices.isEmpty {
                    Text("Noch zu wenig Daten — erfasse ein paar Ausgaben.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(categorySlices) { slice in
                        SectorMark(
                            angle: .value("A", slice.amount * Double(chartAppear)),
                            innerRadius: .ratio(selectedSlice == slice.name ? 0.48 : 0.55),
                            angularInset: selectedSlice == slice.name ? 3 : 1.5
                        )
                        .foregroundStyle(by: .value("K", slice.name))
                        .opacity(selectedSlice == nil || selectedSlice == slice.name ? 1 : 0.45)
                    }
                    .frame(height: 190)
                    .chartLegend(.hidden)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedSlice)
                    .animation(.easeOut(duration: 0.9), value: chartAppear)

                    if let name = selectedSlice,
                       let slice = categorySlices.first(where: { $0.name == name }) {
                        HStack {
                            Image(systemName: slice.icon.isEmpty ? "circle.fill" : slice.icon)
                                .foregroundStyle(LiveCashTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(slice.name)
                                    .font(LiveCashTheme.bodyFont.weight(.semibold))
                                Text(String(format: "%.0f€ · %.0f%%", slice.amount, slice.percent))
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(LiveCashTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    ForEach(categorySlices) { slice in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedSlice = selectedSlice == slice.name ? nil : slice.name
                            }
                            HapticService.selection(store: store)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(LiveCashTheme.accent.opacity(selectedSlice == slice.name ? 1 : 0.35))
                                    .frame(width: 8, height: 8)
                                Text(slice.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(String(format: "%.0f€", slice.amount))
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.0f%%", slice.percent))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .font(LiveCashTheme.captionFont)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    if memory.prevMonthExpenses > 0 {
                        let delta = memory.monthExpenses - memory.prevMonthExpenses
                        Text(
                            delta < 0
                            ? String(format: "Du hast %.0f€ weniger ausgegeben als letzten Monat.", abs(delta))
                            : String(format: "Du hast %.0f€ mehr ausgegeben als letzten Monat.", delta)
                        )
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(delta <= 0 ? LiveCashTheme.income : LiveCashTheme.expense)
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private var monthBars: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Monats-Trend")
                if analytics.monthBars.isEmpty {
                    Text("Mehr Monate = klarere Trends.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(analytics.monthBars) { bar in
                        BarMark(
                            x: .value("M", bar.label),
                            y: .value("€", bar.amount * Double(chartAppear))
                        )
                        .foregroundStyle(LiveCashTheme.accent.gradient)
                    }
                    .frame(height: 140)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }
        }
    }

    private var strengths: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Was mache ich gut?")
                ForEach(analyze.strengths, id: \.self) { line in
                    Label(line, systemImage: "checkmark.circle.fill")
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(LiveCashTheme.income)
                }
            }
        }
    }

    private var changes: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Was sollte ich ändern?")
                ForEach(analyze.suggestions, id: \.self) { line in
                    Label(line, systemImage: "arrow.triangle.2.circlepath")
                        .font(LiveCashTheme.bodyFont)
                }
            }
        }
    }

    private var forecast: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Prognose nächste Monate")
                Text(analyze.futureOutlook)
                    .font(LiveCashTheme.bodyFont)
                    .foregroundStyle(.secondary)
                ForEach(scenarios.prefix(3)) { s in
                    HStack {
                        Text(s.title)
                        Spacer()
                        Text(s.resultLabel)
                            .foregroundStyle(LiveCashTheme.accent)
                            .fontWeight(.semibold)
                    }
                    .font(LiveCashTheme.captionFont)
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(LiveCashTheme.headlineFont)
    }

    private func profileChip(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)%")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(title)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
