import SwiftUI
import UIKit

enum LeaveByTheme {
    static var accent: Color { LeaveByColors.accent }
    static var background: Color { LeaveByColors.background }
    static var softBlue: Color { LeaveByColors.elevated }
}
private struct LeaveByAppearance: ViewModifier {
    @AppStorage(LeaveByColors.themeKey) private var selectedTheme = "J"
    func body(content: Content) -> some View {
        content.scrollContentBackground(.hidden)
            .background(LeaveByColors.color("background", theme: selectedTheme))
            .foregroundStyle(LeaveByColors.color("text", theme: selectedTheme))
            .tint(LeaveByColors.color("accent", theme: selectedTheme))
            .preferredColorScheme(selectedTheme == "Light" ? .light : .dark)
            .dynamicTypeSize(.xLarge ... .accessibility5)
    }
}
extension View {
    func leaveByColors() -> some View { modifier(LeaveByAppearance()) }
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
