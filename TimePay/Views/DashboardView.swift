import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct DashboardView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var showAppPicker = false

    private var buttonsEnabled: Bool { store.canBookTime }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                if store.isSessionActive {
                    sessionLockBanner
                }
                balanceCard
                statsCard
                sessionCards
                quickPresets
                actionButtons
                appPickerSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                NOCOLogoMark()
                VStack(alignment: .leading, spacing: 2) {
                    Text("NOCO Time Payment")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("TimePay")
                        .font(.caption)
                        .foregroundStyle(NOCOTheme.teal)
                }
            }
            Spacer()
            if store.streakDays >= 2 {
                GlassPill(text: "\(store.streakDays) Tage", color: NOCOTheme.lavender)
            }
            Text("NOCO-OS")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(0.2), lineWidth: 1) }
        }
        .padding(.top, 12)
    }

    private var sessionLockBanner: some View {
        GlassCard(glow: NOCOTheme.lavender) {
            HStack(spacing: 12) {
                Image(systemName: "hourglass.circle.fill")
                    .font(.title2)
                    .foregroundStyle(NOCOTheme.lavender)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session aktiv")
                        .font(.subheadline.weight(.bold))
                    Text(store.sessionStatusText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
            }
        }
    }

    private var balanceCard: some View {
        GlassCard(glow: NOCOTheme.teal) {
            VStack(spacing: 12) {
                Text("Zeitkonto")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))

                ZStack {
                    if store.isSessionActive {
                        LiquidProgressRing(
                            progress: store.unlockSessionRemaining > 0 ? store.unlockProgress : store.earnProgress,
                            color: store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender,
                            lineWidth: 5
                        )
                        .frame(width: 130, height: 130)
                    }
                    Text(store.formattedBalance)
                        .font(.system(size: store.isSessionActive ? 36 : 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: NOCOTheme.teal.opacity(0.35), radius: 12)
                }

                if store.unlockSessionRemaining > 0 {
                    Text("Freigabe: \(formatSeconds(store.unlockSessionRemaining))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NOCOTheme.teal)
                } else if store.isEarningSessionActive {
                    Text("Focus: \(formatSeconds(store.earnSessionRemaining))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NOCOTheme.lavender)
                } else {
                    Text("Für gesperrte Apps ausgeben")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statsCard: some View {
        GlassCard {
            HStack(spacing: 0) {
                statItem(value: "+\(store.earnedToday)", label: "Heute verdient", color: NOCOTheme.mint)
                Divider().frame(height: 40).background(.white.opacity(0.15))
                statItem(value: "-\(store.spentToday)", label: "Heute ausgegeben", color: NOCOTheme.teal)
                Divider().frame(height: 40).background(.white.opacity(0.15))
                statItem(value: "\(screenTime.blockedAppCount)", label: "Apps gesperrt", color: .orange)
            }
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var sessionCards: some View {
        VStack(spacing: 12) {
            if store.isEarningSessionActive {
                GlassCard(glow: NOCOTheme.lavender) {
                    HStack {
                        Image(systemName: store.selectedTask.icon)
                            .foregroundStyle(NOCOTheme.lavender)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.selectedTask.title)
                                .font(.subheadline.weight(.semibold))
                            Text("Focus-Session")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Text(formatSeconds(store.earnSessionRemaining))
                            .font(.system(.body, design: .monospaced).weight(.bold))
                            .foregroundStyle(NOCOTheme.lavender)
                    }
                }
            }
        }
    }

    private var quickPresets: some View {
        Group {
            if buttonsEnabled && store.balanceMinutes > 0 {
                HStack(spacing: 10) {
                    ForEach([5, 10, 15], id: \.self) { min in
                        Button {
                            store.applySpendPreset(min)
                            store.tryOpenUnlockSheet()
                        } label: {
                            Text("\(min) Min")
                                .font(.caption.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(NOCOSecondaryButtonStyle(enabled: min <= store.balanceMinutes))
                        .disabled(min > store.balanceMinutes)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { store.tryOpenUnlockSheet() } label: {
                Label("Abbuchen", systemImage: "lock.open")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NOCOPrimaryButtonStyle(enabled: buttonsEnabled))
            .disabled(!buttonsEnabled)

            Button { store.tryOpenEarnSheet() } label: {
                Label("Gutschreiben", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NOCOSecondaryButtonStyle(enabled: buttonsEnabled))
            .disabled(!buttonsEnabled)
        }
    }

    private var appPickerSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Gesperrte Apps")
                    .font(.headline)
                Text("Apple Activity-Auswahl — ausgewählte Apps werden wirklich blockiert.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))

                if let error = screenTime.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                HStack {
                    Text("\(screenTime.blockedAppCount) ausgewählt")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if screenTime.shieldsActive {
                        GlassPill(text: "Gesperrt", color: .orange)
                    } else if store.unlockSessionRemaining > 0 {
                        GlassPill(text: "Freigabe aktiv", color: NOCOTheme.teal)
                    }
                    Button("Apps wählen") { showAppPicker = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NOCOTheme.teal)
                }
            }
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: Binding(
                get: { screenTime.selection },
                set: { screenTime.updateSelection($0) }
            )
        )
        #endif
    }

    private func formatSeconds(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
