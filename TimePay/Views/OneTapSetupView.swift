import SwiftUI
import UIKit

struct OneTapSetupView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var isOnboarding: Bool = false
    var embeddedInTab: Bool = false
    var onFinish: (() -> Void)?
    var onSwitchToAppsTab: (() -> Void)?

    @State private var showCelebration = false
    @State private var openedAutomation = false
    @State private var openedShortcutImport = false

    private var appsDone: Bool { !gate.enabledApps.isEmpty }
    private var shortcutDone: Bool { settings.shortcutImported }
    private var automationDone: Bool { settings.automationConfirmed }
    private var allDone: Bool { appsDone && shortcutDone && automationDone }

    var body: some View {
        NavigationStack {
            ZStack {
                if !embeddedInTab {
                    LiquidGlassBackground(animated: false)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        statusHero
                        progressStrip
                        stepApps
                        stepShortcut
                        stepAutomation
                        if allDone { finishCard }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, embeddedInTab
                        ? (shortcutDone ? TabBarMetrics.contentBottomInset : TabBarMetrics.contentBottomInset + 56)
                        : 40)
                }

                if showCelebration {
                    celebrationOverlay
                }
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
            .safeAreaInset(edge: .bottom) {
                if embeddedInTab && !shortcutDone {
                    stickyImportBar
                        .padding(.bottom, TabBarMetrics.barHeight + TabBarMetrics.bottomPadding)
                } else if !embeddedInTab && !shortcutDone {
                    stickyImportBar
                }
            }
        }
    }

    private var stickyImportBar: some View {
        VStack(spacing: 0) {
            Divider().background(.white.opacity(0.08))
            Button {
                importShortcut()
            } label: {
                Label("Kurzbefehl jetzt hinzufügen", systemImage: "arrow.down.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(NOCOPrimaryButtonStyle(enabled: appsDone))
            .disabled(!appsDone)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(NOCOTheme.glassBorder, lineWidth: 1)
                    }
            }
            .padding(.horizontal, 14)
        }
    }

    private var statusHero: some View {
        GlassCard(glow: allDone ? NOCOTheme.mint : NOCOTheme.lavender, padding: 20) {
            HStack(spacing: 16) {
                GateOrbView(isOpen: allDone, progress: setupFraction, size: 80)
                VStack(alignment: .leading, spacing: 8) {
                    Text("3 Schritte")
                        .font(.title3.weight(.bold))
                    Text("Apps → Kurzbefehl importieren → Automation. Alles vorgefertigt.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                    HStack(spacing: 6) {
                        miniBadge("Apps", done: appsDone)
                        miniBadge("Kurzbefehl", done: shortcutDone)
                        miniBadge("Auto", done: automationDone)
                    }
                }
            }
        }
    }

    private func miniBadge(_ label: String, done: Bool) -> some View {
        Text(label)
            .font(.caption2.weight(.bold))
            .foregroundStyle(done ? NOCOTheme.mint : .white.opacity(0.45))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((done ? NOCOTheme.mint : Color.white).opacity(done ? 0.15 : 0.06), in: Capsule())
    }

    private var progressStrip: some View {
        HStack(spacing: 8) {
            progressChip("1", label: "Apps", done: appsDone, color: NOCOTheme.teal)
            glassChevron
            progressChip("2", label: "Kurzbefehl", done: shortcutDone, color: NOCOTheme.lavender)
            glassChevron
            progressChip("3", label: "Automation", done: automationDone, color: NOCOTheme.mint)
            Spacer()
            SetupProgressRing(progress: setupFraction)
        }
    }

    private var glassChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.22))
    }

    private var setupFraction: Double {
        (appsDone ? 1.0 : 0) / 3.0 + (shortcutDone ? 1.0 : 0) / 3.0 + (automationDone ? 1.0 : 0) / 3.0
    }

    private func progressChip(_ number: String, label: String, done: Bool, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(done ? NOCOTheme.mint.opacity(0.2) : color.opacity(0.12))
                    .frame(width: 28, height: 28)
                if done {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(NOCOTheme.mint)
                } else {
                    Text(number)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                }
            }
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(done ? .white : .white.opacity(0.45))
        }
    }

    private var stepApps: some View {
        SetupStepGlassCard(
            step: 1,
            title: "Apps schützen",
            subtitle: "Welche Apps blockiert TimePay?",
            isDone: appsDone,
            accent: NOCOTheme.teal
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if appsDone {
                    FlowLayout(spacing: 8) {
                        ForEach(gate.enabledApps.prefix(6)) { app in
                            GlassPill(text: app.name, color: app.accent)
                        }
                        if gate.enabledApps.count > 6 {
                            GlassPill(text: "+\(gate.enabledApps.count - 6)", color: NOCOTheme.teal)
                        }
                    }
                }
                HStack(spacing: 10) {
                    Button {
                        settings.impact(.medium)
                        withAnimation(.spring(response: 0.35)) {
                            gate.applySelectionPreset(.recommended)
                        }
                        settings.success()
                    } label: {
                        Label("Empfohlen", systemImage: "sparkles")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(NOCOPrimaryButtonStyle())
                    Button {
                        settings.selection()
                        onSwitchToAppsTab?()
                    } label: {
                        Label("Apps", systemImage: "square.grid.3x3.fill")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(NOCOSecondaryButtonStyle())
                }
            }
        }
    }

    private var stepShortcut: some View {
        SetupStepGlassCard(
            step: 2,
            title: "Kurzbefehl hinzufügen",
            subtitle: "Vorgefertigt wie im App Store — ein Tippen, dann „Hinzufügen“",
            isDone: shortcutDone,
            accent: NOCOTheme.lavender
        ) {
            VStack(alignment: .leading, spacing: 14) {
                GlassHeroImportButton(
                    title: "NOCO TimePay Gate",
                    subtitle: "Öffnet TimePay automatisch — funktioniert auch bei Sideload"
                ) {
                    importShortcut()
                }

                Text("Kurzbefehle öffnet sich → tippe oben „Hinzufügen“. Fertig.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))

                GateShortcutShareLink()

                shortcutTroubleshootCard

                GlassCheckRow(
                    title: "Kurzbefehl ist in Kurzbefehle",
                    detail: openedShortcutImport ? "Tippe zum Bestätigen" : "Zuerst „Kurzbefehl hinzufügen“",
                    isOn: shortcutDone
                ) {
                    guard openedShortcutImport else {
                        settings.rigid()
                        return
                    }
                    settings.shortcutImported.toggle()
                    if settings.shortcutImported {
                        settings.success()
                    } else {
                        settings.selection()
                    }
                }
            }
        }
    }

    private var shortcutTroubleshootCard: some View {
        GlassCard(glow: NOCOTheme.coral, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Import klappt nicht?", systemImage: "lifepreserver.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(NOCOTheme.coral)

                VStack(alignment: .leading, spacing: 8) {
                    troubleshootStep("1", "Tippe „Kurzbefehl-Datei teilen“ → Kurzbefehle wählen → Hinzufügen")
                    troubleshootStep("2", "Oder in Kurzbefehle: + → „URL“ → timepay://gate einfügen")
                    troubleshootStep("3", "Name vergeben: NOCO TimePay Gate")
                    troubleshootStep("4", "In der Automation: Aktion „Kurzbefehl ausführen“ (nicht App-Aktion)")
                }

                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = ShortcutInstaller.gateDeepLink
                        settings.success()
                    } label: {
                        Label("URL kopieren", systemImage: "doc.on.doc")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(NOCOSecondaryButtonStyle())

                    Button {
                        ShortcutInstaller.importViaShareSheet()
                        openedShortcutImport = true
                        settings.impact(.medium)
                    } label: {
                        Label("Datei teilen", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(NOCOSecondaryButtonStyle())
                }
            }
        }
    }

    private func troubleshootStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption2.weight(.bold))
                .foregroundStyle(NOCOTheme.teal)
                .frame(width: 20, height: 20)
                .background(NOCOTheme.teal.opacity(0.15), in: Circle())
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private var stepAutomation: some View {
        SetupStepGlassCard(
            step: 3,
            title: "Automation",
            subtitle: "Startet den importierten Kurzbefehl",
            isDone: automationDone,
            accent: NOCOTheme.mint
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    openedAutomation = true
                    settings.impact(.medium)
                    ShortcutInstaller.openAutomations()
                } label: {
                    Label("Automation öffnen", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOPrimaryButtonStyle(enabled: shortcutDone))
                .disabled(!shortcutDone)

                VStack(spacing: 8) {
                    miniStep("App wird geöffnet", icon: "hand.tap.fill")
                    miniStep("Kurzbefehl: NOCO TimePay Gate", icon: "play.fill")
                    miniStep("Sofort ausführen AN", icon: "checkmark.seal.fill")
                }

                GlassCheckRow(
                    title: "Automation ist fertig",
                    detail: openedAutomation ? "Tippe zum Bestätigen" : "Zuerst Automation öffnen",
                    isOn: automationDone
                ) {
                    guard shortcutDone, openedAutomation else {
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

    private func importShortcut() {
        guard appsDone else {
            settings.rigid()
            return
        }
        openedShortcutImport = true
        settings.impact(.medium)
        ShortcutInstaller.importPrebuiltGateShortcut { _ in
            settings.selection()
        }
    }

    private func miniStep(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(NOCOTheme.teal)
                .frame(width: 22)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var finishCard: some View {
        GlassCard(glow: NOCOTheme.mint) {
            VStack(spacing: 16) {
                Label("Alles bereit", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(NOCOTheme.mint)
                Text("Öffne eine geschützte App zum Testen.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                Button {
                    finishSetup()
                } label: {
                    Label(isOnboarding ? "TimePay starten" : "Setup abschließen", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
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
