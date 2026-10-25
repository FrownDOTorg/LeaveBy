import SwiftUI

enum LeaveByColors {
    static let themeKey = "appearanceTheme"
    private static let themes: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "themes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return result
    }()
    static var selectedID: String {
        let saved = UserDefaults.standard.string(forKey: themeKey)
            ?? UserDefaults(suiteName: WidgetStore.group)?.string(forKey: themeKey) ?? "J"
        return saved == "R" ? "R" : "J"
    }
    static func color(_ role: String, theme: String? = nil) -> Color {
        let hex = themes[theme ?? selectedID]?[role] ?? fallback[role] ?? "#F4F0FA"
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        return Color(red: Double((value >> 16) & 255)/255,
                     green: Double((value >> 8) & 255)/255,
                     blue: Double(value & 255)/255)
    }
    private static let fallback: [String: String] = [
        "name": "J theme",
        "background": "#202127",
        "card": "#2A2B34",
        "field": "#23242D",
        "elevated": "#393247",
        "accent": "#B89AE8",
        "text": "#F4F0FA",
        "muted": "#C7BED5",
        "border": "#555064",
        "positive": "#293B38",
        "achievement": "#3E334D",
        "success": "#A2DDC8",
        "danger": "#F5A9BD"
    ]
    static var background: Color { color("background") }
    static var card: Color { color("card") }
    static var field: Color { color("field") }
    static var elevated: Color { color("elevated") }
    static var accent: Color { color("accent") }
    static var text: Color { color("text") }
    static var muted: Color { color("muted") }
    static var border: Color { color("border") }
    static var positive: Color { color("positive") }
    static var achievement: Color { color("achievement") }
    static var success: Color { color("success") }
    static var danger: Color { color("danger") }
}
