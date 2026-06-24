import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
enum LiveActivityManager {
    static var lastError: String?

    static var isSupported: Bool {
        #if canImport(ActivityKit)
        return ActivityAuthorizationInfo().areActivitiesEnabled
        #else
        return false
        #endif
    }

    static func startUnlock(totalSeconds: Int) {
        startUnlock(remainingSeconds: totalSeconds, totalSeconds: totalSeconds)
    }

    static func startUnlock(remainingSeconds: Int, totalSeconds: Int) {
        #if canImport(ActivityKit)
        guard isSupported, remainingSeconds > 0 else { return }
        endAll()
        let total = max(totalSeconds, remainingSeconds)
        let end = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        let startedAt = end.addingTimeInterval(-TimeInterval(total))
        let attributes = TimePaySessionAttributes(totalSeconds: total, startedAt: startedAt)
        let state = TimePaySessionAttributes.ContentState(
            endDate: end,
            remainingSeconds: remainingSeconds,
            sessionTitle: "Freigabe aktiv",
            sessionKind: "unlock"
        )
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: end),
                pushType: nil
            )
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        #endif
    }

    static func startEarn(title: String, totalSeconds: Int) {
        #if canImport(ActivityKit)
        guard isSupported, totalSeconds > 0 else { return }
        endAll()
        let end = Date().addingTimeInterval(TimeInterval(totalSeconds))
        let attributes = TimePaySessionAttributes(totalSeconds: totalSeconds, startedAt: Date())
        let state = TimePaySessionAttributes.ContentState(
            endDate: end,
            remainingSeconds: totalSeconds,
            sessionTitle: title,
            sessionKind: "earn"
        )
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: end),
                pushType: nil
            )
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        #endif
    }

    static func update(remainingSeconds: Int, title: String, kind: String) {
        #if canImport(ActivityKit)
        guard isSupported else { return }
        let end = Date().addingTimeInterval(TimeInterval(max(0, remainingSeconds)))
        let state = TimePaySessionAttributes.ContentState(
            endDate: end,
            remainingSeconds: max(0, remainingSeconds),
            sessionTitle: title,
            sessionKind: kind
        )
        Task {
            for activity in Activity<TimePaySessionAttributes>.activities {
                await activity.update(.init(state: state, staleDate: end))
            }
        }
        #endif
    }

    static func endAll() {
        #if canImport(ActivityKit)
        Task {
            for activity in Activity<TimePaySessionAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}
