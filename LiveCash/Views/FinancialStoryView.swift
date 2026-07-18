import SwiftUI
import Charts
import MapKit

struct FinancialStoryView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var period: StoryPeriod = .month
    @State private var slideIndex = 0
    @State private var playMode = false
    @State private var playTask: Task<Void, Never>?
    @State private var sceneToken = UUID()

    private var slides: [StorySlide] {
        FinancialStoryEngine.slides(for: period, store: store)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiveCashTheme.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Zeitraum", selection: $period) {
                        ForEach(StoryPeriod.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    if slides.isEmpty {
                        Spacer()
                        ContentUnavailableView("Keine Daten", systemImage: "chart.bar")
                        Spacer()
                    } else {
                        TabView(selection: $slideIndex) {
                            ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                                StorySceneCard(
                                    slide: slide,
                                    isActive: slideIndex == idx,
                                    sceneToken: sceneToken,
                                    store: store
                                )
                                .tag(idx)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .animation(LiveCashMotion.softSpring, value: slideIndex)
                        .onChange(of: slideIndex) { _, _ in
                            sceneToken = UUID()
                            HapticService.selection(store: store)
                        }
                    }

                    controlsBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
            }
            .navigationTitle("Finanz-Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        playTask?.cancel()
                        playMode = false
                        dismiss()
                    }
                }
            }
            .onChange(of: period) { _, _ in
                slideIndex = 0
                sceneToken = UUID()
                restartAutoplayIfNeeded()
            }
            .onAppear {
                sceneToken = UUID()
            }
            .onDisappear {
                playTask?.cancel()
                playMode = false
            }
        }
    }

    private var controlsBar: some View {
        HStack(spacing: 16) {
            Button {
                playMode.toggle()
                if playMode {
                    startAutoplay()
                } else {
                    playTask?.cancel()
                }
                HapticService.light(store: store)
            } label: {
                Label(playMode ? "Pause" : "Play", systemImage: playMode ? "pause.fill" : "play.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(LiveCashTheme.accent)

            if !slides.isEmpty {
                Text("\(slideIndex + 1)/\(slides.count)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private func restartAutoplayIfNeeded() {
        playTask?.cancel()
        if playMode { startAutoplay() }
    }

    private func startAutoplay() {
        playTask?.cancel()
        playTask = Task {
            while !Task.isCancelled, playMode {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard playMode, !slides.isEmpty else { return }
                    withAnimation(LiveCashMotion.softSpring) {
                        slideIndex = (slideIndex + 1) % slides.count
                    }
                    HapticService.soft(store: store)
                }
            }
        }
    }
}

// MARK: - Scene card shell

private struct StorySceneCard: View {
    let slide: StorySlide
    let isActive: Bool
    let sceneToken: UUID
    let store: FinanceStore

    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0

    var body: some View {
        LiveCashGlassCard {
            VStack(alignment: .leading, spacing: 0) {
                sceneHeader
                Spacer(minLength: 12)
                sceneContent
            }
            .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
        }
        .padding(.horizontal, 16)
        .scaleEffect(cardScale)
        .opacity(cardOpacity)
        .onAppear { animateIn() }
        .onChange(of: isActive) { _, active in
            if active { animateIn() }
        }
        .onChange(of: sceneToken) { _, _ in
            if isActive { animateIn() }
        }
    }

    private var sceneHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(slide.title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                if !slide.periodLabel.isEmpty {
                    Text(slide.periodLabel)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LiveCashTheme.accent)
                }
            }
            Spacer()
            if let emoji = slide.accentEmoji {
                Text(emoji)
                    .font(.system(size: 28))
            }
        }
    }

    @ViewBuilder
    private var sceneContent: some View {
        switch slide.kind {
        case .greeting:
            GreetingSceneContent(slide: slide, isActive: isActive)
        case .mapHotspot:
            MapHotspotSceneContent(slide: slide, isActive: isActive)
        case .categoryChart:
            CategoryChartSceneContent(slide: slide, isActive: isActive)
        case .goalsProgress:
            GoalsProgressSceneContent(slide: slide, isActive: isActive, store: store)
        case .personalInsight:
            PersonalInsightSceneContent(slide: slide, isActive: isActive)
        case .tip:
            TipSceneContent(slide: slide, isActive: isActive)
        }
    }

    private func animateIn() {
        cardScale = 0.92
        cardOpacity = 0
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            cardScale = 1
            cardOpacity = 1
        }
    }
}

// MARK: - Greeting

private struct GreetingSceneContent: View {
    let slide: StorySlide
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(slide.headline)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            if let amount = slide.displayAmount {
                AnimatedMoneyText(
                    value: amount,
                    font: .system(size: 56, weight: .bold, design: .rounded),
                    color: slide.isIncome ? LiveCashTheme.income : LiveCashTheme.expense,
                    decimals: 0
                )
                .id(isActive ? slide.id : "idle")
            } else {
                Text(slide.value)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(slide.isIncome ? LiveCashTheme.income : LiveCashTheme.expense)
            }

            Text(slide.detail)
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Map hotspot

private struct MapHotspotSceneContent: View {
    let slide: StorySlide
    let isActive: Bool

    @State private var mapOpacity: Double = 0
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(slide.mapLabel ?? slide.headline)
                .font(.system(.title2, design: .rounded).weight(.bold))

            ZStack {
                if let coordinate = slide.mapCoordinate {
                    Map(position: $cameraPosition, interactionModes: []) {
                        Marker(slide.mapLabel ?? slide.headline, coordinate: coordinate)
                            .tint(LiveCashTheme.expense)
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(height: 180)
                    .opacity(mapOpacity)
                    .onAppear {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: coordinate,
                            latitudinalMeters: 800,
                            longitudinalMeters: 800
                        ))
                        withAnimation(LiveCashMotion.appearEase.delay(0.15)) {
                            mapOpacity = 1
                        }
                    }
                } else {
                    mapFallback
                }
            }

            Text(slide.detail)
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(.secondary)

            if let amount = slide.displayAmount {
                AnimatedMoneyText(
                    value: amount,
                    font: .system(size: 40, weight: .bold, design: .rounded),
                    color: LiveCashTheme.expense,
                    decimals: 0
                )
                .id(isActive ? slide.id : "map-idle")
            }
        }
        .onChange(of: isActive) { _, active in
            if active, slide.mapCoordinate != nil {
                mapOpacity = 0
                withAnimation(LiveCashMotion.appearEase.delay(0.1)) {
                    mapOpacity = 1
                }
            }
        }
    }

    private var mapFallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LiveCashTheme.expenseSoft, LiveCashTheme.accentSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(LiveCashTheme.expense)
                    .symbolEffect(.bounce, value: isActive)
                Text(slide.mapLabel ?? "Unbekannter Ort")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
            }
        }
        .frame(height: 180)
        .appearScale(delay: 0.08)
    }
}

// MARK: - Category chart

private struct CategoryChartSceneContent: View {
    let slide: StorySlide
    let isActive: Bool

    @State private var chartShown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(slide.headline)
                .font(.system(.title2, design: .rounded).weight(.bold))

            if let series = slide.chartSeries, !series.isEmpty {
                Chart {
                    ForEach(Array(series.enumerated()), id: \.offset) { _, item in
                        SectorMark(
                            angle: .value("Betrag", chartShown ? item.1 : 0),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Kategorie", item.0))
                        .cornerRadius(4)
                    }
                }
                .chartLegend(position: .bottom, spacing: 6)
                .frame(height: 200)
                .onAppear { revealChart() }
                .onChange(of: isActive) { _, active in
                    if active { revealChart() }
                }
            }

            Text(slide.detail)
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(.secondary)
        }
    }

    private func revealChart() {
        chartShown = false
        withAnimation(.easeOut(duration: 0.85).delay(0.12)) {
            chartShown = true
        }
    }
}

// MARK: - Goals progress

private struct GoalsProgressSceneContent: View {
    let slide: StorySlide
    let isActive: Bool
    let store: FinanceStore

    @State private var progress: Double = 0
    @State private var chartShown = false

    private var targetPercent: Double {
        Double(slide.value.replacingOccurrences(of: "%", with: "")) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(slide.headline)
                .font(.system(.title, design: .rounded).weight(.bold))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 18)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [LiveCashTheme.accent, LiveCashTheme.income],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(24, CGFloat(progress / 100) * 280), height: 18)
            }
            .frame(maxWidth: 280, alignment: .leading)
            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)

            HStack {
                Text("\(Int(progress))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(LiveCashTheme.income)
                    .contentTransition(.numericText())
                Spacer()
                if let amount = slide.displayAmount {
                    Text(String(format: "%.0f€", amount))
                        .font(LiveCashTheme.headlineFont)
                        .foregroundStyle(.secondary)
                }
            }

            if let series = slide.chartSeries, series.count >= 2 {
                Chart {
                    ForEach(Array(series.enumerated()), id: \.offset) { _, item in
                        BarMark(
                            x: .value("Anteil", item.0),
                            y: .value("Prozent", chartShown ? item.1 : 0)
                        )
                        .foregroundStyle(item.0 == "Erreicht" ? LiveCashTheme.income.gradient : Color.primary.opacity(0.12).gradient)
                        .cornerRadius(8)
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 110)
            }

            Text(slide.detail)
                .font(LiveCashTheme.bodyFont)
                .foregroundStyle(.secondary)
        }
        .onAppear { animateProgress() }
        .onChange(of: isActive) { _, active in
            if active { animateProgress() }
        }
    }

    private func animateProgress() {
        progress = 0
        chartShown = false
        withAnimation(.spring(response: 0.75, dampingFraction: 0.82).delay(0.1)) {
            progress = targetPercent
        }
        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
            chartShown = true
        }
        if isActive {
            HapticService.progressStep(store: store, percent: Int(targetPercent))
        }
    }
}

// MARK: - Personal insight

private struct PersonalInsightSceneContent: View {
    let slide: StorySlide
    let isActive: Bool

    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(slide.headline)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(slide.isIncome ? LiveCashTheme.income : .primary)
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 16)
                .animation(LiveCashMotion.softSpring.delay(0.05), value: shown)

            Text(slide.detail)
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 12)
                .animation(LiveCashMotion.softSpring.delay(0.12), value: shown)

            Spacer(minLength: 0)

            Text(slide.value)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(slide.isIncome ? LiveCashTheme.income : LiveCashTheme.expense)
                .opacity(shown ? 1 : 0)
                .scaleEffect(shown ? 1 : 0.9)
                .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.2), value: shown)
        }
        .onAppear { reveal() }
        .onChange(of: isActive) { _, active in
            if active { reveal() }
        }
    }

    private func reveal() {
        shown = false
        withAnimation {
            shown = true
        }
    }
}

// MARK: - Tip

private struct TipSceneContent: View {
    let slide: StorySlide
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text(slide.headline)
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LiveCashTheme.accentSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(LiveCashTheme.accent.opacity(0.25), lineWidth: 1)
                    )
            }
            .appearScale(delay: 0.06)

            Text(slide.detail)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .appearFade(delay: 0.14)

            Spacer(minLength: 0)

            Text(slide.value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(LiveCashTheme.accent)
                .frame(maxWidth: .infinity, alignment: .center)
                .appearScale(delay: 0.22)
        }
    }
}
