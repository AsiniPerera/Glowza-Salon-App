import SwiftUI

// MARK: - Settings View
// This view provides toggles for notifications, security, and appearance.
// It uses @AppStorage for simple persistence of user preferences!
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    // @AppStorage automatically reads and writes to UserDefaults!
    @AppStorage("pushNotifications") private var pushNotifications = true
    @AppStorage("emailNotifications") private var emailNotifications = false
    @AppStorage("faceIDEnabled") private var faceIDEnabled = true

    private var brand: Color { Color.glowzaPrimary }

    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $pushNotifications)
                    Toggle("Email Notifications", isOn: $emailNotifications)
                }

                Section("Security") {
                    Toggle("Face ID Login", isOn: $faceIDEnabled)
                }

                Section("Appearance") {
                    // We use a custom binding here to proxy the state to AppSettings!
                    // This ensures the global app state updates when the user toggles dark mode.
                    Toggle("Dark Mode", isOn: Binding(
                        get: { appSettings.isDarkMode },
                        set: { appSettings.isDarkMode = $0 }
                    ))
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    // Link opens the system browser to the specified URL!
                    Link("Privacy Policy", destination: URL(string: "https://glowza.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://glowza.app/terms")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(brand)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
