import SwiftUI

struct ShortcutsGuideTabView: View {
    @EnvironmentObject private var gate: ShortcutGateManager
    @State private var showGuideShare = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    SectionHeader(
                        "Automation",
                        subtitle: "Einmal einrichten — kein Kurzbefehl-Import",
                        icon: "bolt.fill"
                    )

                    if !gate.setupCompleted {
                        GlassCard(glow: .orange, padding: 16) {
                            Label("Einrichtung noch nicht abgeschlossen", systemImage: "exclamationmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }

                    GlassCard(glow: NOCOTheme.teal) {
                        Text(ShortcutGateManager.howItWorks)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    GlassCard {
                        Text(ShortcutGateManager.shortcutBuildGuide)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    Button("Anleitung teilen") { showGuideShare = true }
                        .buttonStyle(NOCOPrimaryButtonStyle())

                    Button {
                        gate.markSetupCompleted()
                    } label: {
                        Label("Als eingerichtet markieren", systemImage: "checkmark.seal")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NOCOSecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .navigationTitle("Kurzbefehl")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showGuideShare) {
                ShareTextSheet(text: ShortcutGateManager.shortcutBuildGuide)
            }
        }
    }
}
