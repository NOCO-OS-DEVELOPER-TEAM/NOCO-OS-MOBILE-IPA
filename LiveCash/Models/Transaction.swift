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
        accountId: UUID? = nil
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
    }

    var signedAmount: Double {
        type == .income ? amount : -amount
    }

    var formattedAmount: String {
        let prefix = type == .income ? "+" : "-"
        return String(format: "%@%.2f€", prefix, amount)
    }
}
