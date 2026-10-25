import SwiftUI
import UserNotifications

@main
struct LeaveByApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup { PlannerView() }
    }
}

struct PlannerView: View {
    @StateObject private var reminders = ReminderManager()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("eventTitle") private var title = "My next event"
    @AppStorage("arrivalTime") private var arrivalTimestamp = Date().addingTimeInterval(3600).timeIntervalSince1970
    @AppStorage("travelMinutes") private var travelMinutes = 20
    @AppStorage("bufferMinutes") private var bufferMinutes = 10
    @AppStorage("originPlace") private var originJSON = ""
    @AppStorage("destinationPlace") private var destinationJSON = ""
    @AppStorage("walking") private var walking = false
    @AppStorage("useMaps") private var useMaps = true
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
        "\(originJSON)|\(destinationJSON)|\(walking)|\(arrivalTimestamp)|\(bufferMinutes)"
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
                    TextField("Event name", text: $title)
                    DatePicker("Arrive by", selection: arrival)
                }
                Section("Travel") {
                    Toggle("Use Apple Maps estimate", isOn: $useMaps)
                    if useMaps {
                        Button { choosingOrigin = true } label: {
                            placeLabel("From", place: origin)
                        }
                        Button { choosingDestination = true } label: {
                            placeLabel("To", place: destination)
                        }
                        Picker("Travel mode", selection: $walking) {
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
                        Stepper("Travel: \(travelMinutes) minutes", value: $travelMinutes, in: 0...600, step: 5)
                    }
                    Stepper("Extra time: \(bufferMinutes) minutes", value: $bufferMinutes, in: 0...120, step: 5)
                }
                Section("Leave by") {
                    if let departure {
                        Text(departure, format: .dateTime.month().day().hour().minute())
                            .font(.largeTitle.bold()).foregroundStyle(.blue)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            if departure > context.date {
                                Text(departure, style: .relative) + Text(" until departure")
                            } else {
                                Text("Your planned departure time has passed.")
                            }
                        }
                    } else {
                        Text("Choose your places and calculate travel time. Recalculate after changing your trip or extra time.")
                            .foregroundStyle(.secondary)
                    }
                }
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
                    Text("Extra time brings your planned arrival earlier by that amount. No device location access is needed. Calendar access and widgets will follow.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .disabled(reminders.busy)
            .navigationTitle("LeaveBy")
            .task { await reminders.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await reminders.refresh() } }
            }
            .onChange(of: reminderInputs) { _, _ in reminders.cancel() }
            .sheet(isPresented: $choosingOrigin) {
                PlacePicker(title: "Starting point") { originJSON = $0.encoded }
            }
            .sheet(isPresented: $choosingDestination) {
                PlacePicker(title: "Destination") { destinationJSON = $0.encoded }
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
        let tripSignature = signature
        let targetArrival = Date(timeIntervalSince1970: arrivalTimestamp)
            .addingTimeInterval(-Double(bufferMinutes * 60))
        guard targetArrival > .now else {
            errorMessage = "Choose a future arrival time that also allows for your extra time."
            return
        }
        calculating = true
        defer { calculating = false }
        do {
            let seconds = try await TravelService.estimate(from: origin, to: destination,
                arriveBy: targetArrival, walking: walking)
            guard tripSignature == signature else { return }
            guard seconds.isFinite, seconds >= 0 else {
                errorMessage = "Apple Maps returned an invalid estimate. Please try again."
                return
            }
            estimate = TravelEstimate(signature: tripSignature, seconds: seconds, fetchedAt: .now)
        } catch {
            guard tripSignature == signature else { return }
            errorMessage = "Couldn’t calculate this trip. Check your connection, try more precise places, or switch to manual travel time."
        }
    }
}
