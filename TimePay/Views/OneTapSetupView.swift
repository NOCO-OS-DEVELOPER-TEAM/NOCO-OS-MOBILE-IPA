import SwiftUI
import UIKit
import AppIntents

struct OneTapSetupView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var isOnboarding: Bool = false
    var embeddedInTab: Bool = false
    var onFinish: (() -> Void)?

    @State private var phase = 0
    @State private var showCelebration = false
    @State private var copiedApps = false
    @State private var openedShortcuts = false
    @State private var confirmedShortcutBuilt = false

    private let phases = ["Willkommen", "Einrichtung", "Fertig"]

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                VStack(spacing: 0) {
                    phaseHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    phaseContent
                        .frame(maxHeight: .infinity)

                    bottomBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                .safeAreaPadding(.bottom, 8)

                if showCelebration {
                    celebrationOverlay
                }
            }
            .navigationTitle("NOCO Glass Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding && !embeddedInTab {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Schließen") { dismiss() }
                            .foregroundStyle(NOCOTheme.teal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case 0: welcomePhase
        case 1: combinedSetupPhase
        default: donePhase
        }
    }

    private var phaseHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<phases.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= phase ? NOCOTheme.teal : .white.opacity(0.12))
                        .frame(height: 4)
                }
            }
            HStack {
                SetupProgressRing(progress: settings.setupProgress)
                VStack(alignment: .leading, spacing: 2) {
                    Text(phases[phase])
                        .font(.subheadline.weight(.bold))
                    Text(phaseSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
            }
        }
    }

    private var phaseSubtitle: String {
        switch phase {
        case 1: return "Kurzbefehl + Automation — einmalig"
        default: return "Bereit zum Testen"
        }
    }

    private var welcomePhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                GateOrbView(isOpen: false, progress: 0, size: 150)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("NOCO Liquid Glass")
                        .font(.title.bold())
                    Text("Apps blockieren ohne Fokus-Modus. Ein Kurzbefehl prüft dein Zeitkonto — Apple erlaubt keinen automatischen Import, aber wir führen dich Schritt für Schritt.")
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
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }

    private var combinedSetupPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                if gate.enabledApps.isEmpty {
                    GlassCard(glow: .orange, padding: 14) {
                        Label("Zuerst Apps im Tab „Apps“ wählen (z. B. Empfohlen)", systemImage: "apps.iphone")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                } else {
                    GlassCard(glow: NOCOTheme.mint, padding: 14) {
                        Text("\(gate.enabledApps.count) Apps geschützt")
                            .font(.subheadline.weight(.bold))
                    }
                }

                Text("Kurzbefehl & Automation")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("iOS blockiert unsigned Shortcut-URLs. Stattdessen fügst du die TimePay-Aktion direkt in Kurzbefehle hinzu und erweiterst sie mit Wenn/URL.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))

                Button {
                    openedShortcuts = true
                    settings.impact(.medium)
                    ShortcutInstaller.openTimePayInShortcuts()
                } label: {
                    Label("TimePay Gate-Aktion hinzufügen", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOPrimaryButtonStyle())

                Button {
                    openedShortcuts = true
                    settings.impact(.medium)
                    ShortcutInstaller.openTimePayInShortcuts()
                } label: {
                    Label("Kurzbefehle öffnen", systemImage: "arrow.up.forward.app.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOSecondaryButtonStyle())

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dann im Kurzbefehl ergänzen")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.5))
                        ForEach(Array(ShortcutInstaller.shortcutRecipeSteps.enumerated()), id: \.offset) { _, step in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: step.icon)
                                    .foregroundStyle(NOCOTheme.teal)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.title)
                                        .font(.caption.weight(.semibold))
                                    Text(step.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                            }
                        }
                    }
                }

                Toggle(isOn: $confirmedShortcutBuilt) {
                    Text("Kurzbefehl „NOCO TimePay Gate“ ist fertig")
                        .font(.caption.weight(.semibold))
                }
                .tint(NOCOTheme.teal)
                .padding(.horizontal, 4)
                .onChange(of: confirmedShortcutBuilt) { _, on in
                    if on {
                        guard openedShortcuts else {
                            confirmedShortcutBuilt = false
                            settings.impact(.rigid)
                            return
                        }
                        settings.shortcutImported = true
                        settings.success()
                    } else {
                        settings.shortcutImported = false
                    }
                }

                if !openedShortcuts {
                    Text("Bitte zuerst „Kurzbefehle öffnen“ tippen.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Button {
                    ShortcutInstaller.openAutomations()
                } label: {
                    Label("Automation anlegen", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOSecondaryButtonStyle())

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Automation")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.5))
                        ForEach(Array(ShortcutInstaller.automationRecipeSteps.enumerated()), id: \.offset) { _, step in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: step.icon)
                                    .foregroundStyle(NOCOTheme.teal)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.title)
                                        .font(.caption.weight(.semibold))
                                    Text(step.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                            }
                        }
                    }
                }

                Button {
                    UIPasteboard.general.string = ShortcutInstaller.automationClipboardText(apps: gate.enabledApps)
                    copiedApps = true
                    settings.success()
                } label: {
                    Label(copiedApps ? "Kopiert!" : "Kurzanleitung kopieren", systemImage: "doc.on.doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOSecondaryButtonStyle())

                Toggle(isOn: Binding(
                    get: { settings.automationConfirmed },
                    set: { newValue in
                        guard !newValue || !gate.enabledApps.isEmpty else { return }
                        settings.automationConfirmed = newValue
                        if newValue { settings.success() }
                    }
                )) {
                    Text("Automation ist angelegt")
                        .font(.caption.weight(.semibold))
                }
                .tint(NOCOTheme.teal)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }

    private var donePhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                GateOrbView(isOpen: true, progress: 1, size: 130)
                Text("Alles bereit")
                    .font(.title.bold())
                Text("Teste mit einer geschützten App. TimePay schließt das Gate automatisch — oder beende früh per Live Activity.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)

                Button {
                    finishSetup()
                } label: {
                    Label("TimePay starten", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOPrimaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .padding(.bottom, 100)
        }
    }

    private var bottomBar: some View {
        HStack {
            if phase > 0 && phase < 2 {
                Button("Zurück") {
                    withAnimation(.spring(response: 0.35)) { phase -= 1 }
                }
                .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            if phase < 2 {
                Button(phase == 0 ? "Los geht's" : "Weiter") {
                    withAnimation(.spring(response: 0.35)) { phase += 1 }
                }
                .buttonStyle(NOCOPrimaryButtonStyle(enabled: canAdvance))
                .frame(maxWidth: 180)
                .disabled(!canAdvance)
            }
        }
    }

    private var canAdvance: Bool {
        switch phase {
        case 1:
            return !gate.enabledApps.isEmpty
                && settings.shortcutImported
                && confirmedShortcutBuilt
                && openedShortcuts
                && settings.automationConfirmed
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
