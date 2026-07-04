import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var name = ""
    @State private var target = ""

    var body: some View {
        List {
            if store.goals.isEmpty {
                ContentUnavailableView(
                    "Keine Sparziele",
                    systemImage: "target",
                    description: Text("Lege ein Ziel an — z. B. Urlaub oder neues iPhone.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(store.goals) { goal in
                    GoalCard(goal: goal)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions {
                            Button("+\(50)€") {
                                store.addToGoal(goal, amount: 50)
                            }
                            .tint(LiveCashTheme.accent)
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
        .alert("Neues Sparziel", isPresented: $showAdd) {
            TextField("Name", text: $name)
            TextField("Zielbetrag", text: $target)
                .keyboardType(.decimalPad)
            Button("Abbrechen", role: .cancel) {
                resetForm()
            }
            Button("Anlegen") {
                if let amount = Double(target.replacingOccurrences(of: ",", with: ".")), !name.isEmpty {
                    store.addGoal(name: name, target: amount)
                }
                resetForm()
            }
        } message: {
            Text("Wie viel möchtest du sparen?")
        }
    }

    private func resetForm() {
        name = ""
        target = ""
    }
}
