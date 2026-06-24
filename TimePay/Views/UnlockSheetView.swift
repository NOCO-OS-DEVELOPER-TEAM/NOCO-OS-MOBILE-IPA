import SwiftUI

struct UnlockSheetView: View {
    @EnvironmentObject private var store: TimePayStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NOCOTheme.midnight.ignoresSafeArea()

                VStack(spacing: 16) {
                    if let app = store.shortcutRequestedApp, !app.isEmpty {
                        Text("Für „\(app)“ freischalten")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    Text("Konto: \(store.formattedBalance)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NOCOTheme.teal)

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
                                GlassCard(glow: NOCOTheme.teal) {
                                    MinuteStepperView(
                                        minutes: $store.spendMinutes,
                                        maxMinutes: store.maxSpendMinutes,
                                        accent: NOCOTheme.teal,
                                        label: "Minuten abbuchen"
                                    )
                                }
                                HStack(spacing: 8) {
                                    ForEach([5.0, 10.0, 15.0, 30.0], id: \.self) { m in
                                        Button("\(Int(m))") {
                                            store.applySpendPreset(m)
                                        }
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            m <= store.maxSpendMinutes ? NOCOTheme.teal.opacity(0.15) : .white.opacity(0.06),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(m <= store.maxSpendMinutes ? NOCOTheme.teal : .white.opacity(0.3))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Button {
                            store.confirmUnlock()
                            dismiss()
                        } label: {
                            Label("Gate öffnen", systemImage: "lock.open.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
                        .disabled(store.balanceHalfMinutes < 2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Zeit abbuchen")
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
}
