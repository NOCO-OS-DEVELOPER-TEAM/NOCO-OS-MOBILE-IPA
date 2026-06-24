import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var store: TimePayStore
    @State private var showSetup = false
    @State private var showResetConfirm = false
    @State private var showDiagnosticShare = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                SectionHeader("Einstellungen", subtitle: "Verhalten & Setup", icon: "gearshape.fill")

                GlassCard {
                    VStack(spacing: 0) {
                        toggleRow(
                            title: "Haptisches Feedback",
                            subtitle: "Vibration bei Aktionen",
                            icon: "iphone.radiowaves.left.and.right",
                            isOn: $settings.hapticsEnabled
                        )
                        Divider().background(.white.opacity(0.08))
                        stepperRow
                    }
                }

                GlassCard(glow: gate.setupCompleted ? NOCOTheme.mint : .orange) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Kurzbefehl-Setup")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            GlassPill(
                                text: gate.setupCompleted ? "Aktiv" : "Offen",
                                color: gate.setupCompleted ? NOCOTheme.mint : .orange
                            )
                        }
                        SetupProgressRing(progress: settings.setupProgress)
                            .frame(maxWidth: .infinity)
                        Button {
                            showSetup = true
                        } label: {
                            Label(gate.setupCompleted ? "Setup erneut öffnen" : "Ein-Tap Setup starten", systemImage: "bolt.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Widgets")
                            .font(.subheadline.weight(.bold))
                        HStack(spacing: 12) {
                            widgetPreviewSmall
                            widgetPreviewMedium
                        }
                        Button {
                            WidgetCenter.shared.reloadAllTimelines()
                        } label: {
                            Label("Widgets aktualisieren", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOSecondaryButtonStyle())
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System")
                            .font(.subheadline.weight(.bold))
                        Button("Diagnose-Log teilen") { showDiagnosticShare = true }
                            .buttonStyle(NOCOSecondaryButtonStyle())
                        Button("Setup zurücksetzen") { showResetConfirm = true }
                            .buttonStyle(NOCOSecondaryButtonStyle())
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOCO TimePay")
                            .font(.subheadline.weight(.bold))
                        Text("Version 2.1 · Liquid Glass · Kurzbefehl-Gate")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                        Text("Kein Fokus-Modus · Keine Bildschirmzeit-Berechtigung nötig")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showSetup) {
            OneTapSetupView()
        }
        .sheet(isPresented: $showDiagnosticShare) {
            ShareTextSheet(text: DiagnosticLog.export(store: store, gate: gate))
        }
        .alert("Setup zurücksetzen?", isPresented: $showResetConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Zurücksetzen", role: .destructive) {
                gate.resetSetup()
                settings.shortcutImported = false
                settings.automationConfirmed = false
                settings.hasSeenOnboarding = false
            }
        } message: {
            Text("Du musst Kurzbefehl und Automation danach erneut bestätigen.")
        }
    }

    private var stepperRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "timer")
                .font(.body.weight(.semibold))
                .foregroundStyle(NOCOTheme.lavender)
                .frame(width: 36, height: 36)
                .background(NOCOTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Standard-Freigabe")
                    .font(.subheadline.weight(.semibold))
                Text("Voreinstellung beim Abbuchen")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Stepper("\(settings.defaultUnlockMinutes) Min", value: $settings.defaultUnlockMinutes, in: 5...60, step: 5)
                .labelsHidden()
            Text("\(settings.defaultUnlockMinutes)")
                .font(.headline.weight(.bold))
                .foregroundStyle(NOCOTheme.teal)
                .frame(width: 36)
        }
        .padding(.vertical, 8)
        .onChange(of: settings.defaultUnlockMinutes) { _, new in
            store.spendMinutes = Double(new)
        }
    }

    private var widgetPreviewSmall: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TimePay")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text("\(store.balanceMinutes) Min")
                .font(.headline.weight(.bold))
                .foregroundStyle(NOCOTheme.teal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(NOCOTheme.deepNavy, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(NOCOTheme.teal.opacity(0.25), lineWidth: 1)
        }
    }

    private var widgetPreviewMedium: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Zeitkonto")
                    .font(.caption.weight(.semibold))
                Spacer()
                if store.streakDays >= 2 {
                    Text("\(store.streakDays)🔥")
                        .font(.caption2)
                }
            }
            Text("\(store.balanceMinutes) Min")
                .font(.title2.weight(.bold))
                .foregroundStyle(NOCOTheme.teal)
            Text(sessionLine)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(NOCOTheme.deepNavy, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(NOCOTheme.lavender.opacity(0.2), lineWidth: 1)
        }
    }

    private var sessionLine: String {
        if store.unlockSessionRemaining > 0 { return "Freigabe aktiv" }
        if store.isEarningSessionActive { return "Session läuft" }
        return "Bereit"
    }

    private func toggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(NOCOTheme.teal)
                    .frame(width: 36, height: 36)
                    .background(NOCOTheme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .tint(NOCOTheme.teal)
        .padding(.vertical, 8)
    }
}
