import ActivityKit
import Foundation

struct SavingsGoalActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var goalName: String
        var progressPercent: Int
        var currentAmount: Double
        var targetAmount: Double
        var warning: String?
    }

    var goalId: String
}

@MainActor
enum SavingsLiveActivityService {
    static var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func updateOrStart(goal: SavingsGoal, warning: String? = nil) {
        guard isSupported else { return }
        let state = SavingsGoalActivityAttributes.ContentState(
            goalName: goal.name,
            progressPercent: goal.progressPercent,
            currentAmount: goal.currentAmount,
            targetAmount: goal.targetAmount,
            warning: warning
        )
        let activities = Activity<SavingsGoalActivityAttributes>.activities
        if let existing = activities.first(where: { $0.attributes.goalId == goal.id.uuidString }) {
            Task { await existing.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }
        guard goal.progressPercent < 100 else { return }
        let attributes = SavingsGoalActivityAttributes(goalId: goal.id.uuidString)
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activity optional — ignore on unsupported devices
        }
    }

    static func endAll() {
        for activity in Activity<SavingsGoalActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
