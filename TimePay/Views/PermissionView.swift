import SwiftUI
import UIKit

struct PermissionView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @Environment(\.openURL) private var openURL
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            NOCOLogoMark(size: 72)

            Text("Bildschirmzeit erlauben")
                .font(.title2.bold())

            Text("TimePay braucht Zugriff auf die iOS-Bildschirmzeit, um ausgewaehlte Apps wirklich zu sperren und den TimePay-Sperrbildschirm anzuzeigen.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            GlassCard(glow: NOCOTheme.teal) {
                VStack(alignment: .leading, spacing: 14) {
                    permissionRow(icon: "lock.shield.fill", text: "Apps nach deiner Auswahl blockieren")
                    permissionRow(icon: "hourglass", text: "Zeit freischalten und automatisch wieder sperren")
                    permissionRow(icon: "bell.badge.fill", text: "Benachrichtigung zum Oeffnen von TimePay vom Sperrbildschirm")
                }
            }

            if let error = screenTime.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
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
                    Text("Berechtigung erteilen")
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

            Button("iOS-Einstellungen oeffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.55))

            Spacer()
        }
        .padding(24)
        .onAppear {
            screenTime.refreshAuthorizationStatus()
        }
    }

    private func permissionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(NOCOTheme.teal)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
