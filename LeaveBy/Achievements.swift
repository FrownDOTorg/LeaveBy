import Foundation
import UserNotifications

struct AchievementCatalog: Decodable {
    struct Tier: Decodable {
        let count: Int
        let titles: [String]
        let messages: [String]
    }
    let tiers: [Tier]
}
struct DailyAchievement {
    let title: String
    let body: String
    let milestone: Int
}

enum Achievements {
    static let enabledKey = "achievementNotifications"
    static var enabled: Bool { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
    static let tiers: [AchievementCatalog.Tier] = {
        guard let url = Bundle.main.url(forResource: "achievements", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(AchievementCatalog.self, from: data) else { return [] }
        return catalog.tiers.sorted { $0.count < $1.count }
    }()
    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
    static func badge(count: Int, day: Date) -> DailyAchievement? {
        guard let tier = tiers.last(where: { count >= $0.count }),
              !tier.titles.isEmpty, !tier.messages.isEmpty else { return nil }
        let key = "achievement.variant.\(dayKey(day)).\(tier.count)"
        let defaults = UserDefaults.standard
        let choice: Int
        if defaults.object(forKey: key) == nil {
            choice = Int.random(in: 0..<max(tier.titles.count, tier.messages.count))
            defaults.set(choice, forKey: key)
        } else { choice = defaults.integer(forKey: key) }
        let dayText = Calendar.current.isDateInToday(day) ? "today" : "on \(day.formatted(date: .abbreviated, time: .omitted))"
        let body = tier.messages[choice % tier.messages.count]
            .replacingOccurrences(of: "{namePrefix}", with: FriendlyCopy.name.isEmpty ? "" : "\(FriendlyCopy.name), ")
            .replacingOccurrences(of: "{count}", with: String(count))
            .replacingOccurrences(of: "{day}", with: dayText)
        return DailyAchievement(title: tier.titles[choice % tier.titles.count], body: body, milestone: tier.count)
    }
    static func evaluate(_ events: [EventPlan]) {
        let groups = Dictionary(grouping: events, by: { dayKey($0.arrival) })
        for (key, plans) in groups {
            guard let day = plans.first?.arrival,
                  let badge = badge(count: plans.count, day: day) else { continue }
            let seenKey = "achievement.highest.\(key)"
            guard badge.milestone > UserDefaults.standard.integer(forKey: seenKey) else { continue }
            // Record before the async permission check: edits/reloads cannot replay a milestone.
            UserDefaults.standard.set(badge.milestone, forKey: seenKey)
            guard enabled, day >= Calendar.current.startOfDay(for: .now) else { continue }
            Task {
                let center = UNUserNotificationCenter.current()
                let settings = await center.notificationSettings()
                guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
                let content = UNMutableNotificationContent()
                content.title = badge.title
                content.body = badge.body
                content.sound = .default
                let request = UNNotificationRequest(identifier: "leaveby.achievement.\(key)",
                    content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
                try? await center.add(request)
            }
        }
    }
}

