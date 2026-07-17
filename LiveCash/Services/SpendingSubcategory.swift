import Foundation

/// Fine-grained spend type under a main FinanceCategory — detected automatically from merchant/text.
enum SpendingSubcategory: String, Codable, CaseIterable, Identifiable {
    case restaurant = "Restaurant"
    case fastFood = "Fast Food"
    case supermarket = "Supermarkt"
    case cafe = "Café"
    case fuel = "Tanken"
    case publicTransit = "ÖPNV"
    case rideshare = "Ride-Sharing"
    case fashion = "Mode"
    case electronics = "Elektronik"
    case streaming = "Streaming"
    case gaming = "Gaming"
    case pharmacy = "Apotheke"
    case rent = "Miete"
    case utilities = "Nebenkosten"

    var id: String { rawValue }

    var parent: FinanceCategory {
        switch self {
        case .restaurant, .fastFood, .supermarket, .cafe: return .food
        case .fuel, .publicTransit, .rideshare: return .transport
        case .fashion, .electronics: return .shopping
        case .streaming: return .subscription
        case .gaming: return .entertainment
        case .pharmacy: return .health
        case .rent, .utilities: return .housing
        }
    }

    static func detect(from text: String) -> SpendingSubcategory? {
        let lower = text.lowercased()
        let rules: [(SpendingSubcategory, [String])] = [
            (.supermarket, ["lidl", "aldi", "rewe", "edeka", "netto", "penny", "kaufland", "supermarkt"]),
            (.fastFood, ["mcdonald", "burger king", "kfc", "subway", "döner", "doener", "kebab", "pizza hut"]),
            (.restaurant, ["restaurant", "gasthaus", "wirtshaus", "trattoria", "sushi"]),
            (.cafe, ["café", "cafe", "starbucks", "coffee", "bäckerei", "baeckerei", "barista"]),
            (.fuel, ["tank", "shell", "aral", "esso", "jet ", "benzin"]),
            (.publicTransit, ["db ", "bahn", "bus", "tram", "öpnv", "oepnv", "hvv", "bvg", "mvg"]),
            (.rideshare, ["uber", "bolt", "free now", "taxi"]),
            (.fashion, ["zalando", "h&m", "zara", "about you", "snipes", "nike", "adidas"]),
            (.electronics, ["mediamarkt", "saturn", "apple store", "cyberport", "alternate"]),
            (.streaming, ["netflix", "spotify", "disney", "amazon prime", "youtube premium", "apple music", "paramount"]),
            (.gaming, ["steam", "playstation", "xbox", "nintendo", "epic games", "game"]),
            (.pharmacy, ["apotheke", "dm ", "rossmann", "docmorris"]),
            (.rent, ["miete", "warmmiete", "kaltmiete"]),
            (.utilities, ["strom", "gas", "wasser", "internet", "telekom", "vodafone", "o2"])
        ]
        for (sub, keys) in rules where keys.contains(where: { lower.contains($0) }) {
            return sub
        }
        return nil
    }
}
