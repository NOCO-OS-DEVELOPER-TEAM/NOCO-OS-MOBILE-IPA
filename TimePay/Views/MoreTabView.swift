import SwiftUI
import WidgetKit

struct MoreTabView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var showDiagnosticShare = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                SectionHeader(
                    "iOS-Funktionen",
                    subtitle: "Widgets, Live Activities & mehr",
                    icon: "square.grid.2x2.fill"
                )

                iosFeatureCard(
                    icon: "rectangle.inset.filled",
                    title: "Home-Screen Widget",
                    detail: "Halte den Home-Screen gedrückt → Bearbeiten → Widget hinzufügen → TimePay → Zeitkonto.",
                    badge: "Widget",
                    color: NOCOTheme.teal
                )

                iosFeatureCard(
                    icon: "livephoto.play",
                    title: "Live Activities",
                    detail: "Bei Freigabe oder Focus-Session läuft ein echter Countdown auf dem Sperrbildschirm und in der Dynamic Island.",
                    badge: LiveActivityManager.isSupported ? "Aktiv" : "Aus",
                    color: NOCOTheme.lavender
                )

                iosFeatureCard(
                    icon: "bell.badge.fill",
                    title: "Mitteilungen",
                    detail: "Erinnerungen bei Ablauf, Focus-Start und „Mehr Zeit“ vom Sperrbildschirm.",
                    badge: "Push",
                    color: NOCOTheme.mint
                )

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Widget-Vorschau")
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
                        Text("Hilfe & Diagnose")
                            .font(.subheadline.weight(.bold))
                        Text("Wenn Bildschirmzeit nicht funktioniert, liegt es meist am SideStore-Signieren. Teile das Log für Support.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                        Button("Diagnose-Log teilen") { showDiagnosticShare = true }
                            .buttonStyle(NOCOPrimaryButtonStyle())
                    }
                }

                Text("Version 1.4 · NOCO-OS")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showDiagnosticShare) {
            ShareTextSheet(text: DiagnosticLog.export(screenTime: screenTime))
        }
    }

    private func iosFeatureCard(icon: String, title: String, detail: String, badge: String, color: Color) -> some View {
        GlassCard(glow: color, padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        GlassPill(text: badge, color: color)
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
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
        if store.unlockSessionRemaining > 0 {
            return "Freigabe aktiv"
        }
        if store.isEarningSessionActive {
            return "Focus läuft"
        }
        return "Bereit"
    }
}
