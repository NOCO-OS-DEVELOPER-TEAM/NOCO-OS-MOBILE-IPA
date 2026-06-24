import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct TimePayWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        TimePayBalanceWidget()
        #if canImport(ActivityKit)
        TimePayLiveActivityWidget()
        #endif
    }
}

struct WidgetSnapshot {
    let minutes: Int
    let streak: Int
    let blocked: Int
    let sessionKind: String
    let sessionRemaining: Int
    let sessionTitle: String

    static func load() -> WidgetSnapshot {
        let d = TimePaySharedStorage.defaults
        return WidgetSnapshot(
            minutes: max(d?.integer(forKey: TimePayKeys.balanceKey) ?? 20, 0),
            streak: d?.integer(forKey: TimePayKeys.widgetStreakDays) ?? 0,
            blocked: d?.integer(forKey: TimePayKeys.widgetBlockedCount) ?? 0,
            sessionKind: d?.string(forKey: TimePayKeys.widgetSessionKind) ?? "none",
            sessionRemaining: d?.integer(forKey: TimePayKeys.widgetSessionRemaining) ?? 0,
            sessionTitle: d?.string(forKey: TimePayKeys.widgetSessionTitle) ?? ""
        )
    }
}

#if canImport(ActivityKit)
struct TimePayLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimePaySessionAttributes.self) { context in
            let teal = Color(red: 0.35, green: 0.88, blue: 0.82)
            let isUnlock = context.state.sessionKind == "unlock"

            HStack(spacing: 14) {
                Image(systemName: isUnlock ? "lock.open.fill" : "hourglass.circle.fill")
                    .font(.title2)
                    .foregroundStyle(teal)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.sessionTitle)
                        .font(.headline)
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .font(.title.monospacedDigit().weight(.bold))
                        .foregroundStyle(teal)
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.04, green: 0.06, blue: 0.12))
        } dynamicIsland: { context in
            let teal = Color(red: 0.35, green: 0.88, blue: 0.82)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "hourglass.circle.fill")
                        .foregroundStyle(teal)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .monospacedDigit()
                        .font(.title3.weight(.bold))
                        .foregroundStyle(teal)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.sessionTitle)
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "hourglass")
                    .foregroundStyle(teal)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .font(.caption2)
            } minimal: {
                Image(systemName: "hourglass")
            }
        }
    }
}
#endif

struct TimePayBalanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimePayBalance", provider: BalanceProvider()) { entry in
            TimePayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Zeitkonto")
        .description("Guthaben, Session und Streak auf einen Blick.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct TimePayWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BalanceEntry

    private let teal = Color(red: 0.35, green: 0.88, blue: 0.82)
    private let navy = Color(red: 0.04, green: 0.06, blue: 0.12)

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .accessoryCircular:
            circularLockView
        case .accessoryRectangular:
            rectangularLockView
        case .accessoryInline:
            Text("\(entry.minutes) Min · TimePay")
        default:
            smallView
        }
    }

    private var smallView: some View {
        ZStack {
            widgetBackground
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("TimePay")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    if entry.streak >= 2 {
                        Text("🔥\(entry.streak)")
                            .font(.caption2)
                    }
                }
                Text("\(entry.minutes)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(teal)
                Text("Minuten")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                if entry.sessionKind != "none" {
                    Text(sessionLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(teal.opacity(0.9))
                }
            }
            .padding()
        }
    }

    private var mediumView: some View {
        ZStack {
            widgetBackground
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zeitkonto")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                    Text("\(entry.minutes) Min")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(teal)
                    if entry.sessionKind != "none" {
                        Text(sessionLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.68, green: 0.62, blue: 1.0))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    statPill("+\(entry.streak)", label: "Streak")
                    statPill("\(entry.blocked)", label: "Apps")
                    if entry.sessionRemaining > 0 {
                        Text(formatTime(entry.sessionRemaining))
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(teal)
                    }
                }
            }
            .padding()
        }
    }

    private var circularLockView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text("\(entry.minutes)")
                    .font(.headline.weight(.bold))
                Text("Min")
                    .font(.caption2)
            }
        }
    }

    private var rectangularLockView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TimePay")
                    .font(.caption2)
                Text("\(entry.minutes) Min Guthaben")
                    .font(.headline)
                if entry.sessionKind != "none" {
                    Text(sessionLabel)
                        .font(.caption2)
                }
            }
            Spacer()
        }
    }

    private var widgetBackground: some View {
        ContainerRelativeShape()
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.11, blue: 0.2), navy],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private func statPill(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var sessionLabel: String {
        if entry.sessionKind == "unlock" {
            return "Freigabe · \(formatTime(entry.sessionRemaining))"
        }
        if entry.sessionKind == "earn" {
            return "\(entry.sessionTitle) · \(formatTime(entry.sessionRemaining))"
        }
        return ""
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

struct BalanceEntry: TimelineEntry {
    let date: Date
    let minutes: Int
    let streak: Int
    let blocked: Int
    let sessionKind: String
    let sessionRemaining: Int
    let sessionTitle: String
}

struct BalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        makeEntry(from: .init(minutes: 20, streak: 3, blocked: 2, sessionKind: "none", sessionRemaining: 0, sessionTitle: ""))
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        completion(makeEntry(from: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let snap = WidgetSnapshot.load()
        let entry = makeEntry(from: snap)
        let next = snap.sessionKind == "none"
            ? Date().addingTimeInterval(900)
            : Date().addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry(from snap: WidgetSnapshot) -> BalanceEntry {
        BalanceEntry(
            date: Date(),
            minutes: snap.minutes,
            streak: snap.streak,
            blocked: snap.blocked,
            sessionKind: snap.sessionKind,
            sessionRemaining: snap.sessionRemaining,
            sessionTitle: snap.sessionTitle
        )
    }
}
