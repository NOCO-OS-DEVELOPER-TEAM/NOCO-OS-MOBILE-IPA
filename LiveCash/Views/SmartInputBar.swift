import SwiftUI
import UIKit

struct SmartInputBar: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showReceiptScan: Bool
    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var showCamera = false

    private var isIncome: Bool { store.inputMode == .income }
    private var modeColor: Color { isIncome ? LiveCashTheme.income : LiveCashTheme.expense }

    private var showLivePanel: Bool {
        focused || !text.isEmpty || store.pendingConfirmation != nil || store.pendingSpendLimit != nil
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
                    .foregroundStyle(modeColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 10) {
                InputTypeToggle(isIncome: isIncome) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        store.toggleInputMode()
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.updateLiveIntelligence(for: text)
                }

                Button {
                    focused = false
                    store.showInputSourceSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(LiveCashTheme.accent)
                }
                .buttonStyle(.plain)

                TextField(isIncome ? "Einnahme eingeben…" : "Ausgabe eingeben…", text: $text)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit(submit)
                    .onChange(of: text) { _, newValue in
                        store.updateLiveIntelligence(for: newValue)
                    }
                    .onChange(of: store.focusInputOnAppear) { _, shouldFocus in
                        if shouldFocus {
                            focused = true
                            store.focusInputOnAppear = false
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(focused ? modeColor.opacity(0.45) : LiveCashTheme.glassBorder, lineWidth: 0.8)
                    )

                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(text.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : modeColor)
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
            if store.focusInputOnAppear {
                focused = true
                store.focusInputOnAppear = false
            }
        }
        .sheet(isPresented: $store.showInputSourceSheet) {
            InputSourceSheet(showReceiptScan: $showReceiptScan) {
                showCamera = true
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(source: .camera) { image in
                store.pendingScanImage = image
                showReceiptScan = true
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var liveIntelligencePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let limit = store.pendingSpendLimit {
                SpendLimitBanner(
                    warning: limit,
                    onConfirm: {
                        store.confirmSpendLimit()
                        text = ""
                        focused = false
                        store.clearLiveIntelligence()
                    },
                    onCancel: { store.cancelSpendLimit() }
                )
            } else if let confirmation = store.pendingConfirmation {
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
                    onOption: { option in
                        store.confirmWithOption(option)
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
                LiveSuggestionsView(
                    suggestions: store.liveSuggestions,
                    mode: store.currentAssistantMode
                ) { suggestion in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.15)) {
                        switch suggestion.action {
                        case .submitText(let s):
                            text = s
                            store.updateLiveIntelligence(for: s)
                            submit()
                        case .saveDraft(var draft):
                            SmartInputParser.shared.applyPreferredType(store.inputMode, to: &draft, text: text)
                            let engine = LiveIntelligenceEngine.shared
                            let confidence = engine.classifyInputConfidence(text, draft: draft, preferredType: store.inputMode)
                            switch confidence {
                            case .safe:
                                store.saveDraft(draft, rawInput: text)
                                text = ""
                                focused = false
                                store.clearLiveIntelligence()
                            case .uncertain:
                                store.pendingConfirmation = PendingConfirmation(
                                    draft: draft,
                                    rawInput: text,
                                    message: engine.uncertainMessage(for: draft, text: text),
                                    confidence: .uncertain
                                )
                            case .highRisk:
                                store.pendingConfirmation = PendingConfirmation(
                                    draft: draft,
                                    rawInput: text,
                                    message: "Mehrdeutig — was meinst du?",
                                    confidence: .highRisk,
                                    options: engine.highRiskOptions(for: draft, text: text)
                                )
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
        if store.pendingConfirmation == nil && store.pendingSpendLimit == nil {
            text = ""
            focused = false
            store.clearLiveIntelligence()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
