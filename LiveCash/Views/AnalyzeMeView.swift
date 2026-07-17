import SwiftUI
import Charts

struct AnalyzeMeView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var animatedScore: CGFloat = 0

    private var report: AnalyzeMeReport {
        AnalyzeMeEngine.analyze(store: store)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                        .appearFade(delay: 0)
                    scoreCard
                        .appearScale(delay: 0.05)
                    profileRingsCard
                        .appearFade(delay: 0.1)
                    typeCard
                        .appearFade(delay: 0.14)
                    personalityCard
                        .appearFade(delay: 0.18)
                    chartsSection
                        .appearFade(delay: 0.22)
                    factsSection
                        .appearFade(delay: 0.26)
                    strengthsWeaknesses
                        .appearFade(delay: 0.3)
                    suggestionsCard
                        .appearFade(delay: 0.34)
                    futureCard
                        .appearFade(delay: 0.38)
                }
                .padding(20)
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Analyze Me")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        HapticService.soft(store: store)
                        dismiss()
                    }
                }
            }
            .onAppear {
                HapticService.soft(store: store)
                withAnimation(LiveCashMotion.softSpring) {
                    animatedScore = CGFloat(report.score) / 100
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dein Finanzprofil")
                .font(LiveCashTheme.captionFont)
                .foregroundStyle(.secondary)
            Text("Lokal analysiert aus deinen Buchungen, Zielen und Gewohnheiten.")
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(Color.primary.opacity(0.7))
        }
    }

    private var scoreCard: some View {
        LiveCashCard {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(LiveCashTheme.accent.opacity(0.15), lineWidth: 10)
                        .frame(width: 88, height: 88)
                    Circle()
                        .trim(from: 0, to: animatedScore)
                        .stroke(LiveCashTheme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))
                    Text("\(report.score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Finanz-Score")
                        .font(LiveCashTheme.headlineFont)
                    Text("\(report.score)/100")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                    Text(scoreLabel)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LiveCashTheme.accent)
                }
                Spacer()
            }
        }
    }

    private var profileRingsCard: some View {
        let profile = AnalyticsEngine.report(store: store).profile
        return LiveCashCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Dein Finanzprofil")
                    .font(LiveCashTheme.headlineFont)
                profileMeter("Sparfähigkeit", profile.savings, LiveCashTheme.income)
                profileMeter("Ausgabenkontrolle", profile.spendingControl, .orange)
                profileMeter("Planung", profile.planning, .blue)
                Text(report.personalityLine)
                    .font(LiveCashTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private func profileMeter(_ title: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Text(profileLevelLabel(value))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                    Spacer()
                    Text("\(value)%")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(color)
                        .contentTransition(.numericText())
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(color.opacity(0.12))
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * animatedScore * CGFloat(value) / 100)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private func analyzeRing(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 7)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: animatedScore * CGFloat(value) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                Text("\(value)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func profileLevelLabel(_ value: Int) -> String {
        switch value {
        case 80...: return "🟢"
        case 55..<80: return "🟡"
        default: return "🔴"
        }
    }

    private var scoreLabel: String {
        switch report.score {
        case 85...: return "Sehr stark"
        case 70..<85: return "Gut aufgestellt"
        case 55..<70: return "Solide Basis"
        default: return "Ausbaufähig"
        }
    }

    private var typeCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Finanz-Typ")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text(report.financeType)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(report.typeSubtitle)
                    .font(LiveCashTheme.bodyFont)
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
        }
    }

    private var personalityCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Persönlichkeit", systemImage: "person.crop.circle")
                    .font(LiveCashTheme.headlineFont)
                    .foregroundStyle(LiveCashTheme.accent)
                Text(report.personalityLine)
                    .font(LiveCashTheme.bodyFont)
            }
        }
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagramme")
                .font(LiveCashTheme.headlineFont)

            LiveCashCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ausgabenverteilung")
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                    if report.categoryShares.isEmpty {
                        Text("Noch zu wenige Ausgaben diesen Monat.")
                            .foregroundStyle(.secondary)
                    } else {
                        Chart(report.categoryShares, id: \.name) { item in
                            SectorMark(
                                angle: .value("Anteil", item.percent),
                                innerRadius: .ratio(0.55),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Kategorie", item.name))
                        }
                        .frame(height: 180)
                        .chartLegend(position: .bottom, spacing: 8)

                        ForEach(report.categoryShares, id: \.name) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(String(format: "%.0f%% · %.0f€", item.percent, item.amount))
                                    .foregroundStyle(.secondary)
                            }
                            .font(LiveCashTheme.captionFont)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                metricChip(title: "Sparquote", value: String(format: "%.0f%%", report.savingsRatePercent), color: LiveCashTheme.income)
                metricChip(
                    title: "vs. Vormonat",
                    value: String(format: "%+.0f%%", report.monthCompareDeltaPercent),
                    color: report.monthCompareDeltaPercent <= 0 ? LiveCashTheme.income : LiveCashTheme.expense
                )
                metricChip(title: "Ziele", value: String(format: "%.0f%%", report.goalCompletionPercent), color: LiveCashTheme.accent)
            }
        }
    }

    private func metricChip(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var factsSection: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Erkannte Muster")
                    .font(LiveCashTheme.headlineFont)
                ForEach(report.facts, id: \.self) { fact in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LiveCashTheme.accent)
                        Text(fact)
                            .font(LiveCashTheme.bodyFont)
                    }
                }
            }
        }
    }

    private var strengthsWeaknesses: some View {
        HStack(alignment: .top, spacing: 12) {
            LiveCashCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Stärken", systemImage: "arrow.up.heart.fill")
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                        .foregroundStyle(LiveCashTheme.income)
                    ForEach(report.strengths, id: \.self) { item in
                        Text("• \(item)")
                            .font(LiveCashTheme.captionFont)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            LiveCashCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Schwächen", systemImage: "exclamationmark.triangle.fill")
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                        .foregroundStyle(.orange)
                    ForEach(report.weaknesses, id: \.self) { item in
                        Text("• \(item)")
                            .font(LiveCashTheme.captionFont)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var suggestionsCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Verbesserungsvorschläge")
                    .font(LiveCashTheme.headlineFont)
                ForEach(Array(report.suggestions.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(LiveCashTheme.accent)
                            .clipShape(Circle())
                        Text(tip)
                            .font(LiveCashTheme.bodyFont)
                    }
                }
            }
        }
    }

    private var futureCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Zukunfts-Analyse", systemImage: "sparkles")
                    .font(LiveCashTheme.headlineFont)
                    .foregroundStyle(LiveCashTheme.accent)
                Text(report.futureOutlook)
                    .font(LiveCashTheme.bodyFont)
            }
        }
    }
}
