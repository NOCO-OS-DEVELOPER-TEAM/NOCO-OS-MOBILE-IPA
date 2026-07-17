import SwiftUI
import MapKit

struct MoneyMapView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedCategory: FinanceCategory?
    @State private var selectedID: UUID?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
            latitudinalMeters: 450_000,
            longitudinalMeters: 450_000
        )
    )
    @State private var mapSelectedDate = Date()
    @State private var placeDetail: MapPlaceDetail?
    @State private var showFilters = false
    @State private var lastTimelineHapticDay: Date?

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

    private var topHotspot: MapHeatZone? {
        heatZones.filter { !$0.isIncome }.max(by: { $0.total < $1.total })
    }

    private var pinDisplays: [MapPinDisplay] {
        MapPinLayout.layout(
            transactions: filteredTransactions,
            clusterModeEnabled: store.appSettings.map.clusterModeEnabled
        )
    }

    private var selectedPin: MapPinDisplay? {
        guard let selectedID else { return nil }
        return pinDisplays.first { $0.id == selectedID }
    }

    private var earliestMapDate: Date {
        let dates = store.accountFilteredTransactions.filter { $0.location != nil }.map(\.date)
        return dates.min() ?? Date()
    }

    /// All known map coordinates (ignore timeline) — keeps overview stable while scrubbing.
    private var overviewCoordinates: [CLLocationCoordinate2D] {
        store.accountFilteredTransactions.compactMap { $0.location?.coordinate }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapContent
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    topGlassBar
                    if let hotspot = topHotspot, selectedPin == nil {
                        hotspotCaption(hotspot)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Spacer(minLength: 0)
                    if showFilters {
                        filterGlassPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if store.appSettings.map.timelineHistoryEnabled {
                        timelineGlass
                    }
                    if selectedPin != nil {
                        transactionDetail
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .safeAreaPadding(.bottom, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                store.ensureLocationForMap()
                resetToOverview()
            }
            .onChange(of: store.mapResetEpoch) { _, _ in
                resetToOverview()
            }
            .onChange(of: mapSelectedDate) { _, newDate in
                // Keep camera locked — only pins change.
                let day = Calendar.current.startOfDay(for: newDate)
                if lastTimelineHapticDay != day {
                    lastTimelineHapticDay = day
                    HapticService.selection(store: store)
                }
                if let selectedID, !pinDisplays.contains(where: { $0.id == selectedID }) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.selectedID = nil
                    }
                }
            }
            .sheet(item: $placeDetail) { detail in
                MapPlaceDetailSheet(detail: detail)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: showFilters)
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedID)
            .animation(.easeInOut(duration: 0.28), value: pinDisplays.map(\.id))
        }
    }

    private func hotspotCaption(_ zone: MapHeatZone) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(zone.intensity.color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Teuerster Ort")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("\(zone.placeTitle) · \(String(format: "%.0f€", zone.total))")
                    .font(LiveCashTheme.captionFont.weight(.semibold))
            }
            Spacer()
            Text(zone.intensity.label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(zone.intensity.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var topGlassBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Geldkarte")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text("\(pinDisplays.count) Orte · \(filteredTransactions.count) Buchungen")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            mapToolButton(systemName: "line.3.horizontal.decrease.circle.fill", active: showFilters || selectedCategory != nil) {
                showFilters.toggle()
                HapticService.light(store: store)
            }
            mapToolButton(systemName: "arrow.counterclockwise.circle.fill") {
                resetToOverview()
                HapticService.light(store: store)
            }
            mapToolButton(systemName: "location.circle.fill", active: true) {
                centerOnUserOrOverview()
                HapticService.light(store: store)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private func mapToolButton(systemName: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(active ? LiveCashTheme.accent : .primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PremiumPressStyle())
        .accessibilityLabel(systemName)
    }

    private var filterGlassPanel: some View {
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
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var timelineGlass: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Zeitverlauf")
                    .font(LiveCashTheme.captionFont.weight(.semibold))
                Spacer()
                Text(mapSelectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
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
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            if store.appSettings.map.detailLevel != .minimal {
                ForEach(heatZones) { zone in
                    MapCircle(center: zone.coordinate, radius: zone.radius)
                        .foregroundStyle(
                            zone.intensity.color.opacity(min(0.32, 0.12 + zone.total / 700))
                        )
                }
            }
            ForEach(pinDisplays) { pin in
                Annotation(pin.placeTitle, coordinate: pin.coordinate) {
                    Button {
                        HapticService.light(store: store)
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                            if selectedID == pin.id {
                                selectedID = nil
                                setOverviewCamera(animated: true)
                            } else {
                                selectedID = pin.id
                                if store.appSettings.map.pinZoomEnabled {
                                    zoomToPin(pin.coordinate)
                                }
                            }
                        }
                    } label: {
                        MapPinView(
                            amount: pin.displayAmount,
                            type: pin.dominantType,
                            selected: selectedID == pin.id,
                            clusterSize: pin.clusterSize > 1 ? pin.clusterSize : nil,
                            opacity: pinOpacity(for: pin.transaction)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.6)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            // Location moved to glass bar — avoid system control under home indicator / tab bar.
            MapCompass()
            MapScaleView()
        }
    }

    @ViewBuilder
    private var transactionDetail: some View {
        if let pin = selectedPin {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pin.placeTitle)
                            .font(LiveCashTheme.headlineFont)
                        Text("\(pin.clusterSize) Besuch\(pin.clusterSize == 1 ? "" : "e") · zuletzt \(pin.placeDetail.lastVisitLabel)")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Details") { placeDetail = pin.placeDetail }
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                }

                HStack(spacing: 12) {
                    Label(String(format: "%.0f€", pin.expenseTotal), systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(LiveCashTheme.expense)
                    Label(String(format: "%.0f€", pin.incomeTotal), systemImage: "arrow.up.circle.fill")
                        .foregroundStyle(LiveCashTheme.income)
                    Spacer()
                }
                .font(LiveCashTheme.captionFont.weight(.semibold))

                if let first = pin.clusteredTransactions.first {
                    NavigationLink {
                        TransactionDetailView(transactionID: first.id)
                    } label: {
                        TransactionRow(transaction: first)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func filterChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LiveCashTheme.captionFont.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(active ? LiveCashTheme.accent : Color.primary.opacity(0.06))
                .foregroundStyle(active ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(PremiumPressStyle())
    }

    private func pinOpacity(for tx: Transaction) -> Double {
        let cal = Calendar.current
        if cal.isDate(tx.date, inSameDayAs: mapSelectedDate) { return 1 }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: tx.date), to: cal.startOfDay(for: mapSelectedDate)).day ?? 0
        return max(0.28, 1.0 - Double(days) / 21.0)
    }

    private func zoomToPin(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.55)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 900,
                longitudinalMeters: 900
            ))
        }
    }

    private func centerOnUserOrOverview() {
        setOverviewCamera(animated: true)
    }

    private func resetToOverview() {
        selectedCategory = nil
        selectedID = nil
        showFilters = false
        mapSelectedDate = Date()
        setOverviewCamera(animated: true)
    }

    /// Explicit region only — never `.automatic` (that causes unwanted zoom when pins change).
    private func setOverviewCamera(animated: Bool) {
        let coords = overviewCoordinates.isEmpty ? pinDisplays.map(\.coordinate) : overviewCoordinates
        let apply = {
            guard !coords.isEmpty else {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
                    latitudinalMeters: 450_000,
                    longitudinalMeters: 450_000
                ))
                return
            }
            if coords.count == 1 {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coords[0],
                    latitudinalMeters: 6_000,
                    longitudinalMeters: 6_000
                ))
                return
            }
            var rect = MKMapRect.null
            for c in coords {
                let point = MKMapPoint(c)
                rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
            }
            // Extra inset = lightly zoomed-out overview
            cameraPosition = .rect(rect.insetBy(dx: -rect.size.width * 0.42, dy: -rect.size.height * 0.42))
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.45), apply)
        } else {
            apply()
        }
    }
}

private struct MapPinView: View {
    let amount: Double
    let type: TransactionType
    let selected: Bool
    var clusterSize: Int?
    var opacity: Double = 1

    private var pinColor: Color {
        type == .income ? LiveCashTheme.income : LiveCashTheme.expense
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: clusterSize != nil ? "mappin.and.ellipse" : "mappin.circle.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(selected ? LiveCashTheme.accent : pinColor)
                    )
                    .overlay(Circle().strokeBorder(pinColor.opacity(0.35), lineWidth: 1))
                    .shadow(color: pinColor.opacity(0.35), radius: selected ? 10 : 4, y: 2)

                if let clusterSize, clusterSize > 1 {
                    Text("\(clusterSize)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(pinColor)
                        .clipShape(Circle())
                        .offset(x: 10, y: -6)
                }
            }
            Text(String(format: "%.0f€", amount))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(pinColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.regularMaterial, in: Capsule())
        }
        .opacity(opacity)
        .scaleEffect(selected ? 1.14 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: selected)
        .animation(.easeInOut(duration: 0.28), value: opacity)
    }
}
