import SwiftUI

struct SmartShortcutsView: View {
    @EnvironmentObject private var store: FinanceStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Schnellzugriff")
                    .font(LiveCashTheme.headlineFont)
                Spacer()
                Text("Nur nutzen")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.shortcuts) { shortcut in
                    shortcutButton(shortcut)
                }
            }
        }
    }

    private func shortcutButton(_ shortcut: QuickShortcut) -> some View {
        let color = shortcut.type == .income ? LiveCashTheme.income : LiveCashTheme.expense
        let soft = shortcut.type == .income ? LiveCashTheme.incomeSoft : LiveCashTheme.expenseSoft

        return Button {
            HapticService.light(store: store)
            store.applyShortcut(shortcut)
        } label: {
            VStack(spacing: 6) {
                actionIcon(for: shortcut)
                Text(shortcut.merchant)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                if shortcut.actionType == .book {
                    Text(String(format: "%.0f€", shortcut.amount))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(soft)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(color.opacity(0.25), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func actionIcon(for shortcut: QuickShortcut) -> some View {
        switch shortcut.actionType {
        case .assistant:
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(LiveCashTheme.accent)
        case .overview:
            Image(systemName: "chart.bar.fill")
                .font(.title3)
                .foregroundStyle(LiveCashTheme.accent)
        case .map:
            Image(systemName: "map.fill")
                .font(.title3)
                .foregroundStyle(LiveCashTheme.accent)
        case .goals:
            Image(systemName: "target")
                .font(.title3)
                .foregroundStyle(LiveCashTheme.accent)
        case .book:
            EmptyView()
        }
    }
}
