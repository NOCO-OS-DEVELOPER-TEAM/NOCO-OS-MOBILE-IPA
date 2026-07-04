import SwiftUI

struct FutureSimulationView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var stepIndex = 0
    @State private var playing = false
    @State private var playTask: Task<Void, Never>?

    private var steps: [SimulationStep] {
        FutureSimulationEngine.steps(store: store)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard

                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    stepCard(step, highlighted: idx == stepIndex)
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) { stepIndex = idx }
                        }
                }

                HStack(spacing: 12) {
                    Button {
                        playing.toggle()
                        if playing { runPlay() } else { playTask?.cancel() }
                    } label: {
                        Label(playing ? "Pause" : "Simulation abspielen", systemImage: playing ? "pause.circle.fill" : "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LiveCashTheme.accent)
                }
            }
            .padding(20)
        }
        .background(LiveCashTheme.screenBackground)
        .navigationTitle("Zukunfts-Simulation")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { playTask?.cancel() }
    }

    private var headerCard: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Aktueller Saldo")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f€", store.allTimeBalance))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(store.allTimeBalance >= 0 ? LiveCashTheme.income : LiveCashTheme.expense)
                Text("Basierend auf deinem Verhalten der letzten Wochen")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func stepCard(_ step: SimulationStep, highlighted: Bool) -> some View {
        let positive = step.projectedBalance >= store.allTimeBalance
        return LiveCashGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(step.label)
                        .font(LiveCashTheme.headlineFont)
                    Spacer()
                    if highlighted {
                        Image(systemName: "scope")
                            .foregroundStyle(LiveCashTheme.accent)
                    }
                }
                Text(String(format: "%.0f€", step.projectedBalance))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(positive ? LiveCashTheme.income : LiveCashTheme.expense)
                Text(step.explanation)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
            .opacity(highlighted ? 1 : 0.75)
            .scaleEffect(highlighted ? 1 : 0.98)
        }
        .animation(.easeOut(duration: 0.2), value: highlighted)
    }

    private func runPlay() {
        playTask?.cancel()
        stepIndex = 0
        playTask = Task {
            for idx in steps.indices {
                guard !Task.isCancelled, playing else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) { stepIndex = idx }
                }
                try? await Task.sleep(for: .seconds(2))
            }
            await MainActor.run { playing = false }
        }
    }
}
