import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
enum LiveActivityManager {
    static var isSupported: Bool {
        #if canImport(ActivityKit)
        return ActivityAuthorizationInfo().areActivitiesEnabled
        #else
        return false
        #endif
    }

    static func startUnlock(totalSeconds: Int) {
        #if canImport(ActivityKit)
        guard isSupported, totalSeconds > 0 else { return }
        endAll()
        let end = Date().addingTimeInterval(TimeInterval(totalSeconds))
        let attributes = TimePaySessionAttributes(totalSeconds: totalSeconds, startedAt: Date())
        let state = TimePaySessionAttributes.ContentState(
            endDate: end,
            remainingSeconds: totalSeconds,
            sessionTitle: "Apps freigeschaltet",
            sessionKind: "unlock"
        )
        _ = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: end),
            pushType: nil
        )
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
        _ = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: end),
            pushType: nil
        )
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
