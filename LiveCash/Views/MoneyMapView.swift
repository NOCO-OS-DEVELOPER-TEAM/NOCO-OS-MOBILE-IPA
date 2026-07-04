import SwiftUI
import MapKit

struct MoneyMapView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedCategory: FinanceCategory?
    @State private var selectedID: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var filteredTransactions: [Transaction] {
        store.transactions.filter { tx in
            guard tx.location != nil, tx.type == .expense else { return false }
            if let cat = selectedCategory { return tx.category == cat }
            return true
        }
    }

    private var pinDisplays: [MapPinDisplay] {
        MapPinLayout.layout(transactions: filteredTransactions)
    }

    private var locationGroupCount: Int {
        let keys = filteredTransactions.compactMap { tx -> String? in
            guard let loc = tx.location else { return nil }
            return String(format: "%.3f,%.3f", loc.latitude, loc.longitude)
        }
        return Set(keys).count
    }

    private var selectedTransaction: Transaction? {
        guard let selectedID else { return nil }
        return filteredTransactions.first { $0.id == selectedID }
    }

    private var selectedPin: MapPinDisplay? {
        guard let selectedID else { return nil }
        return pinDisplays.first { $0.transaction.id == selectedID }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapSummaryBar
                categoryFilter
                mapContent
                transactionDetail
            }
            .navigationTitle("Geldkarte")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { adjustCamera() }
            .onChange(of: pinDisplays.count) { _, _ in adjustCamera() }
        }
    }

    private var mapSummaryBar: some View {
        HStack {
            Label("\(filteredTransactions.count) Ausgaben", systemImage: "mappin.and.ellipse")
            Spacer()
            if locationGroupCount > 0 {
                Text("\(locationGroupCount) Orte")
                    .foregroundStyle(.secondary)
            }
        }
        .font(LiveCashTheme.captionFont)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            ForEach(pinDisplays) { pin in
                Annotation(pin.transaction.merchant, coordinate: pin.coordinate) {
                    Button {
                        selectedID = pin.transaction.id
                    } label: {
                        MapPinView(
                            amount: pin.transaction.amount,
                            selected: selectedID == pin.transaction.id,
                            clusterSize: pin.clusterSize > 1 ? pin.clusterSize : nil,
                            clusterTotal: pin.clusterSize > 1 ? pin.clusterTotal : nil,
                            dimmed: pin.clusterSize > 1 && !pin.isClusterRepresentative
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(pin.clusterSize > 1 && !pin.isClusterRepresentative ? 0.75 : 1)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    @ViewBuilder
    private var transactionDetail: some View {
        if let tx = selectedTransaction {
            VStack(spacing: 8) {
                if let pin = selectedPin, pin.clusterSize > 1 {
                    HStack {
                        Image(systemName: "circle.grid.2x2.fill")
                            .foregroundStyle(LiveCashTheme.accent)
                        Text("\(pin.clusterSize) Ausgaben · \(String(format: "%.2f€", pin.clusterTotal)) gesamt")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                NavigationLink {
                    TransactionDetailView(transactionID: tx.id)
                } label: {
                    TransactionRow(transaction: tx)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
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
                .background(active ? LiveCashTheme.accent : Color.clear)
                .foregroundStyle(active ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(active ? Color.clear : LiveCashTheme.glassBorder, lineWidth: 0.6)
                )
        }
        .buttonStyle(.plain)
    }

    private func adjustCamera() {
        let coords = pinDisplays.map(\.coordinate)
        guard !coords.isEmpty else {
            cameraPosition = .automatic
            return
        }
        if coords.count == 1 {
            cameraPosition = .region(MKCoordinateRegion(
                center: coords[0],
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            ))
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
    var clusterSize: Int?
    var clusterTotal: Double?
    var dimmed: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: clusterSize != nil ? "mappin.and.ellipse" : "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(selected ? LiveCashTheme.accent : LiveCashTheme.expense)
                if let clusterSize, clusterSize > 1 {
                    Text("\(clusterSize)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(LiveCashTheme.accent)
                        .clipShape(Circle())
                        .offset(x: 8, y: -6)
                }
            }
            if let clusterTotal, let clusterSize, clusterSize > 1 {
                Text(String(format: "%.0f€", clusterTotal))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            } else if !dimmed {
                Text(String(format: "%.0f€", amount))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
    }
}
