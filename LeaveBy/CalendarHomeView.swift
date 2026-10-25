import SwiftUI
import UserNotifications
import WidgetKit

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
    var mapsDepartureTimestamp: Double?
    var mapsEstimateSignature: String?

    var routeSignature: String {
        "\(originJSON)|\(destinationJSON)|\(walking)|\(arrivalTimestamp)|\(bufferMinutes)"
    }
    var widgetDeparture: Date? {
        if useMaps {
            guard mapsEstimateSignature == routeSignature, let timestamp = mapsDepartureTimestamp else { return nil }
            return Date(timeIntervalSince1970: timestamp)
        }
        return arrival.addingTimeInterval(-Double((travelMinutes + bufferMinutes) * 60))
    }

    var arrival: Date { Date(timeIntervalSince1970: arrivalTimestamp) }
    var reminderIdentifier: String { "leaveby.departure.\(id.uuidString)" }
}

enum EventStorage {
    static let key = "savedEvents.v1"

    static func load() -> [EventPlan] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: key) {
            return (try? JSONDecoder().decode([EventPlan].self, from: data)) ?? []
        }
        guard defaults.object(forKey: "arrivalTime") != nil else { return [] }
        var old = EventPlan()
        old.title = defaults.string(forKey: "eventTitle") ?? "My next event"
        old.arrivalTimestamp = defaults.double(forKey: "arrivalTime")
        old.travelMinutes = defaults.object(forKey: "travelMinutes") as? Int ?? 20
        old.bufferMinutes = defaults.object(forKey: "bufferMinutes") as? Int ?? 10
        old.originJSON = defaults.string(forKey: "originPlace") ?? ""
        old.destinationJSON = defaults.string(forKey: "destinationPlace") ?? ""
        old.walking = defaults.bool(forKey: "walking")
        old.useMaps = defaults.object(forKey: "useMaps") as? Bool ?? true
        save([old])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["leaveby.departure"])
        return [old]
    }

    static func save(_ events: [EventPlan]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: key)
        publishWidgets(events)
        Achievements.evaluate(events)
    }

    static func publishWidgets(_ events: [EventPlan]) {
        let departures = events.compactMap { event -> WidgetDeparture? in
            guard let date = event.widgetDeparture else { return nil }
            return WidgetDeparture(id: event.id, title: event.title.isEmpty ? "Untitled event" : event.title,
                                   departure: date, usesMaps: event.useMaps)
        }
        WidgetStore.save(departures)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStore.kind)
    }
}

struct CalendarHomeView: View {
    @AppStorage(LeaveByColors.themeKey) private var selectedTheme = "J"
    @AppStorage(FriendlyCopy.nameKey) private var preferredName = ""
    @AppStorage("didChooseName") private var didChooseName = false
    @State private var showingProfile = false
    @State private var events = EventStorage.load()
    @State private var day = Date()
    @State private var selected: EventPlan?
    @State private var deleting: EventPlan?
    @State private var importing = false

    private var dayEvents: [EventPlan] {
        events.filter { Calendar.current.isDate($0.arrival, inSameDayAs: day) }
            .sorted { $0.arrivalTimestamp < $1.arrivalTimestamp }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(FriendlyCopy.greeting).font(.headline)
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        if let next = events.filter({ ($0.widgetDeparture ?? .distantPast) > context.date })
                            .sorted(by: { ($0.widgetDeparture ?? .distantFuture) < ($1.widgetDeparture ?? .distantFuture) }).first,
                           let departure = next.widgetDeparture {
                            NextDepartureCard(title: next.title, departure: departure)
                        }
                    }
                }.listRowBackground(LeaveByTheme.softBlue)
                Section {
                    DatePicker("Selected day", selection: $day, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                .listRowBackground(LeaveByColors.card)
                if let badge = Achievements.badge(count: dayEvents.count, day: day) {
                    Section { AchievementCard(badge: badge) }
                        .listRowBackground(LeaveByTheme.softBlue)
                }
                Section(day.formatted(date: .complete, time: .omitted)) {
                    if dayEvents.isEmpty {
                        Text(FriendlyCopy.emptyDay)
                            .foregroundStyle(LeaveByColors.muted)
                    }
                    ForEach(dayEvents) { event in
                        Button { selected = event } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(event.title.isEmpty ? "Untitled event" : event.title)
                                    .font(.headline).foregroundStyle(LeaveByColors.text)
                                Text("Arrive by \(event.arrival.formatted(date: .omitted, time: .shortened))")
                                    .foregroundStyle(LeaveByColors.muted)
                                if let destination = SavedPlace.decode(event.destinationJSON) {
                                    Text(destination.name).font(.caption).foregroundStyle(LeaveByColors.muted)
                                }
                            }
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) { deleting = event }
                        }
                    }
                }
                .listRowBackground(LeaveByColors.card)
                Section {
                    Text("Events are saved on this device in LeaveBy. Use Import to copy events from Apple Calendar. Widgets show the next saved departure.")
                        .font(.footnote).foregroundStyle(LeaveByColors.muted)
                }
                .listRowBackground(LeaveByColors.card)
            }
            .scrollContentBackground(.hidden)
            .background(LeaveByTheme.background)
            .leaveByColors()
            .navigationTitle("LeaveBy")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingProfile = true } label: { Image(systemName: "person.crop.circle") }
                        .accessibilityLabel("Your name and preferences")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") { day = .now }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import") { importing = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addEvent() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add event on selected day")
                }
            }
            .sheet(isPresented: $showingProfile) { ProfileView().interactiveDismissDisabled() }
            .sheet(item: $selected) { event in
                PlannerView(plan: binding(for: event)).id(event.id)
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $importing) {
                CalendarImportView(day: day, existingKeys: Set(events.compactMap(\.importedOccurrenceKey))) { incoming in
                    let existing = Set(events.compactMap(\.importedOccurrenceKey))
                    events.append(contentsOf: incoming.filter { event in
                        guard let key = event.importedOccurrenceKey else { return true }
                        return !existing.contains(key)
                    })
                }
            }
            .alert("Delete event?", isPresented: Binding(
                get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                Button("Delete", role: .destructive) { deleteEvent() }
                Button("Cancel", role: .cancel) { deleting = nil }
            } message: {
                Text("This removes the plan and its departure reminder from LeaveBy. Your original calendar event stays safe.")
            }
            .task {
                syncProfile()
                EventStorage.publishWidgets(events)
                if !didChooseName { showingProfile = true }
            }
            .onChange(of: selectedTheme) { _, _ in syncProfile() }
            .onChange(of: preferredName) { _, _ in syncProfile(refreshReminders: true) }
            .onChange(of: events) { _, value in EventStorage.save(value) }
        }
    }

    private func syncProfile(refreshReminders: Bool = false) {
        UserDefaults(suiteName: WidgetStore.group)?.set(selectedTheme, forKey: LeaveByColors.themeKey)
        UserDefaults(suiteName: WidgetStore.group)?.set(FriendlyCopy.cleanName(preferredName), forKey: FriendlyCopy.nameKey)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStore.kind)
        if refreshReminders { Task { await ReminderManager.refreshNames() } }
    }

    private func binding(for event: EventPlan) -> Binding<EventPlan> {
        Binding(get: { events.first { $0.id == event.id } ?? event }, set: { updated in
            guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
            events[index] = updated
        })
    }

    private func addEvent() {
        var event = EventPlan()
        event.arrivalTimestamp = (Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day).timeIntervalSince1970
        if Calendar.current.isDateInToday(day) {
            event.arrivalTimestamp = Date().addingTimeInterval(3600).timeIntervalSince1970
        }
        events.append(event)
        selected = event
    }

    private func deleteEvent() {
        guard let event = deleting else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [event.reminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [event.reminderIdentifier])
        events.removeAll { $0.id == event.id }
        deleting = nil
    }
}
