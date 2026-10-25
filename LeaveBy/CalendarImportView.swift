import SwiftUI
import EventKit
import Combine
import UIKit

struct CalendarImportItem: Identifiable {
    let id: String
    let title: String
    let start: Date
    let location: String
    let calendarName: String

    var plan: EventPlan {
        var event = EventPlan()
        event.title = title
        event.arrivalTimestamp = start.timeIntervalSince1970
        event.importedOccurrenceKey = id
        event.importedLocation = location.isEmpty ? nil : location
        return event
    }
}

@MainActor
final class CalendarImporter: ObservableObject {
    @Published private(set) var items: [CalendarImportItem] = []
    @Published private(set) var loading = false
    @Published private(set) var message: String?
    @Published private(set) var denied = false
    private let store = EKEventStore()

    func load(day: Date) async {
        guard !loading else { return }
        loading = true
        items = []
        message = nil
        denied = false
        defer { loading = false }
        do {
            let status = EKEventStore.authorizationStatus(for: .event)
            if status == .restricted {
                message = "This iPhone doesn't allow calendar access right now. You can still create a plan yourself."
                return
            }
            if status != .fullAccess {
                let allowed = try await store.requestFullAccessToEvents()
                guard allowed else {
                    denied = true
                    message = "Let's allow Full Access for LeaveBy in Settings so you can bring your events over."
                    return
                }
            }
            guard let interval = Calendar.current.dateInterval(of: .day, for: day) else { return }
            let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
            var seen = Set<String>()
            items = store.events(matching: predicate)
                .filter { !$0.isAllDay && $0.startDate >= interval.start && $0.startDate < interval.end }
                .sorted { $0.startDate < $1.startDate }
                .compactMap { event in
                    let key = "\(event.calendarItemIdentifier)|\(event.startDate.timeIntervalSince1970)"
                    guard seen.insert(key).inserted else { return nil }
                    return CalendarImportItem(id: key, title: event.title ?? "Untitled event",
                        start: event.startDate, location: event.location ?? "",
                        calendarName: event.calendar.title)
                }
            if items.isEmpty { message = "Nothing with a start time to bring over today. Try another day, or add a plan of your own." }
        } catch {
            message = "We couldn't open your calendars just yet. Check access in Settings, then try again."
            denied = EKEventStore.authorizationStatus(for: .event) == .denied
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct CalendarImportView: View {
    let day: Date
    let existingKeys: Set<String>
    let onImport: ([EventPlan]) -> Void
    @StateObject private var importer = CalendarImporter()
    @State private var selected = Set<String>()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(day.formatted(date: .complete, time: .omitted))
                    Text("Copy selected events into LeaveBy. Copies won’t sync with later calendar changes. LeaveBy does not change your original events.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Load events from Apple Calendar") {
                        selected = []
                        Task { await importer.load(day: day) }
                    }
                    .disabled(importer.loading)
                    if importer.loading { ProgressView("Loading calendars…") }
                    if let message = importer.message { Text(message).font(.footnote) }
                    if importer.denied {
                        Button("Open Settings") { importer.openSettings() }
                    }
                } footer: {
                    Text("iOS requires Full Access to read existing calendar events. Only timed events starting on this day are listed; add all-day plans manually with an arrival time.")
                }
                ForEach(importer.items) { item in
                    let imported = existingKeys.contains(item.id)
                    Button {
                        if selected.contains(item.id) { selected.remove(item.id) }
                        else { selected.insert(item.id) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).foregroundStyle(.primary)
                                Text("\(item.start.formatted(date: .omitted, time: .shortened)) · \(item.calendarName)")
                                    .font(.caption).foregroundStyle(.secondary)
                                if !item.location.isEmpty {
                                    Text(item.location).font(.caption).foregroundStyle(.secondary)
                                }
                                if imported { Text("Already in your plans").font(.caption) }
                            }
                            Spacer()
                            Image(systemName: imported || selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                    .disabled(imported)
                    .accessibilityAddTraits(selected.contains(item.id) ? .isSelected : [])
                }
            }
            .navigationTitle("Import events")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import (\(selected.count))") {
                        let plans = importer.items.filter { selected.contains($0.id) && !existingKeys.contains($0.id) }.map(\.plan)
                        onImport(plans)
                        dismiss()
                    }
                    .disabled(selected.isEmpty || importer.loading)
                }
            }
        }
    }
}
