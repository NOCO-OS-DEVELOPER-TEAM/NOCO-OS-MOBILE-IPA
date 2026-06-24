import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct DashboardView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var showAppPicker = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                balanceCard
                sessionCards
                actionButtons
                appPickerSection
                lockPreview
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
            Text("NOCO-OS")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.top, 12)
    }

    private var balanceCard: some View {
        GlassCard {
            VStack(spacing: 8) {
                Text("Zeitkonto")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                Text(store.formattedBalance)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: NOCOTheme.teal.opacity(0.35), radius: 12)
                Text("Für gesperrte Apps ausgeben")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var sessionCards: some View {
        VStack(spacing: 12) {
            if store.unlockSessionRemaining > 0 {
                GlassCard {
                    HStack {
                        Image(systemName: "lock.open.fill")
                            .foregroundStyle(NOCOTheme.teal)
                        Text("Apps freigeschaltet")
                        Spacer()
                        Text(formatSeconds(store.unlockSessionRemaining))
                            .font(.system(.body, design: .monospaced).weight(.bold))
                            .foregroundStyle(NOCOTheme.teal)
                    }
                }
            }
            if store.isEarningSessionActive {
                GlassCard {
                    HStack {
                        Image(systemName: store.selectedTask.icon)
                            .foregroundStyle(NOCOTheme.lavender)
                        Text(store.selectedTask.title)
                        Spacer()
                        Text(formatSeconds(store.earnSessionRemaining))
                            .font(.system(.body, design: .monospaced).weight(.bold))
                            .foregroundStyle(NOCOTheme.lavender)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                store.showUnlockSheet = true
            } label: {
                Label("Entsperren", systemImage: "lock.open")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NOCOPrimaryButtonStyle())

            Button {
                store.showEarnSheet = true
            } label: {
                Label("Zeit +", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NOCOSecondaryButtonStyle())
        }
    }

    private var appPickerSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Gesperrte Apps")
                    .font(.headline)
                Text("Wähle Apps, die TimePay mit Bildschirmzeit blockiert.")
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

    private var lockPreview: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.title)
                    .foregroundStyle(NOCOTheme.teal)
                Text("Diese App ist gesperrt")
                    .font(.headline)
                Text("So sieht der Sperrbildschirm auf dem iPhone aus.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                Button("Entsperren") { store.showUnlockSheet = true }
                    .buttonStyle(NOCOPrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func formatSeconds(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

struct NOCOPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(NOCOTheme.accentGradient)
            .foregroundStyle(.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct NOCOSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NOCOTheme.teal.opacity(0.4), lineWidth: 1)
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
