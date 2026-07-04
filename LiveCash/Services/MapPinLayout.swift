import Foundation
import CoreLocation

struct MapPinDisplay: Identifiable {
    let id: UUID
    let transaction: Transaction
    let coordinate: CLLocationCoordinate2D
    let clusterSize: Int
    let clusterTotal: Double
    let isClusterRepresentative: Bool
}

enum MapPinLayout {
    /// Gruppiert Pins am gleichen Ort und streut sie in einem Ring auseinander.
    static func layout(transactions: [Transaction], clusterModeEnabled: Bool = true) -> [MapPinDisplay] {
        let located: [(Transaction, CLLocationCoordinate2D)] = transactions.compactMap { tx in
            guard let loc = tx.location else { return nil }
            return (tx, loc.coordinate)
        }

        let groups = Dictionary(grouping: located) { item in
            coordinateKey(item.1, clusterModeEnabled: clusterModeEnabled)
        }

        var result: [MapPinDisplay] = []

        for (_, items) in groups.sorted(by: { $0.value.count > $1.value.count }) {
            let sorted = items.sorted { $0.0.date > $1.0.date }
            let center = sorted[0].1
            let total = sorted.reduce(0) { $0 + $1.0.amount }
            let count = sorted.count

            if count == 1 {
                let tx = sorted[0].0
                result.append(MapPinDisplay(
                    id: tx.id,
                    transaction: tx,
                    coordinate: center,
                    clusterSize: 1,
                    clusterTotal: tx.amount,
                    isClusterRepresentative: true
                ))
                continue
            }

            let radius = min(0.00024, 0.00007 + Double(count) * 0.000018)
            for (index, item) in sorted.enumerated() {
                let angle = (Double(index) / Double(count)) * 2 * Double.pi - Double.pi / 2
                let lat = center.latitude + radius * cos(angle)
                let lon = center.longitude + radius * sin(angle)
                result.append(MapPinDisplay(
                    id: item.0.id,
                    transaction: item.0,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    clusterSize: count,
                    clusterTotal: total,
                    isClusterRepresentative: index == 0
                ))
            }
        }

        return result
    }

    private static func coordinateKey(_ c: CLLocationCoordinate2D, clusterModeEnabled: Bool) -> String {
        if clusterModeEnabled {
            return String(format: "%.4f,%.4f", c.latitude, c.longitude)
        }
        return String(format: "%.5f,%.5f", c.latitude, c.longitude)
    }
}
