import Foundation
import CoreLocation

enum TransactionType: String, Codable {
    case income
    case expense
}

struct TransactionLocation: Codable, Equatable, Hashable {
    var latitude: Double
    var longitude: Double
    var label: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Transaction: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var amount: Double
    var type: TransactionType
    var category: FinanceCategory
    var merchant: String
    var date: Date
    var location: TransactionLocation?
    var rawInput: String?
    var ocrText: String?
    var accountId: UUID?
    var userCategoryId: UUID?

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        category: FinanceCategory,
        merchant: String,
        date: Date = Date(),
        location: TransactionLocation? = nil,
        rawInput: String? = nil,
        ocrText: String? = nil,
        accountId: UUID? = nil,
        userCategoryId: UUID? = nil
    ) {
        self.id = id
        self.amount = abs(amount)
        self.type = type
        self.category = category
        self.merchant = merchant
        self.date = date
        self.location = location
        self.rawInput = rawInput
        self.ocrText = ocrText
        self.accountId = accountId
        self.userCategoryId = userCategoryId
    }

    enum CodingKeys: String, CodingKey {
        case id, amount, type, category, merchant, date, location, rawInput, ocrText, accountId, userCategoryId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        amount = try c.decode(Double.self, forKey: .amount)
        type = try c.decode(TransactionType.self, forKey: .type)
        category = try c.decode(FinanceCategory.self, forKey: .category)
        merchant = try c.decode(String.self, forKey: .merchant)
        date = try c.decode(Date.self, forKey: .date)
        location = try c.decodeIfPresent(TransactionLocation.self, forKey: .location)
        rawInput = try c.decodeIfPresent(String.self, forKey: .rawInput)
        ocrText = try c.decodeIfPresent(String.self, forKey: .ocrText)
        accountId = try c.decodeIfPresent(UUID.self, forKey: .accountId)
        userCategoryId = try c.decodeIfPresent(UUID.self, forKey: .userCategoryId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(amount, forKey: .amount)
        try c.encode(type, forKey: .type)
        try c.encode(category, forKey: .category)
        try c.encode(merchant, forKey: .merchant)
        try c.encode(date, forKey: .date)
        try c.encodeIfPresent(location, forKey: .location)
        try c.encodeIfPresent(rawInput, forKey: .rawInput)
        try c.encodeIfPresent(ocrText, forKey: .ocrText)
        try c.encodeIfPresent(accountId, forKey: .accountId)
        try c.encodeIfPresent(userCategoryId, forKey: .userCategoryId)
    }

    var signedAmount: Double {
        type == .income ? amount : -amount
    }

    var formattedAmount: String {
        let prefix = type == .income ? "+" : "-"
        return String(format: "%@%.2f€", prefix, amount)
    }
}
