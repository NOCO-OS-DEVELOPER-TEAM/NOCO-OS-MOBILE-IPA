import Foundation
import CoreLocation

struct MapPinDisplay: Identifiable {
    let id: UUID
    let transaction: Transaction
    let coordinate: CLLocationCoordinate2D
    let clusterSize: Int
    /// Absolute expense total at this place (red).
    let expenseTotal: Double
    /// Absolute income total at this place (green).
    let incomeTotal: Double
    /// Net signed sum (income − expense).
    let clusterTotal: Double
    let isClusterRepresentative: Bool
    let placeTitle: String
    let lastVisit: Date
    let clusteredTransactions: [Transaction]

    var dominantType: TransactionType {
        incomeTotal > expenseTotal ? .income : .expense
    }

    var displayAmount: Double {
        if expenseTotal > 0 && incomeTotal == 0 { return expenseTotal }
        if incomeTotal > 0 && expenseTotal == 0 { return incomeTotal }
        return abs(clusterTotal)
    }

    var placeDetail: MapPlaceDetail {
        MapPlaceDetail(
            id: id,
            title: placeTitle,
            visitCount: clusterSize,
            expenseTotal: expenseTotal,
            incomeTotal: incomeTotal,
            netTotal: clusterTotal,
            lastVisit: lastVisit,
            transactions: clusteredTransactions,
            dominantType: dominantType
        )
    }
}

enum MapPinLayout {
    /// Groups pins by location (+ optional merchant) and spreads clusters in a ring.
    static func layout(transactions: [Transaction], clusterModeEnabled: Bool = true) -> [MapPinDisplay] {
        let located: [(Transaction, CLLocationCoordinate2D)] = transactions.compactMap { tx in
            guard let loc = tx.location else { return nil }
            return (tx, loc.coordinate)
        }

        let groups = Dictionary(grouping: located) { item in
            let merchantKey = item.0.merchant
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            return coordinateKey(item.1, clusterModeEnabled: clusterModeEnabled) + "|" + merchantKey
        }

        var result: [MapPinDisplay] = []

        for (_, items) in groups.sorted(by: { $0.value.count > $1.value.count }) {
            let sorted = items.sorted { $0.0.date > $1.0.date }
            let center = sorted[0].1
            let txs = sorted.map(\.0)
            let expenses = txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let incomes = txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let net = incomes - expenses
            let count = sorted.count
            let title = bestPlaceTitle(for: txs)
            let lastVisit = sorted[0].0.date
            let clusterId = sorted[0].0.id

            if count == 1 {
                let tx = sorted[0].0
                result.append(MapPinDisplay(
                    id: tx.id,
                    transaction: tx,
                    coordinate: center,
                    clusterSize: 1,
                    expenseTotal: tx.type == .expense ? tx.amount : 0,
                    incomeTotal: tx.type == .income ? tx.amount : 0,
                    clusterTotal: tx.signedAmount,
                    isClusterRepresentative: true,
                    placeTitle: title,
                    lastVisit: lastVisit,
                    clusteredTransactions: txs
                ))
                continue
            }

            // One representative pin for the place — avoids visual overlap for many visits.
            result.append(MapPinDisplay(
                id: clusterId,
                transaction: sorted[0].0,
                coordinate: center,
                clusterSize: count,
                expenseTotal: expenses,
                incomeTotal: incomes,
                clusterTotal: net,
                isClusterRepresentative: true,
                placeTitle: title,
                lastVisit: lastVisit,
                clusteredTransactions: txs
            ))
        }

        return spreadNearbyPins(result)
    }

    /// Pushes nearby place pins farther apart so they stay readable.
    private static func spreadNearbyPins(_ pins: [MapPinDisplay]) -> [MapPinDisplay] {
        guard pins.count > 1 else { return pins }
        var adjusted = pins
        let minSeparation = 0.00035

        for i in 0..<adjusted.count {
            var offsetLat = 0.0
            var offsetLon = 0.0
            var neighbors = 0
            for j in 0..<adjusted.count where i != j {
                let dLat = adjusted[i].coordinate.latitude - adjusted[j].coordinate.latitude
                let dLon = adjusted[i].coordinate.longitude - adjusted[j].coordinate.longitude
                let dist = sqrt(dLat * dLat + dLon * dLon)
                if dist < minSeparation {
                    neighbors += 1
                    let angle = Double(i * 47 + neighbors * 73) * .pi / 180
                    let push = (minSeparation - dist) * 0.65 + 0.00012
                    offsetLat += cos(angle) * push
                    offsetLon += sin(angle) * push
                }
            }
            if neighbors > 0 {
                let pin = adjusted[i]
                let coord = CLLocationCoordinate2D(
                    latitude: pin.coordinate.latitude + offsetLat,
                    longitude: pin.coordinate.longitude + offsetLon
                )
                adjusted[i] = MapPinDisplay(
                    id: pin.id,
                    transaction: pin.transaction,
                    coordinate: coord,
                    clusterSize: pin.clusterSize,
                    expenseTotal: pin.expenseTotal,
                    incomeTotal: pin.incomeTotal,
                    clusterTotal: pin.clusterTotal,
                    isClusterRepresentative: pin.isClusterRepresentative,
                    placeTitle: pin.placeTitle,
                    lastVisit: pin.lastVisit,
                    clusteredTransactions: pin.clusteredTransactions
                )
            }
        }
        return adjusted
    }

    private static func bestPlaceTitle(for transactions: [Transaction]) -> String {
        if let labeled = transactions.compactMap({ $0.location?.label }).first(where: { !$0.isEmpty }) {
            return labeled
        }
        let merchants = Dictionary(grouping: transactions, by: \.merchant)
        return merchants.max(by: { $0.value.count < $1.value.count })?.key
            ?? transactions.first?.merchant
            ?? "Standort"
    }

    private static func coordinateKey(_ c: CLLocationCoordinate2D, clusterModeEnabled: Bool) -> String {
        if clusterModeEnabled {
            return String(format: "%.4f,%.4f", c.latitude, c.longitude)
        }
        return String(format: "%.5f,%.5f", c.latitude, c.longitude)
    }
}
