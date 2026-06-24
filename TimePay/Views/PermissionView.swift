import SwiftUI

struct PermissionView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var isRequesting = false
    @State private var showDiagnosticShare = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                Spacer(minLength: 24)

                NOCOLogoMark(size: 80)

                VStack(spacing: 8) {
                    Text("Willkommen bei TimePay")
                        .font(.title2.bold())
                    Text("Dein Zeitkonto für gesperrte Apps")
                        .font(.subheadline)
                        .foregroundStyle(NOCOTheme.teal)
                }

                GlassCard(glow: NOCOTheme.teal) {
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "lock.shield.fill", title: "Apps sperren", detail: "Wähle Apps, die wirklich blockiert werden.")
                        FeatureRow(icon: "hourglass", title: "Zeit freischalten", detail: "Minuten abbuchen → Apps öffnen → automatisch wieder sperren.", color: NOCOTheme.lavender)
                        FeatureRow(icon: "bell.badge.fill", title: "Mitteilungen", detail: "Vom Sperrbildschirm direkt zurück in TimePay.", color: NOCOTheme.mint)
                        FeatureRow(icon: "livephoto.play", title: "Live Timer", detail: "Countdown auf Sperrbildschirm & Dynamic Island.", color: NOCOTheme.coral)
                    }
                }

                if let error = screenTime.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Button {
                    Task {
                        isRequesting = true
                        await screenTime.requestAuthorization()
                        isRequesting = false
                    }
                } label: {
                    if isRequesting {
                        ProgressView().tint(.black)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Bildschirmzeit erlauben", systemImage: "checkmark.shield.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(NOCOPrimaryButtonStyle())
                .disabled(isRequesting)

                Button("Status aktualisieren") {
                    screenTime.refreshAuthorizationStatus()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(NOCOTheme.teal)

                Button("Berechtigung zurücksetzen") {
                    Task { await screenTime.revokeAuthorization() }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

                if screenTime.showSideloadHelp || !screenTime.isAuthorized {
                    GlassCard(glow: .orange, padding: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bildschirmzeit einrichten")
                                .font(.subheadline.weight(.bold))
                            Text(screenTime.sideloadHelpSteps)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                }

                Button("Diagnose-Log teilen") { showDiagnosticShare = true }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NOCOTheme.teal)

                Text("In den normalen App-Einstellungen gibt es keinen Bildschirmzeit-Schalter — das ist bei Sideload-Apps normal.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 24)
            }
            .padding(24)
        }
        .sheet(isPresented: $showDiagnosticShare) {
            ShareTextSheet(text: DiagnosticLog.export(screenTime: screenTime))
        }
        .onAppear {
            screenTime.refreshAuthorizationStatus()
            if !screenTime.isAuthorized {
                screenTime.showSideloadHelp = true
            }
        }
    }
}
