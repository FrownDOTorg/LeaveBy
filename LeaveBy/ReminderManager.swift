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
        revision += 1
        busy = true
        message = nil
        defer { busy = false }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            denied = !granted
            guard granted else {
                message = "Notifications are off. Enable them in Settings to set a reminder."
                return
            }
            guard date.timeIntervalSinceNow >= 5 else {
                message = "Choose a departure at least five seconds in the future."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Time to leave"
            let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
            content.body = name.isEmpty ? "It’s your planned departure time." : "It’s time to leave for \(name)."
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
            message = "Reminder set. Changing the plan cancels it; set it again after your changes."
        } catch {
            message = "Couldn’t set the reminder. Please try again."
        }
    }

    func cancel(explain: Bool = true) {
        revision += 1
        let hadReminder = scheduledDate != nil
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        scheduledDate = nil
        if hadReminder && explain { message = "Reminder canceled. Set it again for your updated plan." }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
