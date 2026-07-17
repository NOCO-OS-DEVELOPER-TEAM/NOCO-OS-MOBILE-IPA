import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal
    @State private var animatedProgress: CGFloat = 0

    private var liveGoal: SavingsGoal {
        store.goals.first(where: { $0.id == goal.id }) ?? goal
    }

    private var pace: GoalPaceStatus {
        liveGoal.paceStatus(referenceMonthlySavings: store.monthlySavingsRate)
    }

    private var estimatedWeeksAt10: Int {
        guard liveGoal.remaining > 0 else { return 0 }
        return max(Int(ceil(liveGoal.remaining / 10)), 1)
    }

    private var weeklyAverage: Double {
        let weeks = max(Calendar.current.dateComponents([.weekOfYear], from: liveGoal.createdAt, to: Date()).weekOfYear ?? 1, 1)
        return liveGoal.currentAmount / Double(weeks)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    LiveCashCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(liveGoal.name)
                                    .font(LiveCashTheme.titleFont)
                                Spacer()
                                Text("\(liveGoal.progressPercent)%")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundStyle(liveGoal.isCompleted ? LiveCashTheme.income : LiveCashTheme.accent)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(LiveCashTheme.incomeSoft)
                                    Capsule()
                                        .fill(liveGoal.isCompleted ? LiveCashTheme.income : LiveCashTheme.accent)
                                        .frame(width: geo.size.width * animatedProgress)
                                }
                            }
                            .frame(height: 12)

                            HStack {
                                statBlock(title: "Gespart", value: String(format: "%.0f€", liveGoal.currentAmount), color: LiveCashTheme.income)
                                Spacer()
                                statBlock(title: "Ziel", value: String(format: "%.0f€", liveGoal.targetAmount), color: .primary)
                                Spacer()
                                statBlock(title: "Übrig", value: String(format: "%.0f€", liveGoal.remaining), color: .secondary)
                            }

                            HStack {
                                Label(String(format: "Ø %.0f€/Woche", weeklyAverage), systemImage: "calendar")
                                Spacer()
                                if let days = liveGoal.daysRemaining, liveGoal.goalTimeTrackingEnabled {
                                    Text("\(days) Tage")
                                }
                            }
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                        }
                    }

                    LiveCashCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vermögen")
                                .font(LiveCashTheme.headlineFont)
                            LabeledContent("Verfügbares Geld", value: String(format: "%.0f€", store.availableBalance))
                            LabeledContent("In diesem Sparziel", value: String(format: "%.0f€", liveGoal.currentAmount))
                            LabeledContent("Gesamtvermögen", value: String(format: "%.0f€", store.totalWealth))
                            Text("Einzahlungen reduzieren dein verfügbares Geld — das Gesamtvermögen bleibt gleich.")
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LiveCashCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Smart Tracking")
                                .font(LiveCashTheme.headlineFont)

                            if let days = liveGoal.daysRemaining, liveGoal.goalTimeTrackingEnabled {
                                LabeledContent("Verbleibende Zeit", value: "\(days) Tag\(days == 1 ? "" : "e")")
                            }
                            if let targetDate = liveGoal.targetDate {
                                LabeledContent("Zieldatum", value: targetDate.formatted(date: .long, time: .omitted))
                            }
                            if let required = liveGoal.requiredDailyPace, liveGoal.goalTimeTrackingEnabled {
                                LabeledContent("Nötiges Tages-Tempo", value: String(format: "%.2f€", required))
                            }
                            if let actual = liveGoal.actualDailyPace {
                                LabeledContent("Aktuelles Tages-Tempo", value: String(format: "%.2f€", actual))
                            }
                            if pace != .noDeadline {
                                LabeledContent("Tempo", value: pace.rawValue)
                            }
                            if !liveGoal.isCompleted {
                                LabeledContent("Bei 10€/Woche", value: "~\(estimatedWeeksAt10) Wochen")
                            }
                            if liveGoal.isCompleted {
                                Label("Ziel erreicht", systemImage: "checkmark.seal.fill")
                                    .font(LiveCashTheme.bodyFont)
                                    .foregroundStyle(LiveCashTheme.income)
                            } else if pace == .slow {
                                Label("Du liegst hinter dem Plan — kleiner Beitrag hilft.", systemImage: "exclamationmark.triangle.fill")
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            store.pendingGoalTransferIsWithdraw = false
                            store.showGoalContributionSheet = true
                        }
                    } label: {
                        Label("Geld hinzufügen", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LiveCashTheme.income)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(liveGoal.isCompleted || store.availableBalance <= 0)

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            store.pendingGoalTransferIsWithdraw = true
                            store.showGoalContributionSheet = true
                        }
                    } label: {
                        Label("Geld entnehmen", systemImage: "minus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LiveCashTheme.accent.opacity(0.15))
                            .foregroundStyle(LiveCashTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(liveGoal.currentAmount <= 0)
                }
                .padding(20)
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Sparziel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .onAppear {
                animatedProgress = 0
                withAnimation(.spring(response: 0.85, dampingFraction: 0.78)) {
                    animatedProgress = liveGoal.progress
                }
            }
            .onChange(of: liveGoal.progress) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            }
        }
    }

    private func statBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LiveCashTheme.captionFont)
                .foregroundStyle(.secondary)
            Text(value)
                .font(LiveCashTheme.headlineFont)
                .foregroundStyle(color)
        }
    }
}
