import Foundation

struct UserCategory: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, icon: String = "tag.fill", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }

    static let iconOptions = [
        "tag.fill", "cart.fill", "car.fill", "bag.fill", "heart.fill",
        "house.fill", "film.fill", "cup.and.saucer.fill", "gift.fill",
        "pawprint.fill", "book.fill", "sportscourt.fill", "airplane",
        "creditcard.fill", "leaf.fill", "star.fill"
    ]
}

struct OnboardingProfile: Codable, Equatable {
    var focusGoal: String
    var budgetTrackingEnabled: Bool

    static let focusOptions = ["Sparen", "Überblick", "Kontrolle"]
}
