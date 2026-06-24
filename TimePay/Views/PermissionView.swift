import SwiftUI

struct PermissionView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            NOCOLogoMark(size: 72)

            Text("Bildschirmzeit erlauben")
                .font(.title2.bold())

            Text("TimePay braucht Zugriff auf die iOS-Bildschirmzeit, um ausgewählte Apps wirklich zu sperren und den TimePay-Sperrbildschirm anzuzeigen.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            GlassCard(glow: NOCOTheme.teal) {
                VStack(alignment: .leading, spacing: 14) {
                    permissionRow(icon: "lock.shield.fill", text: "Apps nach deiner Auswahl blockieren")
                    permissionRow(icon: "hourglass", text: "Zeit freischalten und automatisch wieder sperren")
                    permissionRow(icon: "bell.badge.fill", text: "Benachrichtigung wenn die Zeit abläuft")
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

            Spacer()
        }
        .padding(24)
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
