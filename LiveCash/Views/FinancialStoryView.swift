import SwiftUI

struct FinancialStoryView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var period: StoryPeriod = .week
    @State private var slideIndex = 0
    @State private var playMode = false
    @State private var playTask: Task<Void, Never>?

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
            .navigationTitle("Financial Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onChange(of: period) { _, _ in slideIndex = 0 }
            .onDisappear { playTask?.cancel() }
        }
    }

    private func storyCard(_ slide: StorySlide) -> some View {
        let accent = slide.isIncome ? LiveCashTheme.income : LiveCashTheme.expense
        return LiveCashGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(slide.title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(slide.headline)
                    .font(.system(.title, design: .rounded).weight(.bold))
                Text(slide.detail)
                    .font(LiveCashTheme.bodyFont)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(slide.value)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity, minHeight: 280, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    private func startAutoplay() {
        playTask?.cancel()
        playTask = Task {
            while !Task.isCancelled, playMode {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation {
                        slideIndex = (slideIndex + 1) % max(slides.count, 1)
                    }
                }
            }
        }
    }
}
