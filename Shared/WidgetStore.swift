import Foundation

struct WidgetDeparture: Codable, Identifiable {
    let id: UUID
    let title: String
    let departure: Date
    let usesMaps: Bool
}

enum WidgetStore {
    // Register this same group for both targets before a signed device build.
    static let group = "group.com.frowndotorg.leaveby"
    static let kind = "LeaveByDeparture"
    private static let key = "widgetDepartures.v1"

    static func save(_ departures: [WidgetDeparture]) {
        guard let data = try? JSONEncoder().encode(departures) else { return }
        UserDefaults(suiteName: group)?.set(data, forKey: key)
    }

    static func load() -> [WidgetDeparture] {
        guard let data = UserDefaults(suiteName: group)?.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([WidgetDeparture].self, from: data)) ?? []
    }
}
