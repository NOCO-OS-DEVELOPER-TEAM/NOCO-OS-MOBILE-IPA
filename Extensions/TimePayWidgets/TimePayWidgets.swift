import SwiftUI
import WidgetKit
import AppIntents

#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Widget palette

enum WidgetPalette {
    static let teal = Color(red: 0.15, green: 0.96, blue: 0.88)
    static let tealDeep = Color(red: 0.08, green: 0.72, blue: 0.66)
    static let lavender = Color(red: 0.72, green: 0.58, blue: 1.0)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.48)
    static let mint = Color(red: 0.45, green: 1.0, blue: 0.82)
    static let navy = Color(red: 0.02, green: 0.04, blue: 0.1)
    static let navyLight = Color(red: 0.1, green: 0.14, blue: 0.28)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.18, blue: 0.34),
                navy,
                Color(red: 0.04, green: 0.08, blue: 0.16),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var glowGradient: RadialGradient {
        RadialGradient(
            colors: [teal.opacity(0.35), .clear],
            center: .topLeading,
            startRadius: 8,
            endRadius: 140
        )
    }
}

extension View {
    @ViewBuilder
    func timePayWidgetBackground() -> some View {
        containerBackground(for: .widget) {
            ZStack {
                WidgetPalette.backgroundGradient
                WidgetPalette.glowGradient
                LinearGradient(
                    colors: [WidgetPalette.lavender.opacity(0.12), .clear],
                    startPoint: .bottomTrailing,
                    endPoint: .topLeading
                )
            }
        }
    }

    @ViewBuilder
    func widgetVibrantBorder(_ color: Color = WidgetPalette.teal) -> some View {
        overlay {
            ContainerRelativeShape()
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.7), color.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }
}

// MARK: - Widget intents

struct WidgetOpenUnlockIntent: AppIntent {
    static var title: LocalizedStringResource = "Zeit abbuchen"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        TimePaySharedStorage.defaults?.set("unlock", forKey: TimePayKeys.pendingDeepLinkKey)
        return .result()
    }
}

struct WidgetOpenEarnIntent: AppIntent {
    static var title: LocalizedStringResource = "Session starten"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        TimePaySharedStorage.defaults?.set("earn", forKey: TimePayKeys.pendingDeepLinkKey)
        return .result()
    }
}

#if canImport(ActivityKit)
struct EndUnlockSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Freigabe beenden"
    static var description = IntentDescription("Beendet die Freigabe und erstattet ungenutzte Zeit.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        TimePaySharedStorage.defaults?.set(true, forKey: TimePayKeys.pendingEndUnlockKey)
        return .result()
    }
}
#endif

@main
struct TimePayWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        TimePayBalanceWidget()
        TimePayQuickActionsWidget()
        TimePaySessionWidget()
        #if canImport(ActivityKit)
        TimePayLiveActivityWidget()
        #endif
    }
}

struct WidgetSnapshot {
    let minutes: Int
    let balanceHalfMinutes: Int
    let streak: Int
    let blocked: Int
    let sessionKind: String
    let sessionRemaining: Int
    let sessionTitle: String
    let sessionEndDate: Date?

    static func load() -> WidgetSnapshot {
        let d = TimePaySharedStorage.defaults
        let half = d?.integer(forKey: TimePayKeys.widgetBalanceHalfMinutes) ?? 0
        let whole = max(d?.integer(forKey: TimePayKeys.balanceKey) ?? 20, 0)
        let endTS = d?.double(forKey: TimePayKeys.widgetSessionEndTimestamp) ?? 0
        let endDate = endTS > 0 ? Date(timeIntervalSince1970: endTS) : nil
        return WidgetSnapshot(
            minutes: whole,
            balanceHalfMinutes: half > 0 ? half : whole * 2,
            streak: d?.integer(forKey: TimePayKeys.widgetStreakDays) ?? 0,
            blocked: d?.integer(forKey: TimePayKeys.widgetBlockedCount) ?? 0,
            sessionKind: d?.string(forKey: TimePayKeys.widgetSessionKind) ?? "none",
            sessionRemaining: d?.integer(forKey: TimePayKeys.widgetSessionRemaining) ?? 0,
            sessionTitle: d?.string(forKey: TimePayKeys.widgetSessionTitle) ?? "",
            sessionEndDate: endDate
        )
    }

    var balanceLabel: String { TimePayFormat.halfMinutesNumber(balanceHalfMinutes) }
    var hasSession: Bool { sessionKind != "none" }
}

// MARK: - Zeitkonto

struct TimePayBalanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimePayBalance", provider: BalanceProvider()) { entry in
            BalanceWidgetView(entry: entry)
                .timePayWidgetBackground()
                .widgetVibrantBorder(WidgetPalette.teal)
        }
        .configurationDisplayName("Zeitkonto")
        .description("Guthaben, Streak und aktive Session.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct BalanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BalanceEntry

    var body: some View {
        switch family {
        case .systemMedium: mediumView
        case .accessoryCircular: circularView
        case .accessoryRectangular: rectangularView
        case .accessoryInline: Text("\(entry.balanceLabel) Min · TimePay")
        default: smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "hourglass.circle.fill")
                    .foregroundStyle(WidgetPalette.teal)
                Text("TimePay")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                if entry.streak >= 2 { Text("🔥\(entry.streak)").font(.caption2) }
            }
            Text(entry.balanceLabel)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.teal)
                .shadow(color: WidgetPalette.teal.opacity(0.45), radius: 8)
            Text("Min Guthaben")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
            if entry.hasSession {
                Text(sessionLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WidgetPalette.lavender)
            }
        }
        .padding()
        .widgetURL(URL(string: "timepay://unlock")!)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Zeitkonto", systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text("\(entry.balanceLabel) Min")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.teal)
                if entry.hasSession {
                    Text(sessionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.lavender)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                statPill("+\(entry.streak)", "Streak", WidgetPalette.lavender)
                statPill("\(entry.blocked)", "Apps", WidgetPalette.coral)
            }
        }
        .padding()
        .widgetURL(URL(string: "timepay://unlock")!)
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text(entry.balanceLabel).font(.headline.weight(.bold))
                Text("Min").font(.caption2)
            }
        }
    }

    private var rectangularView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TimePay").font(.caption2)
                Text("\(entry.balanceLabel) Min").font(.headline)
                if entry.hasSession { Text(sessionLabel).font(.caption2) }
            }
            Spacer()
        }
    }

    private func statPill(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var sessionLabel: String {
        let t = formatTime(entry.sessionRemaining)
        if entry.sessionKind == "unlock" { return "Freigabe · \(t)" }
        if entry.sessionKind == "earn" { return "\(entry.sessionTitle) · \(t)" }
        return ""
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - Schnellaktionen

struct TimePayQuickActionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimePayQuickActions", provider: BalanceProvider()) { entry in
            QuickActionsWidgetView(entry: entry)
                .timePayWidgetBackground()
                .widgetVibrantBorder(WidgetPalette.lavender)
        }
        .configurationDisplayName("Schnellaktionen")
        .description("Session starten, Zeit abbuchen oder Freigabe beenden.")
        .supportedFamilies([.systemMedium])
    }
}

struct QuickActionsWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TimePay")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(entry.balanceLabel) Min")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WidgetPalette.teal)
            }

            HStack(spacing: 10) {
                Link(destination: URL(string: "timepay://earn")!) {
                    actionTile("Session", icon: "play.fill", colors: [WidgetPalette.lavender, WidgetPalette.coral.opacity(0.8)])
                }
                Link(destination: URL(string: "timepay://unlock")!) {
                    actionTile("Abbuchen", icon: "lock.open.fill", colors: [WidgetPalette.teal, Color(red: 0.4, green: 0.95, blue: 0.85)])
                }
                if entry.sessionKind == "unlock" {
                    Link(destination: URL(string: "timepay://end")!) {
                        actionTile("Stop", icon: "stop.fill", colors: [WidgetPalette.coral, .orange])
                    }
                } else {
                    Link(destination: URL(string: "timepay://unlock")!) {
                        actionTile("Gate", icon: "lock.shield", colors: [Color.orange.opacity(0.8), WidgetPalette.coral])
                    }
                }
            }
        }
        .padding()
    }

    private func actionTile(_ title: String, icon: String, colors: [Color]) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
            Text(title)
                .font(.caption2.weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .foregroundStyle(.white)
    }
}

// MARK: - Session-Countdown

struct TimePaySessionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimePaySession", provider: BalanceProvider()) { entry in
            SessionWidgetView(entry: entry)
                .timePayWidgetBackground()
                .widgetVibrantBorder(entry.sessionKind == "unlock" ? WidgetPalette.teal : WidgetPalette.lavender)
        }
        .configurationDisplayName("Session")
        .description("Restzeit der Freigabe oder Focus-Session.")
        .supportedFamilies([.systemSmall])
    }
}

struct SessionWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        if entry.hasSession, let end = entry.sessionEndDate, end > Date() {
            VStack(alignment: .leading, spacing: 8) {
                Label(entry.sessionKind == "unlock" ? "Freigabe" : entry.sessionTitle, systemImage: entry.sessionKind == "unlock" ? "lock.open.fill" : "hourglass")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(entry.sessionKind == "unlock" ? WidgetPalette.teal : WidgetPalette.lavender)
                Text(timerInterval: Date()...end, countsDown: true)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("live")
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.mint)
            }
            .padding()
            .widgetURL(URL(string: entry.sessionKind == "unlock" ? "timepay://end" : "timepay://earn")!)
        } else if entry.hasSession && entry.sessionRemaining > 0 {
            VStack(alignment: .leading, spacing: 8) {
                Label(entry.sessionKind == "unlock" ? "Freigabe" : entry.sessionTitle, systemImage: entry.sessionKind == "unlock" ? "lock.open.fill" : "hourglass")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(entry.sessionKind == "unlock" ? WidgetPalette.teal : WidgetPalette.lavender)
                Text(formatTime(entry.sessionRemaining))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("verbleibend")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding()
            .widgetURL(URL(string: entry.sessionKind == "unlock" ? "timepay://end" : "timepay://earn")!)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Keine Session")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
                Text("\(entry.balanceLabel) Min")
                    .font(.title.weight(.bold))
                    .foregroundStyle(WidgetPalette.teal)
                Text("Tippe für Session")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding()
            .widgetURL(URL(string: "timepay://earn")!)
        }
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - Live Activity

#if canImport(ActivityKit)
struct TimePayLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimePaySessionAttributes.self) { context in
            let isUnlock = context.state.sessionKind == "unlock"
            let accent = isUnlock ? WidgetPalette.teal : WidgetPalette.lavender
            let title = isUnlock ? "Freigabe aktiv" : context.state.sessionTitle

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("TimePay", systemImage: isUnlock ? "lock.open.fill" : "hourglass.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                        Text(title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                        .contentTransition(.numericText())
                        .shadow(color: accent.opacity(0.35), radius: 6)
                }

                ProgressView(timerInterval: context.attributes.startedAt...context.state.endDate, countsDown: true)
                    .tint(accent)

                Text("Live — Sekunde für Sekunde")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))

                if isUnlock {
                    Button(intent: EndUnlockSessionIntent()) {
                        Label("Beenden & erstatten", systemImage: "stop.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WidgetPalette.coral)
                }
            }
            .padding(18)
            .activityBackgroundTint(WidgetPalette.navy)
        } dynamicIsland: { context in
            let isUnlock = context.state.sessionKind == "unlock"
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: isUnlock ? "lock.open.fill" : "hourglass").foregroundStyle(WidgetPalette.teal)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .monospacedDigit().font(.title3.weight(.bold)).foregroundStyle(WidgetPalette.teal)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(isUnlock ? "Freigabe" : context.state.sessionTitle).font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if isUnlock {
                        Button(intent: EndUnlockSessionIntent()) { Label("Beenden", systemImage: "stop.fill") }
                    }
                }
            } compactLeading: {
                Image(systemName: isUnlock ? "lock.open" : "hourglass").foregroundStyle(WidgetPalette.teal)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endDate, countsDown: true).monospacedDigit().font(.caption2)
            } minimal: {
                Image(systemName: "hourglass")
            }
        }
    }
}
#endif

// MARK: - Provider

struct BalanceEntry: TimelineEntry {
    let date: Date
    let minutes: Int
    let balanceHalfMinutes: Int
    let streak: Int
    let blocked: Int
    let sessionKind: String
    let sessionRemaining: Int
    let sessionTitle: String
    let sessionEndDate: Date?

    var balanceLabel: String { TimePayFormat.halfMinutesNumber(balanceHalfMinutes) }
    var hasSession: Bool { sessionKind != "none" }
}

struct BalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        makeEntry(from: .init(minutes: 20, balanceHalfMinutes: 40, streak: 3, blocked: 2, sessionKind: "unlock", sessionRemaining: 320, sessionTitle: "Freigabe", sessionEndDate: Date().addingTimeInterval(320)))
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        completion(makeEntry(from: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let snap = WidgetSnapshot.load()
        let entry = makeEntry(from: snap)
        let next = snap.hasSession ? Date().addingTimeInterval(15) : Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry(from snap: WidgetSnapshot) -> BalanceEntry {
        BalanceEntry(
            date: Date(),
            minutes: snap.minutes,
            balanceHalfMinutes: snap.balanceHalfMinutes,
            streak: snap.streak,
            blocked: snap.blocked,
            sessionKind: snap.sessionKind,
            sessionRemaining: snap.sessionRemaining,
            sessionTitle: snap.sessionTitle,
            sessionEndDate: snap.sessionEndDate
        )
    }
}
