import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct UnlockSheetView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NOCOTheme.midnight.ignoresSafeArea()
            LiquidGlassBackground()

            VStack(spacing: 24) {
                Capsule()
                    .fill(.white.opacity(0.25))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                NOCOLogoMark(size: 52)

                Text("Zeit abbuchen")
                    .font(.title2.bold())

                Text("Konto: \(store.formattedBalance)")
                    .foregroundStyle(NOCOTheme.teal)

                if !store.canBookTime {
                    GlassCard(glow: .orange) {
                        Label(store.sessionStatusText, systemImage: "hourglass")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                } else {
                    GlassCard(glow: NOCOTheme.teal) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Minuten ausgeben")
                                Spacer()
                                Text("\(Int(store.spendMinutes)) Min")
                                    .font(.title3.bold())
                                    .foregroundStyle(NOCOTheme.teal)
                            }
                            Slider(value: $store.spendMinutes, in: 1...Double(max(store.balanceMinutes, 1)), step: 1)
                                .tint(NOCOTheme.teal)
                            HStack(spacing: 8) {
                                ForEach([5, 10, 15, 30], id: \.self) { m in
                                    Button("\(m)") { store.spendMinutes = Double(min(m, store.balanceMinutes)) }
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .foregroundStyle(m <= store.balanceMinutes ? NOCOTheme.teal : .white.opacity(0.3))
                                }
                            }
                        }
                    }

                    Button("Zeit freischalten") {
                        store.confirmUnlock(
                            onUnlock: { minutes in
                                screenTime.temporaryUnlock(minutes: minutes)
                            },
                            onRelock: { screenTime.relock() }
                        )
                        dismiss()
                    }
                    .buttonStyle(NOCOPrimaryButtonStyle())
                    .disabled(store.balanceMinutes < 1)
                }

                Button("Abbrechen") { dismiss() }
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }
}
