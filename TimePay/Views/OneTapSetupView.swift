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

    private var appsDone: Bool { !gate.enabledApps.isEmpty }
    private var automationDone: Bool { settings.automationConfirmed }
    private var allDone: Bool { appsDone && automationDone }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroHeader
                        progressStrip
                        stepApps
                        stepAutomation
                        if allDone { finishCard }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, embeddedInTab ? 100 : 32)
                }

                if showCelebration {
                    celebrationOverlay
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding && !embeddedInTab {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Schließen") {
                            settings.selection()
                            dismiss()
                        }
                        .foregroundStyle(NOCOTheme.teal)
                    }
                }
            }
        }
    }

    private var heroHeader: some View {
        GlassCard(glow: NOCOTheme.lavender, padding: 22) {
            HStack(spacing: 18) {
                GateOrbView(isOpen: allDone, progress: allDone ? 1 : 0.35, size: 88)
                VStack(alignment: .leading, spacing: 6) {
                    Text("2 Schritte")
                        .font(.title2.weight(.bold))
                    Text("Apps wählen → Automation mit einer Aktion. Fertig.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                    HStack(spacing: 8) {
                        StatusBadge(
                            text: appsDone ? "\(gate.enabledApps.count) Apps" : "Apps offen",
                            color: appsDone ? NOCOTheme.mint : .orange,
                            icon: "apps.iphone"
                        )
                        StatusBadge(
                            text: automationDone ? "Automation OK" : "Automation offen",
                            color: automationDone ? NOCOTheme.mint : .orange,
                            icon: "bolt.fill"
                        )
                    }
                }
            }
        }
    }

    private var progressStrip: some View {
        HStack(spacing: 10) {
            progressChip("1 · Apps", done: appsDone, color: NOCOTheme.teal)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.25))
            progressChip("2 · Automation", done: automationDone, color: NOCOTheme.lavender)
            Spacer()
            SetupProgressRing(progress: setupFraction)
        }
    }

    private var setupFraction: Double {
        (appsDone ? 0.5 : 0) + (automationDone ? 0.5 : 0)
    }

    private func progressChip(_ label: String, done: Bool, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.caption.weight(.bold))
                .foregroundStyle(done ? NOCOTheme.mint : color.opacity(0.7))
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(done ? .white : .white.opacity(0.55))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(done ? NOCOTheme.mint.opacity(0.35) : .white.opacity(0.1), lineWidth: 1) }
    }

    private var stepApps: some View {
        SetupStepGlassCard(
            step: 1,
            title: "Apps schützen",
            subtitle: "Welche Apps sollen TimePay abfangen?",
            isDone: appsDone,
            accent: NOCOTheme.teal
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if appsDone {
                    FlowLayout(spacing: 8) {
                        ForEach(gate.enabledApps.prefix(8)) { app in
                            GlassPill(text: app.name, color: app.accent)
                        }
                        if gate.enabledApps.count > 8 {
                            GlassPill(text: "+\(gate.enabledApps.count - 8)", color: NOCOTheme.teal)
                        }
                    }
                } else {
                    Text("Tippe „Empfohlen“ — oder wähle im Tab Apps.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
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
                        Label("Apps-Tab", systemImage: "square.grid.3x3.fill")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(NOCOSecondaryButtonStyle())
                }
            }
        }
    }

    private var stepAutomation: some View {
        SetupStepGlassCard(
            step: 2,
            title: "Automation",
            subtitle: "Nur eine Aktion — kein Kurzbefehl bauen",
            isDone: automationDone,
            accent: NOCOTheme.lavender
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundStyle(NOCOTheme.teal)
                        .frame(width: 48, height: 48)
                        .background(NOCOTheme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gate durchsetzen")
                            .font(.headline.weight(.bold))
                        Text("TimePay → diese Aktion in der Automation")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Button {
                    openedAutomation = true
                    settings.impact(.medium)
                    ShortcutInstaller.openAutomations()
                } label: {
                    Label("Automation öffnen", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOPrimaryButtonStyle(enabled: appsDone))
                .disabled(!appsDone)

                VStack(spacing: 8) {
                    miniStep("App wird geöffnet", icon: "hand.tap.fill")
                    miniStep("Aktion: Gate durchsetzen", icon: "lock.shield.fill")
                    miniStep("Sofort ausführen AN", icon: "checkmark.seal.fill")
                }

                GlassCheckRow(
                    title: "Automation ist fertig",
                    detail: openedAutomation ? "Tippe zum Bestätigen" : "Zuerst „Automation öffnen“",
                    isOn: automationDone
                ) {
                    guard appsDone, openedAutomation else {
                        settings.rigid()
                        return
                    }
                    settings.automationConfirmed.toggle()
                    if settings.automationConfirmed {
                        settings.shortcutImported = true
                        settings.success()
                    } else {
                        settings.selection()
                    }
                }
            }
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
                Text("Teste eine geschützte App. Ohne Zeit öffnet sich TimePay.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)

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
            Color.black.opacity(0.4).ignoresSafeArea()
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
        settings.shortcutImported = true
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
