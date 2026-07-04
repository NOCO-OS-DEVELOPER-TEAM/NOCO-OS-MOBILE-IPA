import Foundation

struct FinanceAccount: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var isDefault: Bool

    init(id: UUID = UUID(), name: String, icon: String = "person.fill", sortOrder: Int = 0, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }

    static let defaultPrivate = FinanceAccount(name: "Privat", icon: "person.fill", sortOrder: 0, isDefault: true)
}
