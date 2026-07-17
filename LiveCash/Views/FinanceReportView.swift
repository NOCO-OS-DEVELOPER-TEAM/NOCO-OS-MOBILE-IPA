import SwiftUI
import Charts

/// Spotify-Wrapped-style personal finance report — the wow moment.
struct FinanceReportView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var appearScore: CGFloat = 0
    @State private var sectionOpacity: Double = 0

    private var analyze: AnalyzeMeReport { AnalyzeMeEngine.analyze(store: store) }
    private var analytics: AnalyticsReport { AnalyticsEngine.report(store: store) }
    private var memory: AssistantMemory { AssistantMemory.build(from: store) }
    private var scenarios: [WhatIfScenario] { FutureSimulationEngine.whatIfScenarios(store: store) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    whoAmI
                    spending
                    strengths
                    changes
                    forecast
                }
                .padding(20)
                .opacity(sectionOpacity)
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Mein Finanzbericht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    appearScore = CGFloat(analyze.score) / 100
                    sectionOpacity = 1
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
                sectionTitle("Wo gebe ich Geld aus?")
                if analytics.categorySlices.isEmpty {
                    Text("Noch zu wenig Daten — erfasse ein paar Ausgaben.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(analytics.categorySlices) { slice in
                        SectorMark(
                            angle: .value("A", slice.amount),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("K", slice.name))
                    }
                    .frame(height: 160)
                    .chartLegend(.hidden)

                    ForEach(analytics.categorySlices.prefix(4)) { slice in
                        HStack {
                            Text(slice.name)
                            if let sub = memory.topSubcategory, slice.name == analytics.categorySlices.first?.name {
                                Text("· \(sub)")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0f%%", slice.percent))
                                .foregroundStyle(.secondary)
                        }
                        .font(LiveCashTheme.captionFont)
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
