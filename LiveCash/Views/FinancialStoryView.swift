import SwiftUI

struct FinancialStoryView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var period: StoryPeriod = .month
    @State private var slideIndex = 0
    @State private var playMode = false
    @State private var playTask: Task<Void, Never>?
    @State private var cardScale: CGFloat = 0.94
    @State private var cardOpacity: Double = 0

    private var slides: [StorySlide] {
        FinancialStoryEngine.slides(for: period, store: store)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Zeitraum", selection: $period) {
                    ForEach(StoryPeriod.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if slides.isEmpty {
                    ContentUnavailableView("Keine Daten", systemImage: "chart.bar")
                } else {
                    TabView(selection: $slideIndex) {
                        ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                            storyCard(slide)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .animation(.easeInOut, value: slideIndex)
                    .onChange(of: slideIndex) { _, _ in
                        animateCardIn()
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        playMode.toggle()
                        if playMode { startAutoplay() } else { playTask?.cancel() }
                    } label: {
                        Label(playMode ? "Pause" : "Play", systemImage: playMode ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Finanz-Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onChange(of: period) { _, _ in
                slideIndex = 0
                animateCardIn()
            }
            .onAppear { animateCardIn() }
            .onDisappear { playTask?.cancel() }
        }
    }

    private func storyCard(_ slide: StorySlide) -> some View {
        let accent = slide.isIncome ? LiveCashTheme.income : LiveCashTheme.expense
        return LiveCashGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(slide.title.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let emoji = slide.accentEmoji {
                        Text(emoji)
                            .font(.title2)
                    }
                }
                Text(slide.headline)
                    .font(.system(.title, design: .rounded).weight(.bold))
                Text(slide.detail)
                    .font(LiveCashTheme.bodyFont)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(slide.value)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 300, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .scaleEffect(cardScale)
        .opacity(cardOpacity)
    }

    private func animateCardIn() {
        cardScale = 0.92
        cardOpacity = 0
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            cardScale = 1
            cardOpacity = 1
        }
    }

    private func startAutoplay() {
        playTask?.cancel()
        playTask = Task {
            while !Task.isCancelled, playMode {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        slideIndex = (slideIndex + 1) % max(slides.count, 1)
                    }
                    HapticService.selection(store: store)
                }
            }
        }
    }
}
