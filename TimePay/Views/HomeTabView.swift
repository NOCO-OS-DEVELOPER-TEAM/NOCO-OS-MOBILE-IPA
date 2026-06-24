import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject private var store: TimePayStore
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var settings: AppSettings
    @State private var showSetup = false

    private var buttonsEnabled: Bool { store.canBookTime }
    private var sessionUrgent: Bool {
        (store.unlockSessionRemaining > 0 && store.unlockSessionRemaining <= 60)
            || (store.isEarningSessionActive && store.earnSessionRemaining <= 60)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
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
                .padding(.bottom, TabBarMetrics.contentBottomInset)
            }
            .navigationTitle("Übersicht")
            .appleGlassNavigation()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NOCOLogoMark(size: 28)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    SetupProgressRing(progress: settings.setupProgress)
                }
            }
            .sheet(isPresented: $showSetup) {
                OneTapSetupView()
            }
        }
    }

    // header removed — large title + toolbar logo

    private var gateHero: some View {
        GlassCard(glow: ShortcutGateManager.isGateOpen ? NOCOTheme.teal : NOCOTheme.lavender, padding: 20) {
            HStack(spacing: 18) {
                GateOrbView(
                    isOpen: ShortcutGateManager.isGateOpen,
                    progress: store.unlockSessionRemaining > 0 ? store.unlockProgress : 0,
                    size: 110,
                    flashExpired: store.sessionExpiredFlash,
                    isUrgent: sessionUrgent && ShortcutGateManager.isGateOpen,
                    sessionStart: store.activeSessionStartDate,
                    sessionEnd: store.activeSessionEndDate
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
                        Text("Fast fertig — Kurzbefehl & Automation")
                            .font(.subheadline.weight(.bold))
                        Text("Vorgefertigter Kurzbefehl mit einem Tippen — dann Automation anlegen.")
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
                    if store.isSessionActive,
                       let start = store.activeSessionStartDate,
                       let end = store.activeSessionEndDate {
                        SmoothSessionProgressRing(
                            start: start,
                            end: end,
                            color: sessionUrgent ? NOCOTheme.coral : (store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender),
                            lineWidth: 6
                        )
                        .frame(width: 148, height: 148)
                    }
                    VStack(spacing: 6) {
                        if store.isSessionActive, let end = store.activeSessionEndDate {
                            LiveCountdownText(
                                endDate: end,
                                font: .system(size: 40, weight: .bold, design: .monospaced),
                                color: sessionUrgent ? NOCOTheme.coral : (store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender)
                            )
                            Text(store.unlockSessionRemaining > 0 ? "Freigabe läuft" : "Session läuft")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.55))
                        } else {
                            Text(store.balanceDisplayNumber)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            Text(store.balanceHalfMinutes % 2 == 0 ? "Minuten Guthaben" : "Minuten Guthaben")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(NOCOTheme.teal)
                        }
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
        if store.isSessionActive, store.activeSessionEndDate != nil {
            if store.unlockSessionRemaining > 0 {
                return "Apps freigeschaltet — Gate schließt automatisch"
            }
            return "\(store.selectedTask.title) — danach Gutschrift aufs Konto"
        }
        return "\(gate.enabledApps.count) Apps geschützt · Zeitkonto für Freigaben"
    }

    private var activeSessionCard: some View {
        GlassCard(glow: store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender) {
            VStack(spacing: 12) {
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
                    if let end = store.activeSessionEndDate, store.isSessionActive {
                        LiveCountdownText(
                            endDate: end,
                            font: .system(.title3, design: .monospaced).weight(.bold),
                            color: sessionUrgent ? NOCOTheme.coral : (store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender)
                        )
                    } else {
                        Text(formatSeconds(store.unlockSessionRemaining > 0 ? store.unlockSessionRemaining : store.earnSessionRemaining))
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(store.unlockSessionRemaining > 0 ? NOCOTheme.teal : NOCOTheme.lavender)
                    }
                }

                if store.unlockSessionRemaining > 0 {
                    Button {
                        settings.impact(.medium)
                        store.endUnlockSessionEarly()
                    } label: {
                        Label("Freigabe beenden & Rest erstatten", systemImage: "stop.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NOCOSecondaryButtonStyle())
                }
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
                        ForEach([Double(settings.defaultUnlockMinutes), 10.0, 15.0].uniqued(), id: \.self) { min in
                            Button {
                                store.applySpendPreset(min)
                                store.tryOpenUnlockSheet()
                            } label: {
                                VStack(spacing: 4) {
                                    Text(min.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(min))" : String(format: "%.1f", min).replacingOccurrences(of: ".", with: ","))
                                        .font(.title3.weight(.bold))
                                    Text("Min")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(NOCOSecondaryButtonStyle(enabled: min <= store.maxSpendMinutes))
                            .disabled(min > store.maxSpendMinutes)
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

private extension Array where Element == Double {
    func uniqued() -> [Double] {
        var seen = Set<Double>()
        return filter { seen.insert($0).inserted }
    }
}
