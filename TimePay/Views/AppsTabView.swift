import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppsTabView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var showAppPicker = false
    @State private var showDiagnosticShare = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                SectionHeader(
                    "Gesperrte Apps",
                    subtitle: "Wähle Apps, die TimePay blockiert",
                    icon: "lock.app.dashed.fill"
                )

                statusOverview

                if let error = screenTime.authError {
                    alertCard(title: "Hinweis", message: error, color: .orange, icon: "exclamationmark.circle.fill")
                }

                if screenTime.showSideloadHelp {
                    alertCard(
                        title: "SideStore / Bildschirmzeit",
                        message: screenTime.sideloadHelpSteps,
                        color: .orange,
                        icon: "exclamationmark.triangle.fill"
                    )
                    Button("Diagnose-Log teilen") { showDiagnosticShare = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NOCOTheme.teal)
                }

                GlassCard(glow: screenTime.shieldsActive ? .orange : NOCOTheme.teal) {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(screenTime.blockedAppCount)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                Text("Apps ausgewählt")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                if screenTime.shieldsActive {
                                    StatusBadge(text: "Aktiv gesperrt", color: .orange, icon: "lock.fill")
                                } else if store.unlockSessionRemaining > 0 {
                                    StatusBadge(text: "Freigabe läuft", color: NOCOTheme.teal, icon: "lock.open.fill")
                                } else if screenTime.needsAppSelection {
                                    StatusBadge(text: "Keine Apps", color: .orange, icon: "app.dashed")
                                } else {
                                    StatusBadge(text: "Bereit", color: NOCOTheme.mint, icon: "checkmark")
                                }
                            }
                        }

                        Button {
                            showAppPicker = true
                        } label: {
                            Label("Apps auswählen", systemImage: "plus.app.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NOCOPrimaryButtonStyle())
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(
                            icon: "shield.fill",
                            title: "Echter Sperrbildschirm",
                            detail: "Beim Öffnen einer gesperrten App erscheint der TimePay-Shield."
                        )
                        Divider().background(.white.opacity(0.1))
                        FeatureRow(
                            icon: "bell.badge.fill",
                            title: "Mehr Zeit",
                            detail: "Vom Shield: Benachrichtigung antippen → TimePay öffnet sich.",
                            color: NOCOTheme.lavender
                        )
                        Divider().background(.white.opacity(0.1))
                        FeatureRow(
                            icon: "arrow.clockwise",
                            title: "Auto-Sperre",
                            detail: "Nach Ablauf der Freigabe werden Apps automatisch wieder gesperrt.",
                            color: NOCOTheme.mint
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: Binding(
                get: { screenTime.selection },
                set: { screenTime.updateSelection($0) }
            )
        )
        .onChange(of: showAppPicker) { _, isOpen in
            if !isOpen { screenTime.noteAppPickerIssue() }
        }
        #endif
        .sheet(isPresented: $showDiagnosticShare) {
            ShareTextSheet(text: DiagnosticLog.export(screenTime: screenTime))
        }
    }

    private var statusOverview: some View {
        HStack(spacing: 10) {
            miniStat(
                value: screenTime.isAuthorized ? "OK" : "—",
                label: "Berechtigung",
                color: screenTime.isAuthorized ? NOCOTheme.mint : .orange
            )
            miniStat(
                value: "\(screenTime.blockedAppCount)",
                label: "Apps",
                color: NOCOTheme.teal
            )
            miniStat(
                value: screenTime.shieldsActive ? "An" : "Aus",
                label: "Sperre",
                color: screenTime.shieldsActive ? .orange : .white.opacity(0.6)
            )
        }
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func alertCard(title: String, message: String, color: Color, icon: String) -> some View {
        GlassCard(glow: color, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }
}
