import SwiftUI

struct EarnTimeView: View {
    @EnvironmentObject private var store: TimePayStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NOCOTheme.midnight.ignoresSafeArea()
            LiquidGlassBackground()

            VStack(spacing: 20) {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                Text("Zeit verdienen")
                    .font(.title2.bold())

                Text("Produktiv sein → Minuten aufs Konto")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aufgabe")
                            .font(.headline)
                        ForEach(ProductiveTask.defaults) { task in
                            Button {
                                store.selectedTask = task
                            } label: {
                                HStack {
                                    Image(systemName: task.icon)
                                        .frame(width: 28)
                                    Text(task.title)
                                    Spacer()
                                    if store.selectedTask == task {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(NOCOTheme.teal)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundStyle(.white)
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
                        Text("Du erhältst \(Int(store.earnMinutes)) Min auf dein Konto.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                if store.isEarningSessionActive {
                    Button("Session abbrechen") {
                        store.cancelEarnSession()
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                } else {
                    Button("Session starten") {
                        store.startEarnSession()
                        dismiss()
                    }
                    .buttonStyle(NOCOPrimaryButtonStyle())
                }

                Button("Schließen") { dismiss() }
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(24)
        }
        .presentationDetents([.large])
    }
}
