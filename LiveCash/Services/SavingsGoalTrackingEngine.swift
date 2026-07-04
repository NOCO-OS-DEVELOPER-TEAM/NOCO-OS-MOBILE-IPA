import Foundation

@MainActor
enum SavingsGoalTrackingEngine {
    static func evaluate(goal: SavingsGoal, monthlySavingsRate: Double, settings: SavingsSettings) -> [GoalTrackingAlert] {
        var alerts: [GoalTrackingAlert] = []
        guard settings.smartInsightsEnabled || settings.progressAlerts else { return alerts }

        if settings.progressAlerts, goal.notifyAt50Percent,
           goal.progressPercent >= 50, goal.progressPercent < 100,
           !goal.notifiedMilestones.contains(50) {
            alerts.append(.milestone(percent: 50, goalName: goal.name))
        }

        if goal.progressPercent >= 100, !goal.notifiedMilestones.contains(100) {
            alerts.append(.completed(goalName: goal.name))
        }

        let pace = goal.paceStatus(referenceMonthlySavings: monthlySavingsRate)
        switch pace {
        case .slow where goal.notifySlowProgress && settings.slowProgressAlerts:
            alerts.append(.slowProgress(goalName: goal.name, percent: goal.progressPercent))
        case .fast where goal.notifyFastProgress:
            alerts.append(.fastProgress(goalName: goal.name, percent: goal.progressPercent))
        default:
            break
        }

        if settings.nearGoalAlerts, goal.progressPercent >= 85, goal.progressPercent < 100 {
            alerts.append(.nearGoal(goalName: goal.name, percent: goal.progressPercent))
        }

        return alerts
    }

    static func milestonesToRecord(for alerts: [GoalTrackingAlert]) -> [Int] {
        alerts.compactMap { alert in
            switch alert {
            case .milestone(let percent, _): return percent
            case .completed: return 100
            default: return nil
            }
        }
    }
}

enum GoalTrackingAlert: Equatable {
    case contributed(amount: Double, goalName: String, percent: Int)
    case milestone(percent: Int, goalName: String)
    case completed(goalName: String)
    case slowProgress(goalName: String, percent: Int)
    case fastProgress(goalName: String, percent: Int)
    case nearGoal(goalName: String, percent: Int)

    var title: String {
        switch self {
        case .contributed(let amount, let name, let percent):
            return "+\(Int(amount))€ → \(name)"
        case .milestone(_, let name):
            return "50% bei \(name) 🎯"
        case .completed(let name):
            return "Sparziel erreicht! 🎉"
        case .slowProgress(let name, _):
            return "Tempo bei \(name)"
        case .fastProgress(let name, _):
            return "Starkes Tempo bei \(name)"
        case .nearGoal(let name, _):
            return "Fast geschafft: \(name)"
        }
    }

    var body: String {
        switch self {
        case .contributed(_, _, let percent):
            return "Du bist jetzt bei \(percent)% deines Sparziels."
        case .milestone:
            return "Halbzeit — weiter so!"
        case .completed(let name):
            return "\(name) ist vollständig finanziert."
        case .slowProgress(_, let percent):
            return "Du liegst bei \(percent)% — etwas mehr Tempo würde helfen."
        case .fastProgress(_, let percent):
            return "Du bist bei \(percent)% — über dem Zieltempo."
        case .nearGoal(_, let percent):
            return "Nur noch \(100 - percent)% bis zum Ziel."
        }
    }
}
