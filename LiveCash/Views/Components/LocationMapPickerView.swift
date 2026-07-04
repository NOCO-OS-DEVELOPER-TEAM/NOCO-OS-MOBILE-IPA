import SwiftUI
import MapKit

struct LocationMapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Binding var label: String

    @State private var position: MapCameraPosition = .automatic
    @State private var pinCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $position) {
                    if let pinCoordinate {
                        Annotation("Standort", coordinate: pinCoordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(LiveCashTheme.expense)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .onTapGesture { point in
                    if let coord = proxy.convert(point, from: .local) {
                        pinCoordinate = coord
                        latitude = coord.latitude
                        longitude = coord.longitude
                        if label.isEmpty { label = "Gewählter Ort" }
                    }
                }
            }
            .navigationTitle("Standort wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") { dismiss() }
                        .fontWeight(.semibold)
                        .disabled(pinCoordinate == nil)
                }
            }
            .onAppear {
                if let lat = latitude, let lon = longitude {
                    let c = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    pinCoordinate = c
                    position = .region(MKCoordinateRegion(center: c, latitudinalMeters: 1500, longitudinalMeters: 1500))
                } else {
                    position = .automatic
                }
            }
        }
    }
}
