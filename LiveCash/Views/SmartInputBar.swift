import SwiftUI

struct SmartInputBar: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showReceiptScan: Bool
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 10) {
            if let intent = store.pendingIntent {
                AssistantSuggestionsView(intent: intent)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let insight = store.activeInsight {
                InsightResultView(insight: insight) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.activeInsight = nil
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let feedback = store.lastFeedback {
                Text(feedback)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(LiveCashTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 10) {
                Button {
                    showReceiptScan = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.body.weight(.medium))
                        .frame(width: 44, height: 44)
                        .background(LiveCashTheme.cardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                TextField("z. B. „Netflix 13,99“ oder „wie viel heute?“", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($focused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(LiveCashTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .submitLabel(.done)
                    .onSubmit(submit)

                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(text.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : LiveCashTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func submit() {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            store.processInput(input)
        }
        text = ""
        focused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
