import SwiftUI
import UserNotifications

@main
struct LeaveByApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup { CalendarHomeView().tint(LeaveByTheme.accent) }
    }
}

struct PlannerView: View {
    @StateObject private var reminders: ReminderManager
    @Environment(\.scenePhase) private var scenePhase
    @Binding var plan: EventPlan
    @Environment(\.dismiss) private var dismiss

    init(plan: Binding<EventPlan>) {
        self._plan = plan
        self._reminders = StateObject(wrappedValue: ReminderManager(identifier: plan.wrappedValue.reminderIdentifier))
    }

    private var title: String {
        get { plan.title }
        nonmutating set { plan.title = newValue }
    }
    private var arrivalTimestamp: Double {
        get { plan.arrivalTimestamp }
        nonmutating set { plan.arrivalTimestamp = newValue }
    }
    private var travelMinutes: Int {
        get { plan.travelMinutes }
        nonmutating set { plan.travelMinutes = newValue }
    }
    private var bufferMinutes: Int {
        get { plan.bufferMinutes }
        nonmutating set { plan.bufferMinutes = newValue }
    }
    private var originJSON: String {
        get { plan.originJSON }
        nonmutating set { plan.originJSON = newValue }
    }
    private var destinationJSON: String {
        get { plan.destinationJSON }
        nonmutating set { plan.destinationJSON = newValue }
    }
    private var walking: Bool {
        get { plan.walking }
        nonmutating set { plan.walking = newValue }
    }
    private var useMaps: Bool {
        get { plan.useMaps }
        nonmutating set { plan.useMaps = newValue }
    }
    @State private var choosingOrigin = false
    @State private var choosingDestination = false
    @State private var calculating = false
    @State private var estimate: TravelEstimate?
    @State private var errorMessage: String?

    private var reminderInputs: String {
        "\(signature)|\(title)|\(useMaps)|\(travelMinutes)|\(departure?.timeIntervalSince1970 ?? 0)"
    }

    private var origin: SavedPlace? { SavedPlace.decode(originJSON) }
    private var destination: SavedPlace? { SavedPlace.decode(destinationJSON) }
    private var signature: String {
        plan.routeSignature
    }
    private var validEstimate: TravelEstimate? {
        guard let estimate, estimate.signature == signature else { return nil }
        return estimate
    }
    private var arrival: Binding<Date> {
        Binding(get: { Date(timeIntervalSince1970: arrivalTimestamp) },
                set: { arrivalTimestamp = $0.timeIntervalSince1970 })
    }
    private var travelSeconds: TimeInterval? {
        useMaps ? validEstimate?.seconds : Double(travelMinutes * 60)
    }
    private var departure: Date? {
        guard let travelSeconds else { return nil }
        return Date(timeIntervalSince1970: arrivalTimestamp)
            .addingTimeInterval(-travelSeconds - Double(bufferMinutes * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your next event") {
                    TextField("Event name", text: $plan.title)
                    DatePicker("Arrive by", selection: arrival)
                    if plan.importedOccurrenceKey != nil {
                        Text("Your calendar event is copied here. Make it your own; your original stays unchanged.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let location = plan.importedLocation, destination == nil {
                        Text("Calendar location: \(location)").font(.caption)
                        Text("Tap To to find and confirm this place in Apple Maps.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Travel") {
                    Toggle("Use Apple Maps estimate", isOn: $plan.useMaps)
                    if useMaps {
                        Button { choosingOrigin = true } label: {
                            placeLabel("From", place: origin)
                        }
                        Button { choosingDestination = true } label: {
                            placeLabel("To", place: destination)
                        }
                        Picker("Travel mode", selection: $plan.walking) {
                            Text("Driving").tag(false)
                            Text("Walking").tag(true)
                        }
                        Button { Task { await calculate() } } label: {
                            if calculating { ProgressView("Calculating…") }
                            else { Text("Calculate travel time") }
                        }
                        .disabled(calculating || origin == nil || destination == nil)
                        if let validEstimate {
                            Text("Estimated travel: \(Int(ceil(validEstimate.seconds / 60))) minutes")
                            Text("Updated \(validEstimate.fetchedAt.formatted(date: .omitted, time: .shortened)). Estimates can change; recalculate before leaving.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(.red)
                        }
                    } else {
                        Stepper("Travel: \(travelMinutes) minutes", value: $plan.travelMinutes, in: 0...600, step: 5)
                    }
                    Stepper("Extra time: \(bufferMinutes) minutes", value: $plan.bufferMinutes, in: 0...120, step: 5)
                }
                Section("Leave by") {
                    if let departure {
                        Text(departure, format: .dateTime.month().day().hour().minute())
                            .font(.largeTitle.bold()).foregroundStyle(.blue)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            if departure > context.date {
                                Text(departure, style: .relative) + Text(" until departure")
                            } else {
                                Text(FriendlyCopy.departurePassed)
                            }
                        }
                    } else {
                        Text("Where are we headed? Choose your places, then calculate your travel time. Refresh it whenever your plans change.")
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(LeaveByTheme.softBlue)
                Section("Departure reminder") {
                    if let scheduled = reminders.scheduledDate {
                        Text("Scheduled for \(scheduled.formatted(date: .abbreviated, time: .shortened))")
                        Button("Cancel reminder", role: .destructive) { reminders.cancel() }
                    }
                    Button {
                        guard let departure else { return }
                        Task { await reminders.schedule(at: departure, title: title) }
                    } label: {
                        if reminders.busy { ProgressView("Setting reminder…") }
                        else { Text(reminders.scheduledDate == nil ? "Remind me when to leave" : "Update reminder") }
                    }
                    .disabled(departure == nil || calculating || reminders.busy)
                    if reminders.denied {
                        Button("Open notification settings") { reminders.openSettings() }
                    }
                    if let message = reminders.message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("Uses your saved departure time, without background traffic updates. Focus and notification settings can silence or delay alerts.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Text("Extra time brings your planned arrival earlier by that amount. No device location access is needed. Widgets show the next saved departure. Use Import in the calendar to copy existing events.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LeaveByTheme.background)
            .disabled(reminders.busy)
            .navigationTitle("Event details")
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }.disabled(reminders.busy)
            } }
            .task { await reminders.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await reminders.refresh() } }
            }
            .onChange(of: reminderInputs) { _, _ in reminders.cancel() }
            .sheet(isPresented: $choosingOrigin) {
                PlacePicker(title: "Starting point") { originJSON = $0.encoded }
            }
            .sheet(isPresented: $choosingDestination) {
                PlacePicker(title: "Destination", initialQuery: plan.importedLocation ?? "") { destinationJSON = $0.encoded }
            }
            .onChange(of: signature) { _, _ in estimate = nil; errorMessage = nil }
        }
    }

    private func placeLabel(_ label: String, place: SavedPlace?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label): \(place?.name ?? "Choose a place")")
            if let place {
                Text(place.address).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @MainActor private func calculate() async {
        guard !calculating, let origin, let destination else { return }
        errorMessage = nil
        estimate = nil
        plan.mapsDepartureTimestamp = nil
        plan.mapsEstimateSignature = nil
        let tripSignature = signature
        let targetArrival = Date(timeIntervalSince1970: arrivalTimestamp)
            .addingTimeInterval(-Double(bufferMinutes * 60))
        guard targetArrival > .now else {
            errorMessage = "Let's pick a later arrival so there's room for your extra time, too."
            return
        }
        calculating = true
        defer { calculating = false }
        do {
            let seconds = try await TravelService.estimate(from: origin, to: destination,
                arriveBy: targetArrival, walking: walking)
            guard tripSignature == signature else { return }
            guard seconds.isFinite, seconds >= 0 else {
                errorMessage = "That travel estimate doesn't look right. Let's try again."
                return
            }
            estimate = TravelEstimate(signature: tripSignature, seconds: seconds, fetchedAt: .now)
            plan.mapsDepartureTimestamp = targetArrival.addingTimeInterval(-seconds).timeIntervalSince1970
            plan.mapsEstimateSignature = tripSignature
        } catch {
            guard tripSignature == signature else { return }
            errorMessage = "We couldn't find a travel time just yet. Check your connection or try a full address. You can also enter travel time yourself."
        }
    }
}
