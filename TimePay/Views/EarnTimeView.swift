import SwiftUI

struct EarnTimeView: View {
    @EnvironmentObject private var store: TimePayStore
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            NOCOTheme.midnight.ignoresSafeArea()
            LiquidGlassBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(width: 40, height: 4)
                        .padding(.top, 8)

                    VStack(spacing: 4) {
                        Text("Zeit verdienen")
                            .font(.title2.bold())
                        Text("Focus-Session → Minuten aufs Konto")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    if !store.canBookTime {
                        GlassCard(glow: .orange) {
                            Label(store.sessionStatusText, systemImage: "hourglass")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        GlassCard(glow: NOCOTheme.lavender) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Aufgabe wählen")
                                    .font(.headline)
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(ProductiveTask.defaults) { task in
                                        taskChip(task)
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Dauer")
                                    Spacer()
                                    Text("\(Int(store.earnMinutes)) Min")
                                        .font(.title3.bold())
                                        .foregroundStyle(NOCOTheme.lavender)
                                }
                                Slider(value: $store.earnMinutes, in: 1...60, step: 1)
                                    .tint(NOCOTheme.lavender)
                                Text("Belohnung: +\(Int(store.earnMinutes)) Min auf dein Konto")
                                    .font(.caption)
                                    .foregroundStyle(NOCOTheme.mint)
                            }
                        }

                        Button {
                            store.startEarnSession()
                            dismiss()
                        } label: {
                            Label("Focus starten", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
                    }

                    Button("Schließen") { dismiss() }
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 8)
                }
                .padding(24)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private func taskChip(_ task: ProductiveTask) -> some View {
        let selected = store.selectedTask == task
        return Button { store.selectedTask = task } label: {
            VStack(spacing: 8) {
                Image(systemName: task.icon)
                    .font(.title3)
                    .foregroundStyle(selected ? NOCOTheme.teal : NOCOTheme.lavender)
                Text(task.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? NOCOTheme.teal.opacity(0.15) : .white.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? NOCOTheme.teal.opacity(0.5) : .white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
