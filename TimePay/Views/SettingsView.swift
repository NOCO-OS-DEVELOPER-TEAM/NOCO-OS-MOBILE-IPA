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
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
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

                GlassCard(glow: NOCOTheme.teal) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("App-Icon (lang drücken)", systemImage: "app.badge.checkmark.fill")
                            .font(.subheadline.weight(.bold))
                        Text("Nur eine Kachel: „Apps sperren“. Zeit abbuchen & Co. erreichst du in der App selbst.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }

                GlassCard(glow: NOCOTheme.lavender) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Live Activity (Sperrbildschirm)", systemImage: "lock.display")
                            .font(.subheadline.weight(.bold))
                        Text("Auf deinem iPhone (ohne Dynamic Island) erscheint der Live-Timer auf dem Sperrbildschirm — Sekunde für Sekunde. Dynamic Island gibt es nur ab iPhone 14 Pro.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                        if LiveActivityManager.isSupported {
                            StatusBadge(text: "Aktiv", color: NOCOTheme.mint, icon: "checkmark.circle.fill")
                        } else {
                            StatusBadge(text: "In iOS-Einstellungen aktivieren", color: .orange, icon: "exclamationmark.triangle.fill")
                        }
                    }
                }

                GlassCard(glow: gate.setupCompleted ? NOCOTheme.mint : .orange) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Kurzbefehl-Setup")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            GlassPill(
                                text: gate.setupCompleted ? "Fertig" : "Offen",
                                color: gate.setupCompleted ? NOCOTheme.mint : .orange
                            )
                        }

                        setupChecklist

                        Button {
                            showSetup = true
                        } label: {
                            Label(gate.setupCompleted ? "Setup ansehen" : "Setup starten", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Widgets")
                            .font(.subheadline.weight(.bold))
                        Text("Zeitkonto · Schnellaktionen · Session — Guthaben: \(store.formattedBalance)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                        HStack(spacing: 10) {
                            widgetPreviewSmall
                            widgetPreviewMedium
                        }
                        Button {
                            gate.syncBlockedCountWidget()
                            store.syncWidgetData()
                        } label: {
                            Label("Widgets jetzt aktualisieren", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
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
                        Text("Version 2.9 · Apps sperren · Setup-Fix")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, TabBarMetrics.contentBottomInset)
            }
            .navigationTitle("Einstellungen")
            .appleGlassNavigation()
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
                Text("Kurzbefehl und Automation musst du danach erneut bestätigen.")
            }
        }
    }

    private var setupChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            checklistRow("Apps gewählt", done: !gate.enabledApps.isEmpty)
            checklistRow("Kurzbefehl importiert", done: settings.shortcutImported)
            checklistRow("Automation aktiv", done: settings.automationConfirmed)
        }
    }

    private func checklistRow(_ title: String, done: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? NOCOTheme.mint : .white.opacity(0.25))
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(done ? .white : .white.opacity(0.45))
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
            Label("Zeitkonto", systemImage: "hourglass.circle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(NOCOTheme.teal)
            Text(store.balanceDisplayNumber)
                .font(.title2.weight(.bold))
                .foregroundStyle(NOCOTheme.teal)
            Text("Min")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            LinearGradient(colors: [Color(red: 0.1, green: 0.14, blue: 0.28), NOCOTheme.deepNavy], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(NOCOTheme.teal.opacity(0.45), lineWidth: 1.5)
        }
    }

    private var widgetPreviewMedium: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schnellaktionen")
                .font(.caption.weight(.semibold))
            HStack(spacing: 6) {
                previewChip("Session", NOCOTheme.lavender)
                previewChip("Abbuchen", NOCOTheme.teal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            LinearGradient(colors: [Color(red: 0.1, green: 0.14, blue: 0.28), NOCOTheme.deepNavy], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(NOCOTheme.lavender.opacity(0.35), lineWidth: 1.5)
        }
    }

    private func previewChip(_ title: String, _ color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(color.opacity(0.25), in: Capsule())
            .foregroundStyle(color)
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
