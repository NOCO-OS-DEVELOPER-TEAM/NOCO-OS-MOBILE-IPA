import SwiftUI

enum LiveCashTheme {
    static let accent = Color(red: 0.12, green: 0.72, blue: 0.52)
    static let accentSoft = Color(red: 0.12, green: 0.72, blue: 0.52).opacity(0.18)
    static let income = Color(red: 0.15, green: 0.78, blue: 0.42)
    static let incomeSoft = Color(red: 0.15, green: 0.78, blue: 0.42).opacity(0.16)
    static let expense = Color(red: 0.94, green: 0.32, blue: 0.36)
    static let expenseSoft = Color(red: 0.94, green: 0.32, blue: 0.36).opacity(0.14)

    static let glassBorder = Color.white.opacity(0.28)
    static let glassHighlight = Color.white.opacity(0.12)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let screenBackground = Color(uiColor: .systemGroupedBackground)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .systemGroupedBackground),
                accent.opacity(0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static let titleFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .rounded)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .rounded)

    static func money(_ value: Double, income: Bool = false) -> String {
        String(format: income ? "+%.2f€" : "%.2f€", abs(value))
    }
}

struct LiveCashCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        LiveCashGlassCard {
            content
        }
    }
}

struct LiveCashGlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.22),
                                        LiveCashTheme.glassHighlight,
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.55),
                                        Color.white.opacity(0.12),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 16, y: 6)
            .shadow(color: LiveCashTheme.accent.opacity(0.06), radius: 20, y: 8)
    }
}

struct MoneyCardGlassView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        LiveCashGlassCard {
            content
        }
        .padding(.vertical, 4)
    }
}

struct SectionHeader: View {
    let title: String
    var action: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(LiveCashTheme.headlineFont)
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(LiveCashTheme.accent)
            }
        }
    }
}
