import SwiftUI

enum LiveCashTheme {
    static let accent = Color(red: 0.12, green: 0.72, blue: 0.52)
    static let accentSoft = Color(red: 0.12, green: 0.72, blue: 0.52).opacity(0.18)
    static let income = Color(red: 0.15, green: 0.78, blue: 0.42)
    static let incomeSoft = Color(red: 0.15, green: 0.78, blue: 0.42).opacity(0.16)
    static let expense = Color(red: 0.94, green: 0.32, blue: 0.36)
    static let expenseSoft = Color(red: 0.94, green: 0.32, blue: 0.36).opacity(0.14)

    static let glassBorder = Color.white.opacity(0.22)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let screenBackground = Color(uiColor: .systemGroupedBackground)

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
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(LiveCashTheme.glassBorder, lineWidth: 0.6)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
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
