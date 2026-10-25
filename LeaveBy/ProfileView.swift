import SwiftUI

struct ProfileView: View {
    @AppStorage(LeaveByColors.themeKey) private var selectedTheme = "J"
    @AppStorage(FriendlyCopy.nameKey) private var savedName = ""
    @AppStorage(Achievements.enabledKey) private var achievementNotifications = true
    @AppStorage("didChooseName") private var didChooseName = false
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("What would you like us to call you?").font(.title2.bold())
                    Text("A first name or nickname is perfect. We'll use it in your greetings and departure reminders.")
                    TextField("Your name or nickname", text: $draft)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onChange(of: draft) { _, value in
                            if value.count > 40 { draft = String(value.prefix(40)) }
                        }
                } footer: {
                    Text("Your name stays on this device and is shared with LeaveBy's widgets. You can change or remove it anytime here. It may appear in notification previews.")
                }
                .listRowBackground(LeaveByColors.card)
                Section("Your colors") {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("R theme · Navy & blue").tag("R")
                        Text("J theme · Charcoal & purple").tag("J")
                    }
                    Text("Pick the colors that feel like you. Your plans stay just as they are.")
                        .font(.footnote).foregroundStyle(LeaveByColors.muted)
                }
                .listRowBackground(LeaveByColors.card)
                Section("A little celebration") {
                    Toggle("Playful achievement notifications", isOn: $achievementNotifications)
                    Text("Unlock a random badge at 5, 8, 12, 20, and 30 plans in a day. Uses notification permission you've already allowed; your departure reminders stay separate.")
                        .font(.footnote).foregroundStyle(LeaveByColors.muted)
                }
                .listRowBackground(LeaveByColors.card)
                Section {
                    Button("Save my preference") { save(draft) }
                    Button(savedName.isEmpty ? "Maybe later" : "Use LeaveBy without a name") { save("") }
                }
                .listRowBackground(LeaveByColors.card)
            }
            .leaveByColors()
            .navigationTitle("Make yourself at home")
            .onAppear { draft = savedName }
        }
    }
    private func save(_ value: String) {
        savedName = FriendlyCopy.cleanName(value)
        didChooseName = true
        dismiss()
    }
}
