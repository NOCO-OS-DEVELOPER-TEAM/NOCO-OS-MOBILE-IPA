import SwiftUI
import MapKit

struct MoneyMapView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedCategory: FinanceCategory?
    @State private var selectedTransaction: Transaction?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var mappedTransactions: [Transaction] {
        store.transactions.filter { tx in
            guard tx.location != nil, tx.type == .expense else { return false }
            if let cat = selectedCategory { return tx.category == cat }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilter
                Map(position: $cameraPosition, selection: $selectedTransaction) {
                    ForEach(mappedTransactions) { tx in
                        if let loc = tx.location {
                            Annotation(tx.merchant, coordinate: loc.coordinate) {
                                MapPinView(amount: tx.amount, selected: selectedTransaction?.id == tx.id)
                            }
                            .tag(tx)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .onAppear(adjustCamera)
                .onChange(of: mappedTransactions.count) { _, _ in adjustCamera() }

                if let tx = selectedTransaction {
                    TransactionRow(transaction: tx)
                        .padding()
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Geldkarte")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "Alle", active: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(FinanceCategory.allCases.filter { $0 != .income }) { cat in
                    filterChip(title: cat.rawValue, active: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(LiveCashTheme.screenBackground)
    }

    private func filterChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LiveCashTheme.captionFont)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? LiveCashTheme.accent : LiveCashTheme.cardBackground)
                .foregroundStyle(active ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func adjustCamera() {
        let coords = mappedTransactions.compactMap { $0.location?.coordinate }
        guard !coords.isEmpty else {
            cameraPosition = .automatic
            return
        }
        if coords.count == 1, let c = coords.first {
            cameraPosition = .region(MKCoordinateRegion(center: c, latitudinalMeters: 2000, longitudinalMeters: 2000))
            return
        }
        var rect = MKMapRect.null
        for c in coords {
            let point = MKMapPoint(c)
            rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        cameraPosition = .rect(rect.insetBy(dx: -rect.size.width * 0.2, dy: -rect.size.height * 0.2))
    }
}

private struct MapPinView: View {
    let amount: Double
    let selected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(selected ? LiveCashTheme.accent : LiveCashTheme.expense)
            Text(String(format: "%.0f€", amount))
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}
