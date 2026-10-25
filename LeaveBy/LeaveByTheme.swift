import SwiftUI
import UIKit

enum LeaveByTheme {
    static let accent = LeaveByColors.accent
    static let background = LeaveByColors.background
    static let softBlue = LeaveByColors.elevated
}
extension View {
    func leaveByColors() -> some View {
        self.scrollContentBackground(.hidden)
            .background(LeaveByColors.background)
            .foregroundStyle(LeaveByColors.text)
            .tint(LeaveByColors.accent)
            .preferredColorScheme(.dark)
    }
}

struct AchievementCard: View {
    let badge: DailyAchievement
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("DAILY ACHIEVEMENT", systemImage: "sparkles")
                .font(.caption.bold()).foregroundStyle(LeaveByTheme.accent)
            Text(badge.title).font(.title3.bold())
            Text(badge.body).font(.subheadline).foregroundStyle(LeaveByColors.muted)
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
                .font(.subheadline).foregroundStyle(LeaveByColors.muted)
        }
        .padding(.vertical, 8)
    }
}
