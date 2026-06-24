import Foundation

#if canImport(FamilyControls)
import FamilyControls
#endif

enum DiagnosticLog {
    static func export(screenTime: ScreenTimeManager) -> String {
        var lines: [String] = []
        let formatter = ISO8601DateFormatter()
        lines.append("NOCO TimePay Diagnose")
        lines.append("Zeit: \(formatter.string(from: Date()))")
        lines.append("Version: 1.4")
        lines.append("---")
        lines.append("Bildschirmzeit erlaubt: \(screenTime.isAuthorized)")
        lines.append("Apps gesperrt: \(screenTime.blockedAppCount)")
        lines.append("Sperre aktiv: \(screenTime.shieldsActive)")
        lines.append("SideStore-Hilfe: \(screenTime.showSideloadHelp)")
        #if canImport(FamilyControls)
        lines.append("Auth-Status: \(String(describing: AuthorizationCenter.shared.authorizationStatus))")
        #endif
        if let error = screenTime.authError {
            lines.append("Fehler: \(error)")
        }
        lines.append("---")
        lines.append("Freigabe aktiv: \(TimePaySharedStorage.isUnlocked)")
        lines.append("Freigabe Rest (s): \(TimePaySharedStorage.remainingUnlockSeconds())")
        lines.append("Guthaben (Min): \(TimePaySharedStorage.defaults?.integer(forKey: TimePayKeys.balanceKey) ?? 0)")
        lines.append("Live Activities: \(LiveActivityManager.isSupported)")
        lines.append("---")
        lines.append(screenTime.sideloadHelpSteps)
        return lines.joined(separator: "\n")
    }
}
