import SwiftUI

struct SmartInputBar: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showReceiptScan: Bool
    @State private var text = ""
    @FocusState private var focused: Bool

    private var showLivePanel: Bool {
        focused || !text.isEmpty || store.pendingConfirmation != nil
    }

    var body: some View {
        VStack(spacing: 10) {
            if showLivePanel {
                liveIntelligencePanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let intent = store.pendingIntent, store.pendingConfirmation == nil {
                AssistantSuggestionsView(intent: intent)
            }

            if let insight = store.activeInsight {
                InsightResultView(insight: insight) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.activeInsight = nil
                    }
                }
            }

            if let feedback = store.lastFeedback, !focused {
                Text(feedback)
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(LiveCashTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 10) {
                Button {
                    focused = false
                    showReceiptScan = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.body.weight(.medium))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                TextField("Eingeben oder fragen…", text: $text)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit(submit)
                    .onChange(of: text) { _, newValue in
                        store.updateLiveIntelligence(for: newValue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(focused ? LiveCashTheme.accent.opacity(0.4) : LiveCashTheme.glassBorder, lineWidth: 0.8)
                    )

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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") { focused = false }
            }
        }
        .onAppear {
            store.updateLiveIntelligence(for: "")
        }
    }

    @ViewBuilder
    private var liveIntelligencePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let confirmation = store.pendingConfirmation {
                ConfirmationBanner(
                    confirmation: confirmation,
                    onExpense: {
                        store.confirmAsExpense()
                        text = ""
                        focused = false
                        store.clearLiveIntelligence()
                    },
                    onIncome: {
                        store.confirmAsIncome()
                        text = ""
                        focused = false
                        store.clearLiveIntelligence()
                    },
                    onCancel: {
                        store.cancelConfirmation()
                        store.clearLiveIntelligence()
                    }
                )
            } else {
                InterpretationChip(interpretation: store.inputInterpretation)
                LiveSuggestionsView(suggestions: store.liveSuggestions) { suggestion in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.15)) {
                        switch suggestion.action {
                        case .submitText(let s):
                            text = s
                            store.updateLiveIntelligence(for: s)
                            submit()
                        case .saveDraft(let draft):
                            if LiveIntelligenceEngine.shared.isUncertainInput(text, draft: draft) {
                                store.pendingConfirmation = PendingConfirmation(
                                    draft: draft,
                                    rawInput: text,
                                    message: "Ist das eine Ausgabe oder Einnahme?"
                                )
                            } else {
                                store.saveDraft(draft, rawInput: text)
                                text = ""
                                focused = false
                                store.clearLiveIntelligence()
                            }
                        default:
                            store.applyLiveSuggestion(suggestion)
                            text = ""
                            focused = false
                            store.clearLiveIntelligence()
                        }
                    }
                }
            }
        }
    }

    private func submit() {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            store.processInput(input)
        }
        if store.pendingConfirmation == nil {
            text = ""
            focused = false
            store.clearLiveIntelligence()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
