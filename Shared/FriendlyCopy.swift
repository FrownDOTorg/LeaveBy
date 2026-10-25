import Foundation

enum FriendlyCopy {
    static let nameKey = "preferredName"
    static func cleanName(_ value: String) -> String {
        String(value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ").prefix(40))
    }
    static var name: String {
        cleanName(UserDefaults.standard.string(forKey: nameKey)
            ?? UserDefaults(suiteName: WidgetStore.group)?.string(forKey: nameKey) ?? "")
    }
    static var greeting: String { name.isEmpty ? "Hi there! Let's plan your day." : "Hi, \(name)! Let's plan your day." }
    static var emptyDay: String { name.isEmpty ? "A little breathing room! Tap + to add a plan, or Import to bring one over." : "A little breathing room, \(name)! Tap + to add a plan, or Import to bring one over." }
    static var reminderTitle: String { name.isEmpty ? "Time to head out" : "\(name), it's time to head out" }
    static var reminderSet: String { name.isEmpty ? "You're all set! Your departure reminder is scheduled." : "You're all set, \(name)! Your departure reminder is scheduled." }
    static var departurePassed: String { name.isEmpty ? "Your departure time has passed. Let's check your plan." : "\(name), your departure time has passed. Let's check your plan." }
    static var widgetEmpty: String { name.isEmpty ? "Your next adventure starts here" : "What's next, \(name)?" }
    static func reminderBody(eventTitle: String) -> String {
        let title = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Your planned departure time is here. Have a good trip!" : "Time to leave for \(title). Have a good trip!"
    }
}

