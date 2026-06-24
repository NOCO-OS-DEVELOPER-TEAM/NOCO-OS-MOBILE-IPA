import SwiftUI

struct UnlockSheetView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss

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

                    NOCOLogoMark(size: 52)

                    VStack(spacing: 4) {
                        Text("Zeit abbuchen")
                            .font(.title2.bold())
                        Text("Konto: \(store.formattedBalance)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(NOCOTheme.teal)
                    }

                    if !store.canBookTime {
                        GlassCard(glow: .orange) {
                            Label(store.sessionStatusText, systemImage: "hourglass")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        GlassCard(glow: NOCOTheme.teal) {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack {
                                    Text("Minuten")
                                    Spacer()
                                    Text("\(Int(store.spendMinutes))")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(NOCOTheme.teal)
                                }
                                Slider(value: $store.spendMinutes, in: 1...Double(max(store.balanceMinutes, 1)), step: 1)
                                    .tint(NOCOTheme.teal)
                                HStack(spacing: 8) {
                                    ForEach([5, 10, 15, 30], id: \.self) { m in
                                        Button("\(m) Min") {
                                            store.spendMinutes = Double(min(m, store.balanceMinutes))
                                        }
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            m <= store.balanceMinutes ? NOCOTheme.teal.opacity(0.15) : .white.opacity(0.06),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(m <= store.balanceMinutes ? NOCOTheme.teal : .white.opacity(0.3))
                                    }
                                }
                            }
                        }

                        Button {
                            store.confirmUnlock(
                                onUnlock: { minutes in screenTime.temporaryUnlock(minutes: minutes) },
                                onRelock: { screenTime.relock() }
                            )
                            dismiss()
                        } label: {
                            Label("Apps freischalten", systemImage: "lock.open.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
                        .disabled(store.balanceMinutes < 1)
                    }

                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 8)
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }
}
