import Foundation
import CoreLocation

struct MapHeatZone: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let isIncome: Bool
    let total: Double
}

enum MapHeatLayout {
    static func zones(from transactions: [Transaction]) -> [MapHeatZone] {
        let located = transactions.compactMap { tx -> (Transaction, CLLocationCoordinate2D)? in
            guard let loc = tx.location else { return nil }
            return (tx, loc.coordinate)
        }
        let groups = Dictionary(grouping: located) { item in
            String(format: "%.3f,%.3f", item.1.latitude, item.1.longitude)
        }

        return groups.compactMap { key, items in
            let center = items[0].1
            let expenses = items.filter { $0.0.type == .expense }.reduce(0) { $0 + $1.0.amount }
            let income = items.filter { $0.0.type == .income }.reduce(0) { $0 + $1.0.amount }
            let dominantIncome = income > expenses
            let total = max(expenses, income)
            guard total > 0 else { return nil }
            let radius = min(400, 120 + Double(items.count) * 40)
            return MapHeatZone(
                id: key,
                coordinate: center,
                radius: radius,
                isIncome: dominantIncome,
                total: total
            )
        }
    }
}
