import SwiftUI

/// Full-page Smart Assistant hub under Mehr — tiles + input + question bank.
struct SmartAssistantHubView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var draft = ""
    @State private var showReceiptScan = false
    @State private var liveMatches: [AssistantQuestion] = []
    @State private var matchTask: Task<Void, Never>?
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    Text("Frag alles zu Budget, Sparen und Ausgaben — lokal, ohne Cloud.")
                        .font(LiveCashTheme.bodyFont)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(AssistantQuestionBank.quickTiles.enumerated()), id: \.offset) { _, tile in
                            Button {
                                HapticService.light(store: store)
                                store.showInsight(for: tile.action)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Image(systemName: tile.icon)
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(LiveCashTheme.accent)
                                    Text(tile.title)
                                        .font(LiveCashTheme.captionFont.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
                                .padding(14)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PremiumPressStyle())
                        }
                    }

                    if draft.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2, !liveMatches.isEmpty {
                        questionSection(title: "Passende Fragen", questions: liveMatches)
                    } else {
                        ForEach(AssistantQuestionBank.categories, id: \.self) { category in
                            questionSection(
                                title: category,
                                questions: AssistantQuestionBank.questions(in: category)
                            )
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(LiveCashTheme.screenBackground)

            inputDock
        }
        .navigationTitle("Smart Assistant")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: draft) { _, newValue in
            scheduleMatchUpdate(for: newValue)
        }
        .onDisappear {
            matchTask?.cancel()
        }
        .sheet(isPresented: $showReceiptScan) {
            ReceiptScanView()
        }
        .sheet(isPresented: Binding(
            get: { store.activeInsight != nil },
            set: { if !$0 { store.activeInsight = nil } }
        )) {
            if let insight = store.activeInsight {
                InsightResultView(insight: insight)
            }
        }
        .sheet(isPresented: $store.showFinanceReport) {
            FinanceReportView()
        }
        .sheet(isPresented: $store.showAnalyzeMe) {
            AnalyzeMeView()
        }
    }

    @ViewBuilder
    private func questionSection(title: String, questions: [AssistantQuestion]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(LiveCashTheme.headlineFont)
            ForEach(questions) { q in
                Button {
                    HapticService.selection(store: store)
                    applyQuestion(q)
                } label: {
                    HStack {
                        Text(q.prompt)
                            .font(LiveCashTheme.bodyFont)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(SoftPressStyle())
            }
        }
    }

    private var inputDock: some View {
        VStack(spacing: 8) {
            if !liveMatches.isEmpty && draft.count >= 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(liveMatches.prefix(8)) { q in
                            Button {
                                HapticService.selection(store: store)
                                applyQuestion(q)
                            } label: {
                                Text(q.prompt)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.regularMaterial, in: Capsule())
                            }
                            .buttonStyle(PremiumPressStyle(scale: 0.94))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                Button {
                    showReceiptScan = true
                    HapticService.light(store: store)
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                        .foregroundStyle(LiveCashTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(PremiumPressStyle())

                TextField("z. B. Spare ich genug?", text: $draft, axis: .vertical)
                    .font(LiveCashTheme.bodyFont)
                    .lineLimit(1...3)
                    .focused($inputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    submit()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(canSubmit ? LiveCashTheme.accent : Color.secondary.opacity(0.4))
                }
                .disabled(!canSubmit)
                .buttonStyle(PremiumPressStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .padding(.bottom, 6)
            .background(.ultraThinMaterial)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: liveMatches.count)
    }

    private var canSubmit: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func scheduleMatchUpdate(for text: String) {
        matchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            liveMatches = []
            return
        }
        matchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            guard !Task.isCancelled else { return }
            liveMatches = AssistantQuestionBank.matches(for: trimmed, limit: 10)
        }
    }

    private func applyQuestion(_ q: AssistantQuestion) {
        if let action = q.action {
            store.showInsight(for: action)
            draft = ""
            liveMatches = []
            inputFocused = false
        } else if let query = q.query {
            draft = query
            submit()
        } else {
            draft = q.prompt
        }
    }

    private func submit() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        HapticService.medium(store: store)
        store.processInput(text)
        draft = ""
        liveMatches = []
        inputFocused = false
    }
}
