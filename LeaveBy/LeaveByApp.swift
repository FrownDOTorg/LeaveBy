import SwiftUI

@main
struct LeaveByApp: App {
    var body: some Scene {
        WindowGroup { PlannerView() }
    }
}

struct PlannerView: View {
    @AppStorage("eventTitle") private var title = "My next event"
    @AppStorage("arrivalTime") private var arrivalTimestamp = Date().addingTimeInterval(3600).timeIntervalSince1970
    @AppStorage("travelMinutes") private var travelMinutes = 20
    @AppStorage("bufferMinutes") private var bufferMinutes = 10

    private var arrival: Binding<Date> {
        Binding(get: { Date(timeIntervalSince1970: arrivalTimestamp) },
                set: { arrivalTimestamp = $0.timeIntervalSince1970 })
    }

    private var departure: Date {
        Date(timeIntervalSince1970: arrivalTimestamp)
            .addingTimeInterval(-Double(travelMinutes + bufferMinutes) * 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your next event") {
                    TextField("Event name", text: $title)
                    DatePicker("Arrive by", selection: arrival)
                }
                Section("Plan your departure") {
                    Stepper("Travel: \(travelMinutes) minutes", value: $travelMinutes, in: 0...600, step: 5)
                    Stepper("Extra time: \(bufferMinutes) minutes", value: $bufferMinutes, in: 0...120, step: 5)
                }
                Section("Leave by") {
                    Text(departure, format: .dateTime.weekday().hour().minute())
                        .font(.largeTitle.bold())
                        .foregroundStyle(.blue)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        if departure > context.date {
                            Text(departure, style: .relative) + Text(" until departure")
                        } else {
                            Text("Your planned departure time has passed.")
                        }
                    }
                }
                Section {
                    Text("Enter travel time manually for this first version. Apple Maps estimates, calendar integration, reminders, and widgets will follow in later setup steps.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("LeaveBy")
        }
    }
}
