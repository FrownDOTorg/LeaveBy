import Foundation
import MapKit

struct SavedPlace: Codable, Equatable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    init(item: MKMapItem) {
        name = item.name ?? "Selected place"
        address = item.placemark.title ?? name
        latitude = item.placemark.coordinate.latitude
        longitude = item.placemark.coordinate.longitude
    }

    var mapItem: MKMapItem {
        let item = MKMapItem(placemark: MKPlacemark(coordinate:
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        item.name = name
        return item
    }

    var encoded: String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func decode(_ value: String) -> SavedPlace? {
        guard let data = value.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

struct TravelEstimate {
    let signature: String
    let seconds: TimeInterval
    let fetchedAt: Date
}

@MainActor
struct TravelService {
    static func estimate(from origin: SavedPlace, to destination: SavedPlace,
                         arriveBy: Date, walking: Bool) async throws -> TimeInterval {
        let request = MKDirections.Request()
        request.source = origin.mapItem
        request.destination = destination.mapItem
        request.transportType = walking ? .walking : .automobile
        request.arrivalDate = arriveBy
        let directions = MKDirections(request: request)
        let response = try await withTaskCancellationHandler {
            try await directions.calculateETA()
        } onCancel: {
            directions.cancel()
        }
        return response.expectedTravelTime
    }
}
