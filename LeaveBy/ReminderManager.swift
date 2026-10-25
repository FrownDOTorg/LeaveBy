import Foundation
import Combine
import UserNotifications
import UIKit

final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

@MainActor
final class ReminderManager: ObservableObject {
    @Published private(set) var scheduledDate: Date?
    @Published private(set) var busy = false
    @Published private(set) var denied = false
    @Published private(set) var message: String?
    private static var mutationVersion = 0
    private var revision = 0
    private let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }
    private let center = UNUserNotificationCenter.current()

    func refresh() async {
        guard !busy else { return }
        let snapshot = revision
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
        guard snapshot == revision, !busy else { return }
        denied = settings.authorizationStatus == .denied
        scheduledDate = (requests.first { $0.identifier == identifier }?.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
    }

    func schedule(at date: Date, title: String) async {
        guard !busy else { return }
        Self.mutationVersion += 1
        revision += 1
        busy = true
        message = nil
        defer { busy = false }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            denied = !granted
            guard granted else {
                message = "Let's turn on notifications in Settings so we can give you a heads-up."
                return
            }
            guard date.timeIntervalSinceNow >= 5 else {
                message = "That departure is a little too soon. Pick a time at least five seconds from now, and we'll remind you."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = FriendlyCopy.reminderTitle
            content.body = FriendlyCopy.reminderBody(eventTitle: title)
            content.userInfo = ["eventTitle": title]
            content.sound = .default
            // A fixed UTC calendar keeps the reminder at the planned instant across time-zone changes.
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try await center.add(request)
            scheduledDate = trigger.nextTriggerDate()
            message = FriendlyCopy.reminderSet + " If your plans change, set a fresh reminder afterward."
        } catch {
            message = "Your reminder didn't save this time. Give it another try."
        }
    }

    func cancel(explain: Bool = true) {
        Self.mutationVersion += 1
        revision += 1
        let hadReminder = scheduledDate != nil
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        scheduledDate = nil
        if hadReminder && explain { message = "Your old reminder is cleared. When your updated plan is ready, set a fresh one." }
    }

    static func refreshNames() async {
        let center = UNUserNotificationCenter.current()
        let version = mutationVersion
        for request in await center.pendingNotificationRequests() where request.identifier.hasPrefix("leaveby.departure") {
            guard version == mutationVersion else { return }
            guard let trigger = request.trigger,
                  let content = request.content.mutableCopy() as? UNMutableNotificationContent else { continue }
            content.title = FriendlyCopy.reminderTitle
            if let title = content.userInfo["eventTitle"] as? String {
                content.body = FriendlyCopy.reminderBody(eventTitle: title)
            }
            try? await center.add(UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger))
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
