import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var editingGoal: SavingsGoal?
    @State private var detailGoal: SavingsGoal?
    @State private var goalToDelete: SavingsGoal?

    private var totalSaved: Double {
        store.goals.reduce(0) { $0 + $1.currentAmount }
    }

    private var totalTarget: Double {
        store.goals.reduce(0) { $0 + $1.targetAmount }
    }

    var body: some View {
        List {
            if !store.goals.isEmpty {
                summaryHeader
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            if store.goals.isEmpty {
                ContentUnavailableView(
                    "Keine Sparziele",
                    systemImage: "target",
                    description: Text("Lege ein Ziel an — z. B. Urlaub oder neues iPhone.")
                )
                .listRowBackground(Color.clear)
            } else {
                if !store.activeGoals.isEmpty {
                    Section {
                        ForEach(store.activeGoals) { goal in
                            goalRow(goal)
                        }
                    } header: {
                        Text("Aktive Ziele")
                    }
                }

                if !store.completedGoals.isEmpty {
                    Section {
                        ForEach(store.completedGoals) { goal in
                            goalRow(goal, completed: true)
                        }
                    } header: {
                        Text("Abgeschlossen")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(LiveCashTheme.screenBackground)
        .navigationTitle("Sparziele")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            GoalFormView()
        }
        .sheet(item: $editingGoal) { goal in
            GoalFormView(editingGoal: goal)
        }
        .sheet(item: $detailGoal) { goal in
            GoalDetailView(goal: goal)
        }
        .alert("Sparziel löschen?", isPresented: Binding(
            get: { goalToDelete != nil },
            set: { if !$0 { goalToDelete = nil } }
        )) {
            Button("Löschen", role: .destructive) {
                if let goal = goalToDelete {
                    store.deleteGoal(goal)
                    goalToDelete = nil
                }
            }
            Button("Abbrechen", role: .cancel) { goalToDelete = nil }
        } message: {
            if let goal = goalToDelete {
                Text("\"\(goal.name)\" wird unwiderruflich gelöscht.")
            }
        }
    }

    @ViewBuilder
    private func goalRow(_ goal: SavingsGoal, completed: Bool = false) -> some View {
        Button {
            editingGoal = goal
        } label: {
            GoalCard(
                goal: goal,
                monthlySavingsRate: store.monthlySavingsRate,
                showProgress: store.appSettings.savings.showProgress,
                completed: completed
            )
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                detailGoal = goal
                HapticService.light(store: store)
            } label: {
                Label("Details", systemImage: "info.circle")
            }
            .tint(LiveCashTheme.accent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                goalToDelete = goal
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    private var summaryHeader: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gespart")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f€ / %.0f€", totalSaved, totalTarget))
                            .font(LiveCashTheme.headlineFont)
                    }
                    Spacer()
                    if store.blockedInGoals > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "%.0f€", store.blockedInGoals))
                                .font(LiveCashTheme.captionFont.weight(.semibold))
                                .foregroundStyle(LiveCashTheme.accent)
                            Text("In Sparzielen")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if store.loginReward.loginStreakDays > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("\(store.loginReward.loginStreakDays) Tage", systemImage: "flame.fill")
                                .font(LiveCashTheme.captionFont.weight(.semibold))
                                .foregroundStyle(.orange)
                            Text("Login-Serie")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                if totalTarget > 0 {
                    ProgressView(value: min(totalSaved / totalTarget, 1))
                        .tint(LiveCashTheme.income)
                }
            }
        }
    }
}
