import SwiftUI

struct EarnTimeView: View {
    @EnvironmentObject private var store: TimePayStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NOCOTheme.midnight.ignoresSafeArea()

                VStack(spacing: 16) {
                    if !store.canBookTime {
                        GlassCard(glow: .orange) {
                            Label(store.sessionStatusText, systemImage: "hourglass")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                taskPicker
                                GlassCard {
                                    MinuteStepperView(
                                        minutes: $store.earnMinutes,
                                        maxMinutes: 120,
                                        accent: NOCOTheme.lavender,
                                        label: "Dauer"
                                    )
                                }
                                Text("Belohnung: +\(TimePayFormat.halfMinutes(max(Int((store.earnMinutes * 2).rounded()), 2)))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(NOCOTheme.mint)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        }

                        Button {
                            store.startEarnSession()
                            dismiss()
                        } label: {
                            Label("Focus starten", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Zeit verdienen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(NOCOTheme.teal)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private var taskPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aufgabe")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.45))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ProductiveTask.defaults) { task in
                        taskChip(task)
                    }
                }
            }
        }
    }

    private func taskChip(_ task: ProductiveTask) -> some View {
        let selected = store.selectedTask == task
        return Button { store.selectedTask = task } label: {
            HStack(spacing: 8) {
                Image(systemName: task.icon)
                    .font(.subheadline)
                Text(task.title)
                    .font(.caption.weight(.bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                selected ? NOCOTheme.lavender.opacity(0.22) : .white.opacity(0.06),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(selected ? NOCOTheme.lavender.opacity(0.6) : .clear, lineWidth: 1)
            }
            .foregroundStyle(selected ? NOCOTheme.lavender : .white.opacity(0.75))
        }
        .buttonStyle(.plain)
    }
}
