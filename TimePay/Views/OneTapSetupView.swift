import SwiftUI
import UIKit

/// Setup in 3 klaren Schritten — nur Automation, kein Kurzbefehl-Import.
struct OneTapSetupView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var isOnboarding: Bool = false
    var embeddedInTab: Bool = false
    var onFinish: (() -> Void)?
    var onSwitchToAppsTab: (() -> Void)?

    @State private var showCelebration = false
    @State private var openedShortcuts = false

    private var appsDone: Bool { !gate.enabledApps.isEmpty }
    private var automationDone: Bool { settings.automationConfirmed }
    private var allDone: Bool { appsDone && automationDone }

    private var setupFraction: Double {
        (appsDone ? 1.0 / 3.0 : 0) + (openedShortcuts ? 1.0 / 3.0 : 0) + (automationDone ? 1.0 / 3.0 : 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground(animated: false)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroCard
                        step1Apps
                        step2Automation
                        step3TimePay
                        if allDone { finishCard }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, embeddedInTab ? TabBarMetrics.contentBottomInset : 40)
                }

                if showCelebration { celebrationOverlay }
            }
            .navigationTitle("Setup")
            .appleGlassNavigation()
            .toolbar {
                if !isOnboarding && !embeddedInTab {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") {
                            settings.selection()
                            dismiss()
                        }
                        .foregroundStyle(NOCOTheme.teal)
                    }
                }
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        GlassCard(glow: allDone ? NOCOTheme.mint : NOCOTheme.lavender, padding: 20) {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    SetupProgressRing(progress: setupFraction)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("3 Schritte — fertig")
                            .font(.title3.weight(.bold))
                        Text("Apps sperren in unter 2 Minuten")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer(minLength: 0)
                }

                LiquidGlassInfoBanner(
                    icon: "checkmark.shield.fill",
                    title: "So funktioniert die Sperre",
                    message: "Automation öffnet timepay://gate. Ohne Freigabe → TimePay. Mit Freigabe → nichts passiert.",
                    accent: NOCOTheme.mint
                )

                Button {
                    UIPasteboard.general.string = ShortcutInstaller.setupClipboardText()
                    settings.success()
                } label: {
                    Label("Anleitung kopieren", systemImage: "doc.on.doc")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(NOCOSecondaryButtonStyle())
            }
        }
    }

    // MARK: - Schritt 1

    private var step1Apps: some View {
        SetupStepGlassCard(
            step: 1,
            title: "Apps in TimePay wählen",
            subtitle: "Welche Apps sollen gestoppt werden?",
            isDone: appsDone,
            accent: NOCOTheme.teal
        ) {
            VStack(alignment: .leading, spacing: 14) {
                GlassTapStep(number: 1, tap: "Empfohlene Apps aktivieren", detail: "Der grüne Button unten — fertig.", accent: NOCOTheme.teal, isLast: true)

                if appsDone {
                    FlowLayout(spacing: 8) {
                        ForEach(gate.enabledApps.prefix(8)) { app in
                            GlassPill(text: app.name, color: app.accent)
                        }
                        if gate.enabledApps.count > 8 {
                            GlassPill(text: "+\(gate.enabledApps.count - 8)", color: NOCOTheme.teal)
                        }
                    }
                }

                Button {
                    settings.impact(.medium)
                    withAnimation(.spring(response: 0.35)) {
                        gate.applySelectionPreset(.recommended)
                    }
                    settings.success()
                } label: {
                    Label("Empfohlene Apps aktivieren", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(NOCOPrimaryButtonStyle())

                if let onSwitchToAppsTab {
                    Button {
                        settings.selection()
                        onSwitchToAppsTab()
                    } label: {
                        Text("Andere Apps? → Apps-Tab")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(NOCOTheme.teal.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Schritt 2

    private var step2Automation: some View {
        SetupStepGlassCard(
            step: 2,
            title: "Automation anlegen",
            subtitle: "In der Kurzbefehle-App — genau so tippen",
            isDone: openedShortcuts,
            accent: NOCOTheme.lavender
        ) {
            VStack(alignment: .leading, spacing: 4) {
                GlassTapStep(number: 1, tap: "Automation", detail: "Unten in der Kurzbefehle-App", accent: NOCOTheme.lavender)
                GlassTapStep(number: 2, tap: "＋", detail: "Oben rechts", accent: NOCOTheme.lavender)
                GlassTapStep(number: 3, tap: "App", detail: "Als Auslöser wählen", accent: NOCOTheme.lavender)
                GlassTapStep(number: 4, tap: "Instagram, App Store …", detail: "Eine geschützte App auswählen", accent: NOCOTheme.lavender)
                GlassTapStep(number: 5, tap: "Ist geöffnet", detail: "Dann Weiter", accent: NOCOTheme.lavender, isLast: true)

                Button {
                    openedShortcuts = true
                    settings.impact(.medium)
                    ShortcutInstaller.openAutomations()
                } label: {
                    Label("Kurzbefehle öffnen", systemImage: "arrow.up.forward.app.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(NOCOPrimaryButtonStyle(enabled: appsDone))
                .disabled(!appsDone)
            }
        }
    }

    // MARK: - Schritt 3

    private var step3TimePay: some View {
        SetupStepGlassCard(
            step: 3,
            title: "TimePay verbinden",
            subtitle: "URL eintragen — funktioniert immer",
            isDone: automationDone,
            accent: NOCOTheme.mint
        ) {
            VStack(alignment: .leading, spacing: 4) {
                GlassTapStep(number: 1, tap: "Aktion hinzufügen", accent: NOCOTheme.mint)
                GlassTapStep(number: 2, tap: "URL", detail: "In der Suche tippen", accent: NOCOTheme.mint)
                GlassTapStep(number: 3, tap: "URL öffnen", accent: NOCOTheme.mint)
                GlassTapStep(number: 4, tap: ShortcutInstaller.gateURL, detail: "Genau so eintragen", accent: NOCOTheme.mint)
                GlassTapStep(number: 5, tap: "Sofort ausführen", detail: "Einschalten · Vor Ausführen fragen AUS", accent: NOCOTheme.mint, isLast: true)

                Button {
                    ShortcutInstaller.copyGateURL()
                    settings.success()
                } label: {
                    Label("URL kopieren", systemImage: "doc.on.doc")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(NOCOSecondaryButtonStyle())

                LiquidGlassInfoBanner(
                    icon: "info.circle.fill",
                    title: "TimePay in der Liste?",
                    message: "Statt URL kannst du auch TimePay → „Apps sperren“ wählen. URL ist der sichere Weg.",
                    accent: NOCOTheme.lavender
                )

                LiquidGlassInfoBanner(
                    icon: "hand.tap.fill",
                    title: "Test",
                    message: "App ohne Freigabe öffnen → TimePay erscheint. Mit Freigabe → App bleibt offen.",
                    accent: NOCOTheme.teal
                )

                GlassCheckRow(
                    title: "Fertig — Automation läuft",
                    detail: automationDone ? "Alles eingerichtet" : "Zum Bestätigen antippen",
                    isOn: automationDone
                ) {
                    guard appsDone else {
                        settings.rigid()
                        return
                    }
                    settings.automationConfirmed.toggle()
                    if settings.automationConfirmed {
                        settings.success()
                    } else {
                        settings.selection()
                    }
                }
            }
        }
    }

    // MARK: - Abschluss

    private var finishCard: some View {
        GlassCard(glow: NOCOTheme.mint) {
            VStack(spacing: 16) {
                Label("Sperre ist aktiv", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(NOCOTheme.mint)
                Text("Für jede geschützte App brauchst du eine eigene Automation — oder wähle mehrere Apps auf einmal beim Auslöser.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                Button {
                    finishSetup()
                } label: {
                    Label(isOnboarding ? "TimePay starten" : "Setup abschließen", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(NOCOPrimaryButtonStyle())
            }
        }
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(NOCOTheme.mint)
                    .symbolEffect(.bounce, value: showCelebration)
                Text("Setup abgeschlossen")
                    .font(.title3.bold())
            }
            .padding(36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(NOCOTheme.glassBorder, lineWidth: 1.2)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func finishSetup() {
        gate.markSetupCompleted()
        settings.hasSeenOnboarding = true
        settings.success()
        withAnimation(.spring(response: 0.4)) { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            if isOnboarding {
                onFinish?()
            } else if !embeddedInTab {
                dismiss()
            }
        }
    }
}

/// Simple flow layout for app name pills.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
