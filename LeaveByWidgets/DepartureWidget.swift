import SwiftUI
import WidgetKit

struct DepartureEntry: TimelineEntry {
    let date: Date
    let trip: WidgetDeparture?
}

struct DepartureProvider: TimelineProvider {
    func placeholder(in context: Context) -> DepartureEntry { sample }

    func getSnapshot(in context: Context, completion: @escaping (DepartureEntry) -> Void) {
        if context.isPreview { completion(sample) }
        else {
            let now = Date()
            completion(DepartureEntry(date: now, trip: upcoming(after: now).first))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DepartureEntry>) -> Void) {
        let now = Date()
        let trips = upcoming(after: now)
        var entries = [DepartureEntry(date: now, trip: trips.first)]
        // Move to the next saved departure when the previous one passes.
        let changes = Set(trips.map { $0.departure.addingTimeInterval(1) }).sorted().prefix(50)
        for date in changes {
            entries.append(DepartureEntry(date: date, trip: trips.first { $0.departure > date }))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(900))))
    }

    private func upcoming(after date: Date) -> [WidgetDeparture] {
        WidgetStore.load().filter { $0.departure > date }.sorted { $0.departure < $1.departure }
    }

    private var sample: DepartureEntry {
        DepartureEntry(date: .now, trip: WidgetDeparture(id: UUID(), title: "Coffee with a friend",
            departure: Date().addingTimeInterval(1200), usesMaps: true))
    }
}

struct DepartureWidgetView: View {
    let entry: DepartureEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let trip = entry.trip {
                if family == .accessoryInline {
                    HStack {
                        Image(systemName: "figure.walk")
                        Text("Leave in")
                        countdown(trip)
                    }
                } else if family == .accessoryCircular {
                    VStack(spacing: 2) {
                        Image(systemName: "figure.walk")
                        countdown(trip).font(.caption2)
                    }
                } else if family == .accessoryRectangular {
                    VStack(alignment: .leading) {
                        Text(trip.title).font(.headline).lineLimit(1)
                        HStack { Text("Leave in"); countdown(trip) }
                        Text(trip.departure, style: .time).font(.caption)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("LeaveBy", systemImage: "figure.walk").font(.caption).foregroundStyle(.secondary)
                        Text(trip.title).font(.headline).lineLimit(2)
                        Text(trip.departure, format: .dateTime.month().day().hour().minute())
                            .font(.subheadline)
                        countdown(trip).font(.title2.bold())
                        Text(trip.usesMaps ? "Saved Maps estimate" : "Manual travel time")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                if family == .accessoryInline {
                    Text("LeaveBy: no planned departure")
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "calendar")
                        Text("No planned departure").font(.headline)
                        if family == .systemSmall || family == .systemMedium {
                            Text("Open LeaveBy and calculate a trip.").font(.caption)
                        }
                    }
                }
            }
        }
        .privacySensitive()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder private func countdown(_ trip: WidgetDeparture) -> some View {
        if trip.departure > entry.date {
            Text(timerInterval: entry.date...trip.departure, countsDown: true)
                .monospacedDigit().lineLimit(1)
        } else {
            Text("Leave now")
        }
    }
}

@main
struct LeaveByDepartureWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetStore.kind, provider: DepartureProvider()) { entry in
            DepartureWidgetView(entry: entry)
        }
        .configurationDisplayName("Next departure")
        .description("A countdown to your next saved departure. Open LeaveBy to refresh travel estimates.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
