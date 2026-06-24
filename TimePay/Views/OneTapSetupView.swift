import SwiftUI
import UIKit

struct OneTapSetupView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var isOnboarding: Bool = false
    var onFinish: (() -> Void)?

    @State private var phase = 0
    @State private var showCelebration = false
    @State private var copiedApps = false

    private let phases = ["Willkommen", "Kurzbefehl", "Automation", "Fertig"]

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                VStack(spacing: 0) {
                    phaseHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    TabView(selection: $phase) {
                        welcomePhase.tag(0)
                        shortcutPhase.tag(1)
                        automationPhase.tag(2)
                        donePhase.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.45), value: phase)

                    bottomBar
                        .padding(20)
                }

                if showCelebration {
                    celebrationOverlay
                }
            }
            .navigationTitle("NOCO Glass Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Schließen") { dismiss() }
                            .foregroundStyle(NOCOTheme.teal)
                    }
                }
            }
        }
    }

    private var phaseHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<phases.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= phase ? NOCOTheme.teal : .white.opacity(0.12))
                        .frame(height: 4)
                        .overlay {
                            if index == phase {
                                Capsule()
                                    .fill(NOCOTheme.mint.opacity(0.5))
                                    .blur(radius: 4)
                            }
                        }
                }
            }
            HStack {
                SetupProgressRing(progress: settings.setupProgress)
                VStack(alignment: .leading, spacing: 2) {
                    Text(phases[phase])
                        .font(.subheadline.weight(.bold))
                    Text("Fast fertig — nur Kurzbefehle bestätigen")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
            }
        }
    }

    private var welcomePhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                GateOrbView(isOpen: false, progress: 0, size: 160)
                    .padding(.top, 12)

                VStack(spacing: 8) {
                    Text("NOCO Liquid Glass")
                        .font(.title.bold())
                    Text("Apps blockieren — ohne Fokus-Modus. Ein Kurzbefehl prüft dein Zeitkonto und leitet nur um, wenn nötig.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                }

                GlassCard(glow: NOCOTheme.teal) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(ShortcutInstaller.quickSetupSteps.enumerated()), id: \.offset) { _, step in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: step.icon)
                                    .foregroundStyle(NOCOTheme.teal)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.title)
                                        .font(.caption.weight(.bold))
                                    Text(step.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var shortcutPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(NOCOTheme.holoGradient)
                    .symbolEffect(.pulse, value: phase)

                Text("Kurzbefehl importieren")
                    .font(.title3.bold())

                Text("Tippe unten — Kurzbefehle öffnet sich. Einmal „Hinzufügen“ tippen, fertig. TimePay übernimmt den Rest im Hintergrund.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)

                Button {
                    settings.impact(.medium)
                    ShortcutInstaller.importGateShortcut()
                } label: {
                    Label("Kurzbefehl importieren", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOPrimaryButtonStyle())

                if let url = ShortcutInstaller.bundledShortcutURL() {
                    ShareLink(item: url) {
                        Label("Oder Datei teilen", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NOCOSecondaryButtonStyle())
                }

                GlassCard(glow: settings.shortcutImported ? NOCOTheme.mint : .orange, padding: 14) {
                    HStack {
                        Image(systemName: settings.shortcutImported ? "checkmark.seal.fill" : "hand.tap.fill")
                            .foregroundStyle(settings.shortcutImported ? NOCOTheme.mint : .orange)
                        Text(settings.shortcutImported ? "Kurzbefehl bestätigt" : "Nach dem Import hier bestätigen")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        if !settings.shortcutImported {
                            Button("Erledigt") {
                                settings.shortcutImported = true
                                settings.success()
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(NOCOTheme.teal)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var automationPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Text("Automation verknüpfen")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Wähle in Kurzbefehle dieselben Apps wie hier in TimePay. Danach läuft alles automatisch — kein manuelles An/Aus.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))

                if gate.enabledApps.isEmpty {
                    GlassCard(glow: .orange, padding: 14) {
                        Label("Aktiviere zuerst Apps im Tab „Apps“", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Deine geschützten Apps")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.5))
                            FlowLayout(spacing: 8) {
                                ForEach(gate.enabledApps) { app in
                                    GlassPill(text: app.name, color: app.accent)
                                }
                            }
                        }
                    }
                }

                Button {
                    let text = ShortcutInstaller.automationClipboardText(apps: gate.enabledApps)
                    UIPasteboard.general.string = text
                    copiedApps = true
                    settings.success()
                } label: {
                    Label(copiedApps ? "Kopiert!" : "Anleitung + App-Namen kopieren", systemImage: "doc.on.doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOSecondaryButtonStyle())

                Button {
                    ShortcutInstaller.openShortcutsApp()
                } label: {
                    Label("Kurzbefehle öffnen", systemImage: "arrow.up.forward.app.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOPrimaryButtonStyle())

                GlassCard(glow: settings.automationConfirmed ? NOCOTheme.mint : .orange, padding: 14) {
                    HStack {
                        Image(systemName: settings.automationConfirmed ? "checkmark.seal.fill" : "gearshape.2.fill")
                            .foregroundStyle(settings.automationConfirmed ? NOCOTheme.mint : .orange)
                        Text(settings.automationConfirmed ? "Automation bestätigt" : "Automation angelegt? Bestätigen")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        if !settings.automationConfirmed {
                            Button("Erledigt") {
                                settings.automationConfirmed = true
                                gate.markSetupCompleted()
                                settings.success()
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(NOCOTheme.teal)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var donePhase: some View {
        VStack(spacing: 28) {
            Spacer()
            GateOrbView(isOpen: true, progress: 1, size: 140)
            Text("Alles bereit")
                .font(.title.bold())
            Text("Öffne eine geschützte App zum Testen. TimePay schließt das Gate automatisch, wenn die Zeit abläuft.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            Button {
                finishSetup()
            } label: {
                Label("TimePay starten", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NOCOPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    private var bottomBar: some View {
        HStack {
            if phase > 0 && phase < 3 {
                Button("Zurück") {
                    withAnimation { phase -= 1 }
                }
                .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            if phase < 3 {
                Button(phase == 0 ? "Los geht's" : "Weiter") {
                    withAnimation { phase += 1 }
                }
                .buttonStyle(NOCOPrimaryButtonStyle(enabled: canAdvance))
                .frame(maxWidth: 180)
                .disabled(!canAdvance)
            }
        }
    }

    private var canAdvance: Bool {
        switch phase {
        case 1: return settings.shortcutImported
        case 2: return settings.automationConfirmed || gate.enabledApps.isEmpty
        default: return true
        }
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(NOCOTheme.mint)
                    .symbolEffect(.pulse)
                Text("Setup abgeschlossen")
                    .font(.title3.bold())
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .transition(.opacity)
    }

    private func finishSetup() {
        gate.markSetupCompleted()
        settings.hasSeenOnboarding = true
        settings.success()
        withAnimation { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if isOnboarding {
                onFinish?()
            } else {
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
