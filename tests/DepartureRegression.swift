import Foundation

@main
struct DepartureRegression {
    static func main() throws {
        var plan = EventPlan()
        plan.arrivalTimestamp = 100_000
        plan.useMaps = false
        plan.travelMinutes = 20
        plan.bufferMinutes = 15
        precondition(plan.widgetDeparture!.timeIntervalSince1970 == 97_900)
        plan.useMaps = true
        plan.mapsTravelSeconds = 1200
        plan.mapsEstimateSignature = plan.routeSignature
        let first = plan.widgetDeparture!
        plan.bufferMinutes += 5
        precondition(plan.widgetDeparture! == first.addingTimeInterval(-300), "Buffer edits must retain Maps travel time")
        plan.bufferMinutes -= 10
        precondition(plan.widgetDeparture! == first.addingTimeInterval(300))
        let encoded = try JSONEncoder().encode(plan)
        let restored = try JSONDecoder().decode(EventPlan.self, from: encoded)
        precondition(restored.widgetDeparture == plan.widgetDeparture, "Departure must survive reopening")
        plan.destinationJSON = "new destination"
        precondition(plan.widgetDeparture == nil, "Route changes must invalidate the estimate")
        var legacy = EventPlan()
        legacy.arrivalTimestamp = 100_000
        legacy.mapsDepartureTimestamp = 97_900
        legacy.bufferMinutes = 15
        legacy.mapsEstimateSignature = legacy.legacySignature
        legacy.migrateEstimate()
        precondition(legacy.savedTravelSeconds == 1200)
        legacy.bufferMinutes = 20
        precondition(legacy.widgetDeparture!.timeIntervalSince1970 == 97_600, "Old saved plans must support buffer edits")
        legacy.arrivalTimestamp += 3600
        precondition(legacy.widgetDeparture == nil)
        print("Departure regressions passed: manual time, buffer +/- changes, persistence, route invalidation and legacy migration.")
    }
}
