import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
final class CurrentPlace: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var busy = false
    @Published var message: String?
    @Published var place: SavedPlace?
    private let manager = CLLocationManager()
    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyHundredMeters }
    func request() {
        guard !busy else { return }
        busy = true; message = nil
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        default: busy = false; message = "Allow location access for LeaveBy in Settings, or search for a place instead."
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard busy else { return }
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways { manager.requestLocation() }
        else if manager.authorizationStatus != .notDetermined { busy = false; message = "You can still search for your starting point." }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        busy = false
        guard let location = locations.last, location.horizontalAccuracy >= 0, abs(location.timestamp.timeIntervalSinceNow) < 120 else {
            message = "We couldn't get a fresh location. Please try again."; return
        }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        item.name = "My Location (saved point)"
        place = SavedPlace(item: item)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        busy = false; message = "Location isn't available just now. Try again or search for an address."
    }
}

enum FavoritePlaces {
    static let key = "favoritePlaces.v1"
    static let names = ["Home", "Work", "Gym"]
    static func load() -> [String: SavedPlace] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: SavedPlace].self, from: data)) ?? [:]
    }
    static func save(_ places: [String: SavedPlace]) {
        if let data = try? JSONEncoder().encode(places) { UserDefaults.standard.set(data, forKey: key) }
    }
}

struct FavoritePlacesView: View {
    @State private var places = FavoritePlaces.load()
    @State private var editing: String?
    var body: some View {
        List {
            Section {
                ForEach(FavoritePlaces.names, id: \.self) { name in
                    Button { editing = name } label: {
                        VStack(alignment: .leading) {
                            Text(name).font(.headline)
                            Text(places[name]?.address ?? "Choose a place").font(.subheadline).foregroundStyle(LeaveByColors.muted)
                        }
                    }.swipeActions { Button("Remove", role: .destructive) { places.removeValue(forKey: name); FavoritePlaces.save(places) } }
                }
            } footer: { Text("Saved on this device. My Location captures a starting point when tapped; it does not track you in the background.") }
            .listRowBackground(LeaveByColors.card)
        }
        .leaveByColors().navigationTitle("Saved places")
        .sheet(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
            PlacePicker(title: "Save \(editing ?? "place")", showsShortcuts: false) { place in
                if let name = editing { places[name] = place; FavoritePlaces.save(places) }
                editing = nil
            }
        }
    }
}
