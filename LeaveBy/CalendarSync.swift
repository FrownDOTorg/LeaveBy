import SwiftUI
import EventKit
import UserNotifications

@MainActor
enum CalendarSync {
    static let store = EKEventStore()
    static let calendarsKey = "syncedCalendarIDs"
    static let suppressedKey = "hiddenCalendarOccurrences"
    static var selectedIDs: Set<String> { Set(UserDefaults.standard.stringArray(forKey: calendarsKey) ?? []) }
    static func sourceKey(_ event: EKEvent) -> String {
        let identifier = event.calendarItemIdentifier
        if event.hasRecurrenceRules || event.isDetached {
            return "\(identifier)|\((event.occurrenceDate ?? event.startDate).timeIntervalSince1970)"
        }
        return identifier
    }
    static func suppress(_ plan: EventPlan) {
        guard let key = plan.calendarSourceID else { return }
        var hidden = Set(UserDefaults.standard.stringArray(forKey: suppressedKey) ?? [])
        hidden.insert(key)
        UserDefaults.standard.set(Array(hidden), forKey: suppressedKey)
    }
    static func merge(_ plans: [EventPlan]) -> [EventPlan] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess, !selectedIDs.isEmpty else { return plans }
        let calendars = store.calendars(for: .event).filter { selectedIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return plans }
        let available = Set(calendars.map(\.calendarIdentifier))
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .year, value: 1, to: start)!
        // Fetch one month at a time to bound EventKit's predicate range.
        var found: [String: EKEvent] = [:]
        var cursor = start
        while cursor < end {
            let next = min(Calendar.current.date(byAdding: .month, value: 1, to: cursor)!, end)
            let predicate = store.predicateForEvents(withStart: cursor, end: next, calendars: calendars)
            for event in store.events(matching: predicate) where !event.isAllDay && event.startDate >= start && event.startDate < end {
                found[sourceKey(event)] = event
            }
            cursor = next
        }
        let hidden = Set(UserDefaults.standard.stringArray(forKey: suppressedKey) ?? [])
        var result = plans
        var seen = Set<String>()
        for (key, source) in found where !hidden.contains(key) {
            seen.insert(key)
            let legacy = "\(source.calendarItemIdentifier)|\(source.startDate.timeIntervalSince1970)"
            let index = result.firstIndex { $0.calendarSourceID == key || ($0.calendarSourceID == nil && $0.importedOccurrenceKey == legacy) }
            var plan = index.map { result[$0] } ?? EventPlan()
            let changed = plan.arrivalTimestamp != source.startDate.timeIntervalSince1970 || (plan.importedLocation ?? "") != (source.location ?? "")
            if index != nil && changed {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [plan.reminderIdentifier])
                if (plan.importedLocation ?? "") != (source.location ?? "") { plan.destinationJSON = "" }
                plan.mapsEstimateSignature = nil
            }
            plan.title = source.title ?? "Untitled event"
            plan.arrivalTimestamp = source.startDate.timeIntervalSince1970
            plan.importedLocation = source.location
            plan.importedOccurrenceKey = legacy
            plan.calendarSourceID = key
            plan.calendarID = source.calendar.calendarIdentifier
            plan.calendarOccurrence = (source.occurrenceDate ?? source.startDate).timeIntervalSince1970
            if let index { result[index] = plan } else { result.append(plan) }
        }
        result.removeAll { plan in
            guard let key = plan.calendarSourceID, let calendarID = plan.calendarID,
                  available.contains(calendarID), plan.arrival >= start, plan.arrival < end,
                  !seen.contains(key) else { return false }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [plan.reminderIdentifier])
            return true
        }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "calendarLastSynced")
        return result
    }
}

struct CalendarSyncView: View {
    let onSync: () -> Void
    @State private var calendars: [EKCalendar] = []
    @State private var selected = CalendarSync.selectedIDs
    @State private var message: String?
    @State private var loading = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Your year, together").font(.title2.bold())
                    Text("Connect calendars to load timed events for the next 12 months. New events and changes sync when you return to LeaveBy, while it is open, and when iOS allows background refresh.")
                    Text("Your notes and travel preferences stay yours. Calendar changes update the event name, time and location; changed trips may need a new estimate and reminder. All-day events are left out.")
                        .font(.footnote).foregroundStyle(LeaveByColors.muted)
                    Button("Choose Apple calendars") { Task { await load() } }.disabled(loading)
                    if loading { ProgressView() }
                    if let message { Text(message).foregroundStyle(LeaveByColors.muted) }
                    if EKEventStore.authorizationStatus(for: .event) == .denied {
                        Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                    }
                }.listRowBackground(LeaveByColors.card)
                Section("Calendars to keep connected") {
                    ForEach(calendars, id: \.calendarIdentifier) { calendar in
                        Toggle(calendar.title, isOn: Binding(get: { selected.contains(calendar.calendarIdentifier) }, set: { enabled in
                            if enabled { selected.insert(calendar.calendarIdentifier) } else { selected.remove(calendar.calendarIdentifier) }
                        }))
                    }
                }.listRowBackground(LeaveByColors.card)
                Section {
                    Text("Disconnecting keeps existing plans as copies. Deleting a connected plan hides it in LeaveBy without deleting the Apple Calendar event.")
                        .font(.footnote).foregroundStyle(LeaveByColors.muted)
                }.listRowBackground(LeaveByColors.card)
            }
            .leaveByColors().navigationTitle("Calendar sync")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & sync") {
                        UserDefaults.standard.set(Array(selected), forKey: CalendarSync.calendarsKey)
                        EventStorage.save(CalendarSync.merge(EventStorage.load()), celebrate: false)
                        BackgroundUpdates.schedule()
                        NotificationCenter.default.post(name: Notification.Name("LeaveByCalendarSync"), object: nil)
                        onSync(); dismiss()
                    }.disabled(loading || calendars.isEmpty)
                }
            }
            .task { if EKEventStore.authorizationStatus(for: .event) == .fullAccess { calendars = CalendarSync.store.calendars(for: .event) } }
        }
    }
    private func load() async {
        loading = true; message = nil
        defer { loading = false }
        do {
            if EKEventStore.authorizationStatus(for: .event) != .fullAccess {
                guard try await CalendarSync.store.requestFullAccessToEvents() else { message = "Allow Full Access in Settings to connect calendars."; return }
            }
            calendars = CalendarSync.store.calendars(for: .event)
            if calendars.isEmpty { message = "No calendars found on this iPhone." }
        } catch { message = "We couldn't load your calendars. Check access in Settings and try again." }
    }
}
