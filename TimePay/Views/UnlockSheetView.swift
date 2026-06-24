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
                    .fill(.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                NOCOLogoMark(size: 52)

                Text("Apps entsperren")
                    .font(.title2.bold())

                Text("Konto: \(store.formattedBalance)")
                    .foregroundStyle(NOCOTheme.teal)

                GlassCard {
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
                    }
                }

                Button("Jetzt entsperren") {
                    store.confirmUnlock(
                        onUnlock: { minutes in
                            screenTime.temporaryUnlock(minutes: minutes)
                        },
                        onRelock: {
                            screenTime.relock()
                        }
                    )
                    dismiss()
                }
                .buttonStyle(NOCOPrimaryButtonStyle())
                .disabled(store.balanceMinutes < 1)

                Button("Abbrechen") { dismiss() }
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
    }
}
