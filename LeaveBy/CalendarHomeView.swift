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
    var notes: String?
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

    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    @State private var query = ""
    @State private var filter = "Upcoming"
    @State private var reminderIDs: Set<String> = []

    private var filteredPlans: [EventPlan] {
        events.filter { event in
            let text = [event.title, SavedPlace.decode(event.originJSON)?.name ?? "",
                        SavedPlace.decode(event.destinationJSON)?.name ?? "", event.importedLocation ?? "", event.notes ?? ""].joined(separator: " ")
            return (query.isEmpty || text.localizedCaseInsensitiveContains(query))
                && (filter != "Upcoming" || event.arrival > .now)
                && (filter != "Reminders" || reminderIDs.contains(event.reminderIdentifier))
        }.sorted { $0.arrivalTimestamp < $1.arrivalTimestamp }
    }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { dashboard }
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            NavigationStack { calendar }
                .tabItem { Label("Calendar", systemImage: "calendar") }.tag(1)
            NavigationStack { plans }
                .tabItem { Label("Plans", systemImage: "list.bullet.rectangle") }.tag(2)
            NavigationStack { PlannerSettingsView { showingProfile = true } }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(3)
        }
        .leaveByColors()
        .sheet(isPresented: $showingProfile) { ProfileView().interactiveDismissDisabled() }
        .sheet(item: $selected, onDismiss: { Task { await refreshReminders() } }) { event in
            PlannerView(plan: binding(for: event)).id(event.id).interactiveDismissDisabled()
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
        .alert("Delete plan?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Delete", role: .destructive) { deleteEvent() }
            Button("Keep plan", role: .cancel) { deleting = nil }
        } message: {
            Text("This removes the plan and its departure reminder from LeaveBy. Your original calendar event stays safe.")
        }
        .task {
            syncProfile()
            EventStorage.publishWidgets(events)
            await refreshReminders()
            if !didChooseName { showingProfile = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshReminders() } }
        }
        .onChange(of: selectedTheme) { _, _ in syncProfile() }
        .onChange(of: preferredName) { _, _ in syncProfile(refreshReminders: true) }
        .onChange(of: events) { _, value in EventStorage.save(value) }
    }

    private var dashboard: some View {
        List {
            Section {
                Text(FriendlyCopy.greeting).font(.title2.bold())
                Text("A little less rushing. A little more breathing room.")
                    .foregroundStyle(LeaveByColors.muted)
            }.listRowBackground(LeaveByColors.background)
            Section {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    if let next = events.filter({ ($0.widgetDeparture ?? .distantPast) > context.date })
                        .min(by: { ($0.widgetDeparture ?? .distantFuture) < ($1.widgetDeparture ?? .distantFuture) }),
                       let departure = next.widgetDeparture {
                        Button { selected = next } label: {
                            NextDepartureCard(title: next.title, departure: departure)
                        }.buttonStyle(.plain)
                    } else {
                        PlannerEmptyState(title: "Room for your next adventure", message: "Add a plan and we'll help you work out when to head out.", symbol: "sun.horizon")
                    }
                }
                Button { day = .now; addEvent() } label: {
                    Label("Add a plan", systemImage: "plus.circle.fill").font(.headline)
                }.padding(.vertical, 6)
            }.listRowBackground(LeaveByColors.elevated)
            Section("Today at a glance") {
                LabeledContent("Plans", value: "\(events.filter { Calendar.current.isDateInToday($0.arrival) }.count)")
                LabeledContent("Scheduled reminders", value: "\(reminderIDs.count)")
            }.listRowBackground(LeaveByColors.card)
            if let badge = Achievements.badge(count: events.filter { Calendar.current.isDateInToday($0.arrival) }.count, day: .now) {
                Section { AchievementCard(badge: badge) }.listRowBackground(LeaveByColors.achievement)
            }
            Section("Coming up") {
                let upcoming = events.filter { $0.arrival > .now }.sorted { $0.arrivalTimestamp < $1.arrivalTimestamp }
                if upcoming.isEmpty { Text("Your next plans will appear here.").foregroundStyle(LeaveByColors.muted) }
                ForEach(Array(upcoming.prefix(3))) { event in planRow(event) }
            }.listRowBackground(LeaveByColors.card)
        }
        .leaveByColors().navigationTitle("LeaveBy")
    }

    private var calendar: some View {
        List {
            Section {
                DatePicker("Selected day", selection: $day, displayedComponents: .date).datePickerStyle(.graphical)
            }.listRowBackground(LeaveByColors.card)
            if let badge = Achievements.badge(count: dayEvents.count, day: day) {
                Section { AchievementCard(badge: badge) }.listRowBackground(LeaveByColors.achievement)
            }
            Section(day.formatted(date: .complete, time: .omitted)) {
                if dayEvents.isEmpty {
                    PlannerEmptyState(title: "A little breathing room", message: FriendlyCopy.emptyDay, symbol: "calendar.badge.plus")
                }
                ForEach(dayEvents) { event in planRow(event) }
                Button { addEvent() } label: { Label("Add a plan", systemImage: "plus.circle.fill") }
            }.listRowBackground(LeaveByColors.card)
        }
        .leaveByColors().navigationTitle("Calendar")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Today") { day = .now } }
            ToolbarItem(placement: .topBarTrailing) { Button("Import") { importing = true } }
        }
    }

    private var plans: some View {
        List {
            Section {
                Picker("Show plans", selection: $filter) {
                    Text("Upcoming").tag("Upcoming")
                    Text("All").tag("All")
                    Text("Reminders").tag("Reminders")
                }.pickerStyle(.menu)
            }.listRowBackground(LeaveByColors.card)
            if filteredPlans.isEmpty {
                Section { PlannerEmptyState(title: "No plans here yet", message: "Try another search or add something to look forward to.", symbol: "magnifyingglass") }
                    .listRowBackground(LeaveByColors.card)
            }
            ForEach(planDays, id: \.self) { date in
                Section(date.formatted(date: .complete, time: .omitted)) {
                    ForEach(filteredPlans.filter { Calendar.current.isDate($0.arrival, inSameDayAs: date) }) { event in planRow(event) }
                }.listRowBackground(LeaveByColors.card)
            }
        }
        .searchable(text: $query, prompt: "Search places, plans, or notes")
        .leaveByColors().navigationTitle("Plans")
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button { day = .now; addEvent() } label: { Image(systemName: "plus") }.accessibilityLabel("Add plan")
        } }
    }

    private var planDays: [Date] {
        Array(Set(filteredPlans.map { Calendar.current.startOfDay(for: $0.arrival) })).sorted()
    }

    private func planRow(_ event: EventPlan) -> some View {
        Button { selected = event } label: {
            PlanCard(plan: event, hasReminder: reminderIDs.contains(event.reminderIdentifier))
        }
        .buttonStyle(.plain)
        .swipeActions { Button("Delete", role: .destructive) { deleting = event } }
        .contextMenu { Button("Delete plan", role: .destructive) { deleting = event } }
    }

    private func refreshReminders() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        reminderIDs = Set(requests.filter { $0.identifier.hasPrefix("leaveby.departure.") }.map(\.identifier))
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
        reminderIDs.remove(event.reminderIdentifier)
        events.removeAll { $0.id == event.id }
        deleting = nil
    }
}
