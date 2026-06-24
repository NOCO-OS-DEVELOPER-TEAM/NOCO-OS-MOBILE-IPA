import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var settings: AppSettings
    @State private var showSetup = false

    private var buttonsEnabled: Bool { store.canBookTime }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                header
                gateHero
                if !gate.setupCompleted {
                    setupCard
                }
                balanceCard
                if store.isSessionActive {
                    activeSessionCard
                }
                quickActions
                statsGrid
                presetRow
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showSetup) {
            OneTapSetupView()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                NOCOLogoMark(size: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TimePay")
                        .font(.title2.weight(.bold))
                    Text("NOCO Liquid Glass")
                        .font(.caption)
                        .foregroundStyle(NOCOTheme.teal)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if store.streakDays >= 2 {
                    StatusBadge(text: "\(store.streakDays) Tage", color: NOCOTheme.lavender, icon: "flame.fill")
                }
                SetupProgressRing(progress: settings.setupProgress)
            }
        }
        .padding(.top, 8)
    }

    private var gateHero: some View {
        GlassCard(glow: ShortcutGateManager.isGateOpen ? NOCOTheme.teal : NOCOTheme.lavender, padding: 20) {
            HStack(spacing: 18) {
                GateOrbView(
                    isOpen: ShortcutGateManager.isGateOpen,
                    progress: store.unlockSessionRemaining > 0 ? store.unlockProgress : 0,
                    size: 110
                )
                VStack(alignment: .leading, spacing: 10) {
                    Text("Gate-Status")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(ShortcutGateManager.isGateOpen ? "Apps frei" : "Geschützt")
                        .font(.title3.weight(.bold))
                    StatusBadge(
                        text: gate.gateStatusLabel,
                        color: ShortcutGateManager.isGateOpen ? NOCOTheme.teal : .orange,
                        icon: ShortcutGateManager.isGateOpen ? "lock.open.fill" : "lock.fill"
                    )
                    Text("\(gate.enabledApps.count) Apps im Gate")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var setupCard: some View {
        Button {
            showSetup = true
        } label: {
            GlassCard(glow: NOCOTheme.coral, padding: 16) {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(NOCOTheme.coral)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fast fertig — Setup abschließen")
                            .font(.subheadline.weight(.bold))
                        Text("Kurzbefehl importieren, einmal bestätigen, läuft im Hintergrund.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var balanceCard: some View {
        GlassCard(glow: NOCOTheme.teal, padding: 24) {
            VStack(spacing: 16) {
                HStack {
                    Text("Zeitkonto")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    if store.unlockSessionRemaining > 0 {
                        StatusBadge(text: "Freigabe", color: NOCOTheme.teal, icon: "lock.open.fill")
                    } else if store.isEarningSessionActive {
                        StatusBadge(text: "Session", color: NOCOTheme.lavender, icon: "hourglass")
                    }
                }

                ZStack {
                    if store.isSessionActive {
                        LiquidProgressRing(
                            progress: store.unlockSessionRemaining > 0 ? store.unlockProgress : store.earnProgress,
                            color: store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender,
                            lineWidth: 6
                        )
                        .frame(width: 148, height: 148)
                    }
                    VStack(spacing: 4) {
                        Text("\(store.balanceMinutes)")
                            .font(.system(size: store.isSessionActive ? 44 : 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("Minuten")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(NOCOTheme.teal)
                    }
                }

                Text(heroSubtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var heroSubtitle: String {
        if store.unlockSessionRemaining > 0 {
            return "Freigabe endet in \(formatSeconds(store.unlockSessionRemaining))"
        }
        if store.isEarningSessionActive {
            return "Session läuft — \(formatSeconds(store.earnSessionRemaining)) verbleibend"
        }
        return "Guthaben für geschützte Apps — Gate steuert den Zugang automatisch"
    }

    private var activeSessionCard: some View {
        GlassCard(glow: store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender) {
            HStack(spacing: 14) {
                Image(systemName: store.unlockSessionRemaining > 0 ? "lock.open.fill" : store.selectedTask.icon)
                    .font(.title2)
                    .foregroundStyle(store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.unlockSessionRemaining > 0 ? "Apps freigeschaltet" : store.selectedTask.title)
                        .font(.subheadline.weight(.bold))
                    Text(store.sessionStatusText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Text(formatSeconds(store.unlockSessionRemaining > 0 ? store.unlockSessionRemaining : store.earnSessionRemaining))
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .foregroundStyle(store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender)
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Aktionen", subtitle: "Zeit buchen oder verdienen", icon: "bolt.fill")
            ActionTile(
                title: "Zeit abbuchen",
                subtitle: "Apps für Minuten freischalten",
                icon: "lock.open.fill",
                gradient: LinearGradient(colors: [NOCOTheme.teal, NOCOTheme.mint], startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                settings.impact(.medium)
                store.tryOpenUnlockSheet()
            }
            .disabled(!buttonsEnabled)
            .opacity(buttonsEnabled ? 1 : 0.45)

            ActionTile(
                title: "Zeit gutschreiben",
                subtitle: "Produktiv-Session starten",
                icon: "plus.circle.fill",
                gradient: LinearGradient(colors: [NOCOTheme.lavender, NOCOTheme.coral.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                settings.impact(.medium)
                store.tryOpenEarnSheet()
            }
            .disabled(!buttonsEnabled)
            .opacity(buttonsEnabled ? 1 : 0.45)
        }
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Heute", subtitle: "Deine Statistik", icon: "chart.bar.fill")
            HStack(spacing: 10) {
                MetricTile(value: "+\(store.earnedToday)", label: "Verdient", icon: "arrow.up.circle.fill", color: NOCOTheme.mint)
                MetricTile(value: "-\(store.spentToday)", label: "Ausgegeben", icon: "arrow.down.circle.fill", color: NOCOTheme.teal)
                MetricTile(value: "\(gate.enabledApps.count)", label: "Apps", icon: "apps.iphone", color: .orange)
            }
        }
    }

    private var presetRow: some View {
        Group {
            if buttonsEnabled && store.balanceMinutes > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Schnellwahl", subtitle: "Häufige Freigabe-Zeiten", icon: "timer")
                    HStack(spacing: 10) {
                        ForEach([settings.defaultUnlockMinutes, 10, 15].uniqued(), id: \.self) { min in
                            Button {
                                store.applySpendPreset(min)
                                store.tryOpenUnlockSheet()
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(min)")
                                        .font(.title3.weight(.bold))
                                    Text("Min")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(NOCOSecondaryButtonStyle(enabled: min <= store.balanceMinutes))
                            .disabled(min > store.balanceMinutes)
                        }
                    }
                }
            }
        }
    }

    private func formatSeconds(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
