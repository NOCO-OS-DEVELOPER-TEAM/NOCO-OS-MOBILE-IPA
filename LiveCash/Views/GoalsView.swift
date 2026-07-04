import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var editingGoal: SavingsGoal?

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
                ForEach(store.goals) { goal in
                    Button {
                        editingGoal = goal
                    } label: {
                        GoalCard(
                            goal: goal,
                            monthlySavingsRate: store.monthlySavingsRate,
                            showProgress: store.appSettings.savings.showProgress
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions {
                        Button("+\(50)€") {
                            store.addToGoal(goal, amount: 50)
                        }
                        .tint(LiveCashTheme.income)
                    }
                }
                .onDelete { idx in
                    idx.forEach { store.deleteGoal(store.goals[$0]) }
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
                    if store.savingsStreakDays > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("\(store.savingsStreakDays) Tage", systemImage: "flame.fill")
                                .font(LiveCashTheme.captionFont.weight(.semibold))
                                .foregroundStyle(LiveCashTheme.expense)
                            Text("Spar-Streak")
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
