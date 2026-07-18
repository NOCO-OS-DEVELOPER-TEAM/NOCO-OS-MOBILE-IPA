import Foundation

enum FinanceCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Lebensmittel"
    case transport = "Transport"
    case shopping = "Einkaufen"
    case subscription = "Abonnement"
    case entertainment = "Unterhaltung"
    case health = "Gesundheit"
    case housing = "Wohnen"
    case income = "Einkommen"
    case other = "Sonstiges"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "cart.fill"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .subscription: return "repeat.circle.fill"
        case .entertainment: return "film.fill"
        case .health: return "heart.fill"
        case .housing: return "house.fill"
        case .income: return "arrow.down.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    static func detect(from text: String) -> FinanceCategory {
        if let sub = SpendingSubcategory.detect(from: text) {
            return sub.parent
        }
        let lower = text.lowercased()
        let rules: [(FinanceCategory, [String])] = [
            (.food, [
                "lidl", "aldi", "rewe", "edeka", "netto", "penny", "food", "essen", "pizza", "restaurant",
                "bäcker", "baecker", "kaffee", "mcdonald", "burger",
                "sprite", "cola", "fanta", "wasser", "getränk", "getraenk", "saft", "bier", "energy",
                "red bull", "monster", "trink", "snack", "chips", "schokolade", "eis "
            ]),
            (.transport, ["tank", "benzin", "db ", "bahn", "uber", "bolt", "bus", "ticket", "park"]),
            (.shopping, ["amazon", "zalando", "h&m", "ikea", "mediamarkt", "saturn", "shop"]),
            (.subscription, ["netflix", "spotify", "disney", "apple music", "youtube", "abo", "subscription", "prime", "gym", "fitness"]),
            (.entertainment, ["kino", "game", "steam", "playstation", "xbox", "konzert"]),
            (.health, ["apotheke", "arzt", "kranken", "dm ", "rossmann"]),
            (.housing, ["miete", "strom", "gas", "internet", "telekom", "vodafone", "o2"]),
            (.income, ["gehalt", "salary", "lohn", "einkommen", "überweisung"])
        ]
        for (category, keywords) in rules {
            if keywords.contains(where: { lower.contains($0) }) {
                return category
            }
        }
        return .other
    }
}
