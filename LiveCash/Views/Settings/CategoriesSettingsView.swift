import SwiftUI

struct CategoriesSettingsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var editingCategory: UserCategory?

    var body: some View {
        List {
            Section {
                ForEach(store.userCategories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .foregroundStyle(LiveCashTheme.accent)
                                .frame(width: 28)
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        store.deleteUserCategory(id: store.userCategories[index].id)
                    }
                }
            } header: {
                Text("Eigene Kategorien")
            } footer: {
                Text("Eigene Kategorien erscheinen in Buchungen, der Geldkarte, im Smart Assistant und in Auswertungen.")
            }

            Section("Standard") {
                ForEach(FinanceCategory.allCases.filter { $0 != .income }) { cat in
                    HStack(spacing: 12) {
                        Image(systemName: cat.icon)
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                        Text(cat.rawValue)
                    }
                }
            }
        }
        .navigationTitle("Kategorien")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Neu") { showAdd = true }
            }
        }
        .sheet(isPresented: $showAdd) {
            CategoryEditorSheet(title: "Neue Kategorie") { name, icon in
                store.addUserCategory(name: name, icon: icon)
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(title: "Kategorie bearbeiten", initialName: category.name, initialIcon: category.icon) { name, icon in
                store.updateUserCategory(id: category.id, name: name, icon: icon)
            }
        }
    }
}

private struct CategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var initialName = ""
    var initialIcon = "tag.fill"
    let onSave: (String, String) -> Void

    @State private var name: String
    @State private var icon: String

    init(title: String, initialName: String = "", initialIcon: String = "tag.fill", onSave: @escaping (String, String) -> Void) {
        self.title = title
        self.initialName = initialName
        self.initialIcon = initialIcon
        self.onSave = onSave
        _name = State(initialValue: initialName)
        _icon = State(initialValue: initialIcon)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(UserCategory.iconOptions, id: \.self) { option in
                            Button {
                                icon = option
                            } label: {
                                Image(systemName: option)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(icon == option ? LiveCashTheme.accent.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, icon)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
