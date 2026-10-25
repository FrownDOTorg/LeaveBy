import SwiftUI
import UIKit

enum LeaveByTheme {
    static let accent = Color(red: 46/255, green: 89/255, blue: 219/255)
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.systemGroupedBackground :
            UIColor(red: 245/255, green: 247/255, blue: 251/255, alpha: 1)
    })
    static let softBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.10, green: 0.16, blue: 0.28, alpha: 1) :
            UIColor(red: 232/255, green: 239/255, blue: 255/255, alpha: 1)
    })
}

struct AchievementCard: View {
    let badge: DailyAchievement
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("DAILY ACHIEVEMENT", systemImage: "sparkles")
                .font(.caption.bold()).foregroundStyle(LeaveByTheme.accent)
            Text(badge.title).font(.title3.bold())
            Text(badge.body).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
struct NextDepartureCard: View {
    let title: String
    let departure: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("YOUR NEXT DEPARTURE", systemImage: "figure.walk")
                .font(.caption.bold()).foregroundStyle(LeaveByTheme.accent)
            Text(title.isEmpty ? "Your next plan" : title).font(.title2.bold())
            Text(timerInterval: min(Date.now, departure)...departure, countsDown: true)
                .font(.largeTitle.bold()).monospacedDigit().foregroundStyle(LeaveByTheme.accent)
            Text("Leave \(departure.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
