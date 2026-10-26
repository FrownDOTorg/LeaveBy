import SwiftUI
import UIKit

struct PlanCard: View {
    let plan: EventPlan
    let hasReminder: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(plan.title.isEmpty ? "Untitled plan" : plan.title).font(.title3.bold())
                Spacer()
                if hasReminder { Image(systemName: "bell.fill").foregroundStyle(LeaveByColors.accent).accessibilityLabel("Reminder scheduled") }
            }
            Label(plan.arrival.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                .font(.subheadline).foregroundStyle(LeaveByColors.muted)
            if let destination = SavedPlace.decode(plan.destinationJSON) {
                Label(destination.name, systemImage: "mappin.and.ellipse").font(.subheadline)
            } else if let location = plan.importedLocation, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse").font(.subheadline)
            }
            if let departure = plan.widgetDeparture {
                Text("Leave by \(departure.formatted(date: .omitted, time: .shortened))")
                    .font(.headline).foregroundStyle(LeaveByColors.accent)
            } else {
                Text("Open your plan to calculate travel time").font(.subheadline).foregroundStyle(LeaveByColors.muted)
            }
            if let notes = plan.notes, !notes.isEmpty {
                Text(notes).font(.subheadline).foregroundStyle(LeaveByColors.muted).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct PlannerEmptyState: View {
    let title: String
    let message: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol).font(.largeTitle).foregroundStyle(LeaveByColors.accent)
            Text(title).font(.title2.bold())
            Text(message).foregroundStyle(LeaveByColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 16)
    }
}

struct PlannerSettingsView: View {
    @AppStorage(LeaveByColors.themeKey) private var theme = "J"
    @AppStorage(FriendlyCopy.nameKey) private var name = ""
    @AppStorage(Achievements.enabledKey) private var extras = true
    @Environment(\.openURL) private var openURL
    let editProfile: () -> Void
    var body: some View {
        Form {
            Section("Make yourself at home") {
                Button(action: editProfile) {
                    Label(name.isEmpty ? "Choose your name" : "Hi, \(name)", systemImage: "person.crop.circle")
                }
                Picker("Your colors", selection: $theme) {
                    Text("J · Charcoal & purple").tag("J")
                    Text("R · Navy & blue").tag("R")
                    Text("Light · Blue accents").tag("Light")
                    Text("Dark · Blue accents").tag("Dark")
                }
            }.listRowBackground(LeaveByColors.card)
            Section("Notifications") {
                Button("Open notification settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Toggle("Extra notifications", isOn: $extras)
                Text("Departure reminders are set individually inside each plan.")
                    .font(.footnote).foregroundStyle(LeaveByColors.muted)
            }.listRowBackground(LeaveByColors.card)
            Section("Your widgets") {
                Label("Your next departure, at a glance", systemImage: "rectangle.on.rectangle")
                Text("Touch and hold your Home Screen, choose Edit, then Add Widget and search for LeaveBy. You can also add a countdown when customizing your Lock Screen.")
                    .font(.subheadline).foregroundStyle(LeaveByColors.muted)
            }.listRowBackground(LeaveByColors.card)
            Section("A little about your plans") {
                Text("Your plans and name stay on this device. Calendar import makes a separate copy, so your original events stay safe.")
                Text("Apple Maps estimates update when you calculate them. Widgets and reminders use the departure time you saved.")
            }.font(.subheadline).foregroundStyle(LeaveByColors.muted).listRowBackground(LeaveByColors.card)
        }
        .leaveByColors().navigationTitle("Settings")
    }
}
