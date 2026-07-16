import SwiftUI

struct SmartInputBar: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showReceiptScan: Bool
    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var showCamera = false

    private var isIncome: Bool { store.inputMode == .income }
    private var modeColor: Color { isIncome ? LiveCashTheme.income : LiveCashTheme.expense }

    private var showLivePanel: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.pendingConfirmation != nil
            || store.pendingSpendLimit != nil
            || !trimmed.isEmpty
    }

    var body: some View {
        VStack(spacing: 10) {
            if showLivePanel {
                liveIntelligencePanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .gesture(
                        DragGesture(minimumDistance: 24)
                            .onEnded { value in
                                if value.translation.height > 48 {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        focused = false
                                        store.clearLiveIntelligence()
                                    }
                                    HapticService.light(store: store)
                                }
                            }
                    )
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
                    HapticService.medium(store: store)
                    store.updateLiveIntelligence(for: text)
                }

                Button {
                    focused = false
                    store.showInputSourceSheet = true
                    HapticService.light(store: store)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(LiveCashTheme.accent)
                        .shadow(color: LiveCashTheme.accent.opacity(0.25), radius: 6, y: 2)
                }
                .buttonStyle(.plain)

                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Ausgabe, Einnahme oder Frage eingeben…")
                            .font(LiveCashTheme.bodyFont)
                            .foregroundStyle(.secondary.opacity(0.85))
                            .padding(.horizontal, 16)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $text)
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
                        .padding(.vertical, 13)
                }
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(focused ? 0.18 : 0.08),
                                            Color.white.opacity(0.02)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(
                                    focused ? modeColor.opacity(0.5) : LiveCashTheme.glassBorder,
                                    lineWidth: focused ? 1.2 : 0.8
                                )
                        )
                        .shadow(color: focused ? modeColor.opacity(0.18) : .black.opacity(0.06), radius: focused ? 10 : 4, y: 3)
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: focused)
                .animation(.easeInOut(duration: 0.2), value: isIncome)

                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(text.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.5) : modeColor)
                        .scaleEffect(text.trimmingCharacters(in: .whitespaces).isEmpty ? 1 : 1.05)
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Color.clear)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") { focused = false }
            }
        }
        .onAppear {
            store.clearLiveIntelligence()
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
                if store.inputInterpretation.hint != nil {
                    InterpretationChip(interpretation: store.inputInterpretation)
                }
                if !store.liveSuggestions.isEmpty {
                    LiveSuggestionsView(
                        suggestions: store.liveSuggestions,
                        mode: store.currentAssistantMode
                    ) { suggestion in
                        HapticService.light(store: store)
                        withAnimation(.easeOut(duration: 0.15)) {
                            switch suggestion.action {
                            case .submitText(let s):
                                text = s
                                store.updateLiveIntelligence(for: s)
                                submit()
                            case .saveDraft(var draft):
                                SmartInputParser.shared.applyPreferredType(store.inputMode, to: &draft, text: text)
                                let engine = LiveIntelligenceEngine.shared
                                let confidence = engine.effectiveConfidence(
                                    engine.classifyInputConfidence(text, draft: draft, preferredType: store.inputMode, store: store),
                                    store: store
                                )
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
        HapticService.light(store: store)
    }
}
