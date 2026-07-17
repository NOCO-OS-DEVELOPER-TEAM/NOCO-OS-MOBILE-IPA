import SwiftUI
import Charts

struct AnalyticsCenterView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedCategory: String?
    @State private var scoreProgress: CGFloat = 0
    @State private var barProgress: CGFloat = 0
    @State private var animateGoals = false

    private var report: AnalyticsReport {
        AnalyticsEngine.report(store: store)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                financeStatusCard
                categoryDonutCard
                monthCompareCard
                cashflowCard
                goalsCard
                hotspotCard
                profileRingsCard
            }
            .padding(20)
        }
        .background(LiveCashTheme.screenBackground)
        .navigationTitle("Analyse")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                scoreProgress = CGFloat(report.financeScore) / 100
            }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.78).delay(0.15)) {
                barProgress = 1
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
                animateGoals = true
            }
        }
    }

    // MARK: - 1 Finanzstatus

    private var financeStatusCard: some View {
        LiveCashCard {
            VStack(spacing: 18) {
                Text("Finanzstatus")
                    .font(LiveCashTheme.headlineFont)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(LiveCashTheme.accent.opacity(0.12), lineWidth: 14)
                        .frame(width: 148, height: 148)
                    Circle()
                        .trim(from: 0, to: scoreProgress)
                        .stroke(
                            AngularGradient(
                                colors: [LiveCashTheme.accent, LiveCashTheme.income, LiveCashTheme.accent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 148, height: 148)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(report.financeScore)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        Text("Finanz Score")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Text("/ 100")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metricTile("Sparquote", String(format: "%.0f%%", report.savingsRatePercent), LiveCashTheme.income)
                    metricTile("Ausgabenverhalten", report.spendingBehaviorLabel, LiveCashTheme.accent)
                    metricTile("Zielerreichung", String(format: "%.0f%%", report.goalAchievementPercent), .orange)
                    metricTile("Kontostand", report.balanceTrendLabel, .blue)
                }
            }
        }
    }

    // MARK: - 2 Donut

    private var categoryDonutCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ausgaben")
                    .font(LiveCashTheme.headlineFont)

                if report.categorySlices.isEmpty {
                    Text("Noch keine Ausgaben diesen Monat.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(report.categorySlices) { slice in
                        SectorMark(
                            angle: .value("Anteil", slice.amount),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.8
                        )
                        .foregroundStyle(by: .value("Kategorie", slice.name))
                        .opacity(selectedCategory == nil || selectedCategory == slice.name ? 1 : 0.35)
                    }
                    .frame(height: 200)
                    .chartLegend(.hidden)
                    .rotationEffect(.degrees(selectedCategory == nil ? 0 : 8))
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: selectedCategory)

                    if let selected = report.categorySlices.first(where: { $0.name == selectedCategory }) {
                        Text(String(format: "Du hast diesen Monat %.0f %% für %@ ausgegeben.", selected.percent, selected.name))
                            .font(LiveCashTheme.bodyFont)
                            .foregroundStyle(LiveCashTheme.accent)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        Text("Tippe auf ein Segment für Details.")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(report.categorySlices) { slice in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                selectedCategory = selectedCategory == slice.name ? nil : slice.name
                            }
                        } label: {
                            HStack {
                                Image(systemName: slice.icon)
                                    .foregroundStyle(LiveCashTheme.accent)
                                    .frame(width: 22)
                                Text(slice.name)
                                Spacer()
                                Text(String(format: "%.0f%% · %.0f€", slice.percent, slice.amount))
                                    .foregroundStyle(.secondary)
                            }
                            .font(LiveCashTheme.captionFont)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 3 Month compare

    private var monthCompareCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Monatsvergleich")
                    .font(LiveCashTheme.headlineFont)

                let maxAmount = max(report.monthBars.map(\.amount).max() ?? 1, 1)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(report.monthBars) { bar in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(bar.label)
                                    .font(LiveCashTheme.captionFont)
                                Spacer()
                                Text(String(format: "%.0f€", bar.amount))
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.primary.opacity(0.06))
                                    Capsule()
                                        .fill(LiveCashTheme.accent.gradient)
                                        .frame(width: geo.size.width * CGFloat(bar.amount / maxAmount) * barProgress)
                                }
                            }
                            .frame(height: 14)
                        }
                    }
                }

                let delta = report.monthCompareDeltaPercent
                Text(
                    delta < -1
                    ? String(format: "Du hast %.0f %% weniger ausgegeben.", abs(delta))
                    : (delta > 1
                       ? String(format: "Du hast %.0f %% mehr ausgegeben.", delta)
                       : "Ausgaben etwa auf Vormonatsniveau.")
                )
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(delta <= 0 ? LiveCashTheme.income : LiveCashTheme.expense)
            }
        }
    }

    // MARK: - 4 Cashflow

    private var cashflowCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Geldfluss")
                    .font(LiveCashTheme.headlineFont)

                if report.cashflow.isEmpty {
                    Text("Noch keine Bewegungen diesen Monat.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(report.cashflow) { event in
                        LineMark(
                            x: .value("Zeit", event.date),
                            y: .value("Saldo", event.runningBalance)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LiveCashTheme.accent)

                        PointMark(
                            x: .value("Zeit", event.date),
                            y: .value("Saldo", event.runningBalance)
                        )
                        .foregroundStyle(event.isIncome ? LiveCashTheme.income : LiveCashTheme.expense)
                        .symbolSize(36)
                    }
                    .frame(height: 160)
                    .chartXAxis(.hidden)

                    ForEach(report.cashflow.suffix(5).reversed()) { event in
                        HStack {
                            Text(event.title)
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%@%.0f€", event.amount >= 0 ? "+" : "", event.amount))
                                .foregroundStyle(event.isIncome ? LiveCashTheme.income : LiveCashTheme.expense)
                                .fontWeight(.semibold)
                        }
                        .font(LiveCashTheme.captionFont)
                    }
                }
            }
        }
    }

    // MARK: - 5 Goals

    private var goalsCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sparziele")
                    .font(LiveCashTheme.headlineFont)

                if report.goals.isEmpty {
                    Text("Lege ein Sparziel an, um Fortschritt zu sehen.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(report.goals) { goal in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(goal.name)
                                    .font(LiveCashTheme.bodyFont.weight(.semibold))
                                Spacer()
                                Text("\(goal.progressPercent)%")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(LiveCashTheme.accent)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(LiveCashTheme.incomeSoft)
                                    Capsule()
                                        .fill(LiveCashTheme.accent)
                                        .frame(width: geo.size.width * (animateGoals ? goal.progress : 0))
                                }
                            }
                            .frame(height: 10)
                            HStack {
                                Text(String(format: "Ø %.0f€/Woche", goal.weeklyAverage))
                                Spacer()
                                if let days = goal.daysRemaining {
                                    Text("\(days) Tage")
                                }
                                Spacer()
                                Text(String(format: "%.0f€ nötig", goal.remaining))
                            }
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                            if let needed = goal.neededWeekly {
                                Text(String(format: "Benötigt: ~%.0f€/Woche", needed))
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    // MARK: - 6 Hotspots

    private var hotspotCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ausgaben-Hotspots")
                    .font(LiveCashTheme.headlineFont)

                if let caption = report.topHotspotCaption {
                    Text(caption)
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(LiveCashTheme.expense)
                }

                if report.hotspots.isEmpty {
                    Text("Orte erscheinen, sobald Ausgaben mit Standort erfasst sind.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(report.hotspots) { spot in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(spot.intensity.color)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spot.title)
                                    .font(LiveCashTheme.bodyFont.weight(.semibold))
                                Text(spot.intensity.label)
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0f€", spot.amount))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                        }
                    }

                    HStack(spacing: 16) {
                        legendDot(MapHeatIntensity.expensive)
                        legendDot(MapHeatIntensity.normal)
                        legendDot(MapHeatIntensity.frugal)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - 7 Profile rings

    private var profileRingsCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Dein Finanzprofil")
                    .font(LiveCashTheme.headlineFont)

                HStack(spacing: 18) {
                    profileRing("Sparverhalten", report.profile.savings, LiveCashTheme.income)
                    profileRing("Kontrolle", report.profile.spendingControl, .orange)
                    profileRing("Planung", report.profile.planning, .blue)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Helpers

    private func metricTile(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(color)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func profileRing(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: scoreProgress * CGFloat(value) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                Text("\(value)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func legendDot(_ intensity: MapHeatIntensity) -> some View {
        HStack(spacing: 4) {
            Circle().fill(intensity.color).frame(width: 8, height: 8)
            Text(intensity.label)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

}
