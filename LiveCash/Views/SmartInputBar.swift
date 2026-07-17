import SwiftUI

struct SmartInputBar: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showReceiptScan: Bool
    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var showCamera = false
    @State private var isExpanded = false

    private var isIncome: Bool { store.inputMode == .income }
    private var modeColor: Color { isIncome ? LiveCashTheme.income : LiveCashTheme.expense }

    private var hasBlockingPanel: Bool {
        store.pendingConfirmation != nil || store.pendingSpendLimit != nil
    }

    private var showTypingSuggestions: Bool {
        isExpanded && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasBlockingPanel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if isExpanded {
                    expandedPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    if value.translation.height > 56 {
                                        collapse()
                                    }
                                }
                        )
                }

                compactBar
            }
        }
        .animation(LiveCashMotion.panelSpring, value: isExpanded)
        .onChange(of: isExpanded) { _, expanded in
            store.isAssistantExpanded = expanded
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Schließen") { collapse() }
                Spacer()
                Button("Fertig") { collapse() }
            }
        }
        .onAppear {
            store.clearLiveIntelligence()
            if store.focusInputOnAppear {
                expand()
                store.focusInputOnAppear = false
            }
        }
        .onChange(of: store.focusInputOnAppear) { _, shouldFocus in
            if shouldFocus {
                expand()
                store.focusInputOnAppear = false
            }
        }
        .onChange(of: focused) { _, isFocused in
            if isFocused {
                withAnimation(LiveCashMotion.panelSpring) {
                    isExpanded = true
                }
                HapticService.soft(store: store)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .liveCashCollapseAssistant)) { _ in
            collapse()
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

    // MARK: - Compact bar (always visible)

    private var compactBar: some View {
        HStack(spacing: 10) {
            InputTypeToggle(isIncome: isIncome) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    store.toggleInputMode()
                }
                HapticService.medium(store: store)
                if isExpanded {
                    store.updateLiveIntelligence(for: text)
                }
            }

            Button {
                focused = false
                store.showInputSourceSheet = true
                HapticService.light(store: store)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(LiveCashTheme.accent)
            }
            .buttonStyle(.plain)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(isExpanded ? "Ausgabe, Einnahme oder Frage…" : "Eingeben…")
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(Color.primary.opacity(0.45))
                        .padding(.horizontal, 14)
                        .allowsHitTesting(false)
                }
                TextField("", text: $text)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit(submit)
                    .onChange(of: text) { _, newValue in
                        store.updateLiveIntelligence(for: newValue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(focused ? modeColor.opacity(0.55) : Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onTapGesture { expand() }

            if isExpanded && !text.trimmingCharacters(in: .whitespaces).isEmpty {
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(modeColor)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Expanded panel

    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)

            if hasBlockingPanel {
                liveIntelligencePanel
            } else if showTypingSuggestions {
                typingSuggestionsPanel
            } else if let insight = store.activeInsight {
                InsightResultView(insight: insight) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.activeInsight = nil
                    }
                }
            } else if let intent = store.pendingIntent {
                AssistantSuggestionsView(intent: intent)
            } else {
                quickTilesGrid
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 24, y: -8)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
    }

    private var quickTilesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(AssistantQuestionBank.quickTiles, id: \.title) { tile in
                Button {
                    HapticService.light(store: store)
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.showInsight(for: tile.action)
                        text = ""
                        store.clearLiveIntelligence()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tile.icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(LiveCashTheme.accent)
                            .frame(width: 28)
                        Text(tile.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var typingSuggestionsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.inputInterpretation.hint != nil {
                InterpretationChip(interpretation: store.inputInterpretation)
            }
            if !store.liveSuggestions.isEmpty {
                LiveSuggestionsView(
                    suggestions: store.liveSuggestions,
                    mode: store.currentAssistantMode
                ) { suggestion in
                    handleSuggestion(suggestion)
                }
            }
        }
    }

    @ViewBuilder
    private var liveIntelligencePanel: some View {
        if let limit = store.pendingSpendLimit {
            SpendLimitBanner(
                warning: limit,
                onConfirm: {
                    store.confirmSpendLimit()
                    text = ""
                    collapse()
                },
                onCancel: { store.cancelSpendLimit() }
            )
        } else if let confirmation = store.pendingConfirmation {
            ConfirmationBanner(
                confirmation: confirmation,
                onExpense: {
                    store.confirmAsExpense()
                    text = ""
                    collapse()
                },
                onIncome: {
                    store.confirmAsIncome()
                    text = ""
                    collapse()
                },
                onOption: { option in
                    store.confirmWithOption(option)
                    text = ""
                    collapse()
                },
                onCancel: {
                    store.cancelConfirmation()
                    store.clearLiveIntelligence()
                }
            )
        }
    }

    // MARK: - Actions

    private func expand() {
        withAnimation(LiveCashMotion.panelSpring) {
            isExpanded = true
        }
        focused = true
        HapticService.medium(store: store)
    }

    private func collapse() {
        focused = false
        store.isAssistantExpanded = false
        withAnimation(LiveCashMotion.panelSpring) {
            isExpanded = false
            store.activeInsight = nil
            store.pendingIntent = nil
            store.clearLiveIntelligence()
        }
        HapticService.soft(store: store)
    }

    private func handleSuggestion(_ suggestion: LiveSuggestion) {
        HapticService.medium(store: store)
        withAnimation(LiveCashMotion.snappy) {
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
                    collapse()
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
                // Keep expanded to show insight result
                store.clearLiveIntelligence()
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
            // Stay expanded if an insight/intent appeared; else collapse
            if store.activeInsight == nil && store.pendingIntent == nil {
                collapse()
            } else {
                store.clearLiveIntelligence()
                focused = false
            }
        }
        HapticService.success(store: store)
    }
}
