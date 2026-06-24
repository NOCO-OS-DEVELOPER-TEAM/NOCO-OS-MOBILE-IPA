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
        Task { await startUnlockAsync(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds) }
    }

    static func startEarn(title: String, totalSeconds: Int, endDate: Date? = nil) {
        Task { await startEarnAsync(title: title, totalSeconds: totalSeconds, endDate: endDate) }
    }

    static func syncUnlock(remainingSeconds: Int, totalSeconds: Int) {
        guard remainingSeconds > 0 else {
            endAll()
            return
        }
        let end = TimePaySharedStorage.unlockUntilDate
            ?? Date().addingTimeInterval(TimeInterval(remainingSeconds))
        let total = max(totalSeconds, remainingSeconds)
        let startedAt = end.addingTimeInterval(-TimeInterval(total))
        updateSession(
            endDate: end,
            remainingSeconds: remainingSeconds,
            title: "Freigabe aktiv",
            kind: "unlock",
            totalSeconds: total,
            startedAt: startedAt
        )
    }

    static func syncEarn(title: String, remainingSeconds: Int, totalSeconds: Int, endDate: Date) {
        guard remainingSeconds > 0 else {
            endAll()
            return
        }
        let total = max(totalSeconds, remainingSeconds)
        let startedAt = endDate.addingTimeInterval(-TimeInterval(total))
        updateSession(
            endDate: endDate,
            remainingSeconds: remainingSeconds,
            title: title,
            kind: "earn",
            totalSeconds: total,
            startedAt: startedAt
        )
    }

    static func endAll() {
        Task { await endAllAsync() }
    }

    // MARK: - Private

    #if canImport(ActivityKit)
    private static func startUnlockAsync(remainingSeconds: Int, totalSeconds: Int) async {
        guard isSupported, remainingSeconds > 0 else { return }
        await endAllAsync()

        let total = max(totalSeconds, remainingSeconds)
        let end = TimePaySharedStorage.unlockUntilDate
            ?? Date().addingTimeInterval(TimeInterval(remainingSeconds))
        let startedAt = end.addingTimeInterval(-TimeInterval(total))
        let attributes = TimePaySessionAttributes(totalSeconds: total, startedAt: startedAt)
        let state = TimePaySessionAttributes.ContentState(
            endDate: end,
            remainingSeconds: remainingSeconds,
            totalSeconds: total,
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
    }

    private static func startEarnAsync(title: String, totalSeconds: Int, endDate: Date?) async {
        guard isSupported, totalSeconds > 0 else { return }
        await endAllAsync()

        let end = endDate ?? Date().addingTimeInterval(TimeInterval(totalSeconds))
        let startedAt = end.addingTimeInterval(-TimeInterval(totalSeconds))
        let attributes = TimePaySessionAttributes(totalSeconds: totalSeconds, startedAt: startedAt)
        let state = TimePaySessionAttributes.ContentState(
            endDate: end,
            remainingSeconds: totalSeconds,
            totalSeconds: totalSeconds,
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
    }

    private static func updateSession(
        endDate: Date,
        remainingSeconds: Int,
        title: String,
        kind: String,
        totalSeconds: Int,
        startedAt: Date
    ) {
        guard isSupported else { return }
        let state = TimePaySessionAttributes.ContentState(
            endDate: endDate,
            remainingSeconds: max(0, remainingSeconds),
            totalSeconds: totalSeconds,
            sessionTitle: title,
            sessionKind: kind
        )
        Task {
            let activities = Activity<TimePaySessionAttributes>.activities
            if activities.isEmpty {
                let attributes = TimePaySessionAttributes(totalSeconds: totalSeconds, startedAt: startedAt)
                _ = try? Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: endDate),
                    pushType: nil
                )
                return
            }
            for activity in activities {
                await activity.update(.init(state: state, staleDate: endDate))
            }
        }
    }

    private static func endAllAsync() async {
        for activity in Activity<TimePaySessionAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif
}
