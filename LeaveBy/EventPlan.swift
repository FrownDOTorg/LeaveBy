import Foundation

struct EventPlan: Codable, Identifiable, Equatable {
    var id = UUID()
    var title = "New event"
    var arrivalTimestamp = Date().addingTimeInterval(3600).timeIntervalSince1970
    var travelMinutes = 20
    var bufferMinutes = 10
    var originJSON = ""
    var destinationJSON = ""
    var walking = false
    var useMaps = true
    var importedOccurrenceKey: String?
    var importedLocation: String?
    var notes: String?
    var mapsDepartureTimestamp: Double?
    var mapsEstimateSignature: String?

    var mapsTravelSeconds: Double?
    var mapsUpdatedAt: Double?
    var calendarSourceID: String?
    var calendarOccurrence: Double?
    var calendarID: String?
    var routeSignature: String {
        "\(originJSON)|\(destinationJSON)|\(walking)|\(arrivalTimestamp)"
    }
    var legacySignature: String { "\(routeSignature)|\(bufferMinutes)" }
    var savedTravelSeconds: Double? {
        guard mapsEstimateSignature == routeSignature || mapsEstimateSignature == legacySignature else { return nil }
        if let seconds = mapsTravelSeconds { return seconds }
        guard let timestamp = mapsDepartureTimestamp else { return nil }
        return max(0, arrivalTimestamp - Double(bufferMinutes * 60) - timestamp)
    }
    var widgetDeparture: Date? {
        let seconds: Double
        if useMaps {
            guard let saved = savedTravelSeconds else { return nil }
            seconds = saved
        } else { seconds = Double(travelMinutes * 60) }
        return arrival.addingTimeInterval(-seconds - Double(bufferMinutes * 60))
    }
    mutating func migrateEstimate() {
        if let seconds = savedTravelSeconds {
            mapsTravelSeconds = seconds
            mapsEstimateSignature = routeSignature
        }
    }
    var arrival: Date { Date(timeIntervalSince1970: arrivalTimestamp) }
    var reminderIdentifier: String { "leaveby.departure.\(id.uuidString)" }
}
