import SwiftUI
import MapKit

struct MoneyMapView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedCategory: FinanceCategory?
    @State private var selectedID: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapSelectedDate = Date()

    private var mapEndDate: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: mapSelectedDate) ?? mapSelectedDate
    }

    private var filteredTransactions: [Transaction] {
        store.accountFilteredTransactions.filter { tx in
            guard tx.location != nil, tx.date <= mapEndDate else { return false }
            if let cat = selectedCategory { return tx.category == cat }
            return true
        }
    }

    private var heatZones: [MapHeatZone] {
        MapHeatLayout.zones(from: filteredTransactions)
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

    private var earliestMapDate: Date {
        let dates = store.accountFilteredTransactions.filter { $0.location != nil }.map(\.date)
        return dates.min() ?? Date()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapSummaryBar
                categoryFilter
                mapContent
                timelineBar
                transactionDetail
            }
            .navigationTitle("Geldkarte")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.ensureLocationForMap()
                adjustCamera()
            }
            .onChange(of: pinDisplays.count) { _, _ in adjustCamera() }
            .onChange(of: mapSelectedDate) { _, _ in adjustCamera() }
        }
    }

    private var mapSummaryBar: some View {
        HStack {
            Label("\(filteredTransactions.count) mit Standort", systemImage: "mappin.and.ellipse")
            Spacer()
            Text(mapSelectedDate.formatted(date: .abbreviated, time: .omitted))
                .foregroundStyle(.secondary)
        }
        .font(LiveCashTheme.captionFont)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var timelineBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Zeitverlauf")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
                Spacer()
                if Calendar.current.isDateInToday(mapSelectedDate) {
                    Text("Heute")
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                        .foregroundStyle(LiveCashTheme.accent)
                }
            }
            Slider(
                value: Binding(
                    get: { mapSelectedDate.timeIntervalSince1970 },
                    set: { mapSelectedDate = Date(timeIntervalSince1970: $0) }
                ),
                in: earliestMapDate.timeIntervalSince1970...Date().timeIntervalSince1970
            )
            .tint(LiveCashTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(heatZones) { zone in
                MapCircle(center: zone.coordinate, radius: zone.radius)
                    .foregroundStyle(
                        (zone.isIncome ? LiveCashTheme.income : LiveCashTheme.expense)
                            .opacity(min(0.35, 0.12 + zone.total / 500))
                    )
            }
            ForEach(pinDisplays) { pin in
                Annotation(pin.transaction.merchant, coordinate: pin.coordinate) {
                    Button {
                        selectedID = pin.transaction.id
                    } label: {
                        MapPinView(
                            amount: pin.transaction.amount,
                            type: pin.transaction.type,
                            selected: selectedID == pin.transaction.id,
                            clusterSize: pin.clusterSize > 1 ? pin.clusterSize : nil,
                            clusterTotal: pin.clusterSize > 1 ? pin.clusterTotal : nil,
                            dimmed: pin.clusterSize > 1 && !pin.isClusterRepresentative,
                            opacity: pinOpacity(for: pin.transaction)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    private func pinOpacity(for tx: Transaction) -> Double {
        let cal = Calendar.current
        if cal.isDate(tx.date, inSameDayAs: mapSelectedDate) { return 1 }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: tx.date), to: cal.startOfDay(for: mapSelectedDate)).day ?? 0
        return max(0.2, 1.0 - Double(days) / 21.0)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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
            .padding(.vertical, 8)
        }
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
    let type: TransactionType
    let selected: Bool
    var clusterSize: Int?
    var clusterTotal: Double?
    var dimmed: Bool = false
    var opacity: Double = 1

    private var pinColor: Color {
        type == .income ? LiveCashTheme.income : LiveCashTheme.expense
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: clusterSize != nil ? "mappin.and.ellipse" : "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(selected ? LiveCashTheme.accent : pinColor)
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
        .opacity(opacity)
    }
}
