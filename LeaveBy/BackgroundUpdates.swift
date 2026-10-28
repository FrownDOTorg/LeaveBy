import Foundation
import BackgroundTasks
import UserNotifications

@MainActor
enum BackgroundUpdates {
    static let identifier = "com.leaveby.planner.refresh"
    static var refreshing = false
    static var editing = false
    static func register() {
        UserDefaults.standard.register(defaults: ["automaticTravelRefresh": true])
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            let work = Task { @MainActor in
                schedule()
                if !editing { EventStorage.save(CalendarSync.merge(EventStorage.load()), celebrate: false) }
                await refreshTravel()
                task.setTaskCompleted(success: !Task.isCancelled)
            }
            task.expirationHandler = { work.cancel() }
        }
    }
    static func schedule() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        guard UserDefaults.standard.bool(forKey: "automaticTravelRefresh") || !CalendarSync.selectedIDs.isEmpty else { return }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    static func refreshTravel() async {
        guard !refreshing, !editing, UserDefaults.standard.bool(forKey: "automaticTravelRefresh") else { return }
        refreshing = true
        defer { refreshing = false }
        // Only near-term trips need fresh traffic. Keep background work bounded.
        let plans = EventStorage.load().filter {
            $0.useMaps && $0.arrival > .now && $0.arrival < Date().addingTimeInterval(86400)
                && Date().timeIntervalSince1970 - ($0.mapsUpdatedAt ?? 0) > 15 * 60
        }.sorted { $0.arrival < $1.arrival }.prefix(3)
        for plan in plans {
            guard !Task.isCancelled, !editing else { break }
            guard let origin = SavedPlace.decode(plan.originJSON), let destination = SavedPlace.decode(plan.destinationJSON) else { continue }
            do {
                let seconds = try await TravelService.estimate(from: origin, to: destination, arriveBy: plan.arrival, walking: plan.walking)
                guard !Task.isCancelled, !editing, seconds.isFinite, seconds >= 0 else { continue }
                var current = EventStorage.load()
                guard let index = current.firstIndex(where: { $0.id == plan.id && $0.routeSignature == plan.routeSignature && $0.useMaps }) else { continue }
                current[index].mapsTravelSeconds = seconds
                current[index].mapsUpdatedAt = Date().timeIntervalSince1970
                current[index].mapsEstimateSignature = plan.routeSignature
                let updated = current[index]
                EventStorage.save(current, celebrate: false)
                await ReminderManager.updateExisting(updated)
            } catch { /* Keep the last successful estimate and its timestamp. */ }
        }
    }
}
