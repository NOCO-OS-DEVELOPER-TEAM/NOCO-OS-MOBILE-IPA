import SwiftUI

struct ShortcutsSetupView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var showGuideShare = false

    private let steps = [
        "Überblick",
        "Kurzbefehl",
        "Automation",
        "Apps wählen",
        "Fertig",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NOCOTheme.midnight.ignoresSafeArea()
                LiquidGlassBackground()

                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    TabView(selection: $step) {
                        overviewStep.tag(0)
                        shortcutStep.tag(1)
                        automationStep.tag(2)
                        appsStep.tag(3)
                        doneStep.tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    navigationButtons
                        .padding(20)
                }
            }
            .navigationTitle("Kurzbefehl-Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                        .foregroundStyle(NOCOTheme.teal)
                }
            }
            .sheet(isPresented: $showGuideShare) {
                ShareTextSheet(text: ShortcutGateManager.shortcutBuildGuide)
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? NOCOTheme.teal : .white.opacity(0.15))
                    .frame(height: 4)
            }
        }
    }

    private var overviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                NOCOLogoMark(size: 64)
                    .frame(maxWidth: .infinity)

                Text("Blockieren ohne Fokus")
                    .font(.title2.bold())

                Text("Fokus-Modus blendet Apps nur aus — das wollen wir nicht. Stattdessen nutzt du eine Kurzbefehl-Automation: Beim Öffnen einer App prüft TimePay, ob du Freigabe-Zeit hast.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))

                GlassCard(glow: NOCOTheme.teal) {
                    VStack(alignment: .leading, spacing: 12) {
                        flowRow(number: "1", text: "Instagram öffnen → Automation startet")
                        flowRow(number: "2", text: "Kurzbefehl fragt TimePay: Gate offen?")
                        flowRow(number: "3", text: "Nein → TimePay öffnet sich, Minuten abbuchen")
                        flowRow(number: "4", text: "Ja → App bleibt offen bis Timer endet")
                    }
                }

                alertBox(
                    title: "Kein Fokus nötig",
                    message: "Du brauchst keinen Fokus-Modus und keine Bildschirmzeit-Berechtigung.",
                    color: NOCOTheme.mint
                )
            }
            .padding(24)
        }
    }

    private var shortcutStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Schritt 1: Kurzbefehl")
                    .font(.title3.bold())

                instructionBlock(
                    title: "Neuen Kurzbefehl anlegen",
                    lines: [
                        "Kurzbefehle-App → Bibliothek → +",
                        "Name: NOCO TimePay Gate",
                        "Aktion: „TimePay Gate prüfen“ (App TimePay)",
                        "Aktion „Wenn“ → Ergebnis ist falsch",
                        "Dann: URL öffnen → timepay://gate",
                        "Dann: Zum Home-Bildschirm",
                        "Sonst-Zweig: leer lassen",
                    ]
                )

                Button("Anleitung teilen / kopieren") { showGuideShare = true }
                    .buttonStyle(NOCOSecondaryButtonStyle())

                alertBox(
                    title: "Tipp",
                    message: "Die Aktion „TimePay Gate prüfen“ erscheint nach der ersten Installation von TimePay unter Kurzbefehle → Apps.",
                    color: NOCOTheme.lavender
                )
            }
            .padding(24)
        }
    }

    private var automationStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Schritt 2: Automation")
                    .font(.title3.bold())

                instructionBlock(
                    title: "Persönliche Automation",
                    lines: [
                        "Kurzbefehle → Automation → + → App",
                        "Apps auswählen (Instagram, TikTok, …)",
                        "„Ist geöffnet“",
                        "Aktion: Kurzbefehl „NOCO TimePay Gate“ ausführen",
                        "„Sofort ausführen“ einschalten",
                        "„Vor Ausführen fragen“ ausschalten",
                    ]
                )

                alertBox(
                    title: "Mehrere Apps",
                    message: "Du kannst in einem Automation-Schritt mehrere Apps auf einmal auswählen — oder für jede App eine eigene Automation anlegen.",
                    color: NOCOTheme.teal
                )

                alertBox(
                    title: "Freigabe-Zeit",
                    message: "Während TimePay eine Freigabe läuft, lässt der Kurzbefehl Apps durch. Du musst die Automation nicht manuell ausschalten.",
                    color: NOCOTheme.mint
                )
            }
            .padding(24)
        }
    }

    private var appsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Schritt 3: Apps abstimmen")
                    .font(.title3.bold())

                Text("Diese Apps hast du in TimePay aktiviert — dieselben solltest du in der Automation auswählen:")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))

                if gate.enabledApps.isEmpty {
                    alertBox(
                        title: "Keine Apps aktiv",
                        message: "Geh zum Tab „Apps“ und aktiviere mindestens eine App.",
                        color: .orange
                    )
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(gate.enabledApps) { app in
                                Label(app.name, systemImage: app.symbol)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var doneStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(NOCOTheme.mint)

                Text("Bereit zum Testen")
                    .font(.title2.bold())

                Text("Öffne eine geschützte App. Wenn alles stimmt, springt sie zurück und TimePay öffnet sich. Buche Minuten — dann sollte die App wieder gehen.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                Button {
                    gate.markSetupCompleted()
                    dismiss()
                } label: {
                    Label("Einrichtung abgeschlossen", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NOCOPrimaryButtonStyle())
            }
            .padding(24)
        }
    }

    private var navigationButtons: some View {
        HStack {
            if step > 0 {
                Button("Zurück") { withAnimation { step -= 1 } }
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            if step < steps.count - 1 {
                Button("Weiter") { withAnimation { step += 1 } }
                    .buttonStyle(NOCOPrimaryButtonStyle())
                    .frame(maxWidth: 160)
            }
        }
    }

    private func flowRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(NOCOTheme.teal.opacity(0.2), in: Circle())
                .foregroundStyle(NOCOTheme.teal)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private func instructionBlock(title: String, lines: [String]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(NOCOTheme.teal)
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private func alertBox(title: String, message: String, color: Color) -> some View {
        GlassCard(glow: color, padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }
}
