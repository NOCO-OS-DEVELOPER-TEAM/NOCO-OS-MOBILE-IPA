import Foundation
import CoreLocation
import SwiftUI

enum MapHeatIntensity: String, Equatable {
    case expensive
    case normal
    case frugal

    var label: String {
        switch self {
        case .expensive: return "teuer"
        case .normal: return "normal"
        case .frugal: return "sparsam"
        }
    }

    var color: Color {
        switch self {
        case .expensive: return Color(red: 0.94, green: 0.32, blue: 0.36)
        case .normal: return Color(red: 0.95, green: 0.72, blue: 0.2)
        case .frugal: return Color(red: 0.15, green: 0.78, blue: 0.42)
        }
    }
}

struct MapHeatZone: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let isIncome: Bool
    let total: Double
    let intensity: MapHeatIntensity
    let placeTitle: String
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

        let expenseTotals = groups.values.map { items in
            items.filter { $0.0.type == .expense }.reduce(0) { $0 + $1.0.amount }
        }.filter { $0 > 0 }.sorted()
        let median = expenseTotals.isEmpty ? 0 : expenseTotals[expenseTotals.count / 2]

        return groups.compactMap { key, items in
            let center = items[0].1
            let expenses = items.filter { $0.0.type == .expense }.reduce(0) { $0 + $1.0.amount }
            let income = items.filter { $0.0.type == .income }.reduce(0) { $0 + $1.0.amount }
            let dominantIncome = income > expenses
            let total = max(expenses, income)
            guard total > 0 else { return nil }
            let radius = min(400, 120 + Double(items.count) * 40)
            let title = dominantTitle(from: items.map(\.0))
            let intensity: MapHeatIntensity
            if dominantIncome {
                intensity = .frugal
            } else if median <= 0 {
                intensity = .normal
            } else if expenses >= median * 1.5 {
                intensity = .expensive
            } else if expenses <= median * 0.6 {
                intensity = .frugal
            } else {
                intensity = .normal
            }
            return MapHeatZone(
                id: key,
                coordinate: center,
                radius: radius,
                isIncome: dominantIncome,
                total: total,
                intensity: intensity,
                placeTitle: title
            )
        }
    }

    static func hotspots(from transactions: [Transaction], limit: Int = 5) -> [AnalyticsHotspot] {
        zones(from: transactions)
            .filter { !$0.isIncome }
            .sorted { $0.total > $1.total }
            .prefix(limit)
            .map {
                AnalyticsHotspot(
                    id: $0.id,
                    title: $0.placeTitle,
                    amount: $0.total,
                    intensity: $0.intensity,
                    coordinate: $0.coordinate
                )
            }
    }

    private static func dominantTitle(from transactions: [Transaction]) -> String {
        let merchants = Dictionary(grouping: transactions, by: \.merchant)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
        if let top = merchants.first, !top.0.isEmpty {
            return top.0
        }
        return "Unbekannter Ort"
    }
}
