import SwiftUI

// MARK: - Change Password View
struct ChangePasswordView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    @State private var currentPassword  = ""
    @State private var newPassword      = ""
    @State private var confirmPassword  = ""
    @State private var showCurrent      = false
    @State private var showNew          = false
    @State private var showConfirm      = false
    @State private var errorMessage: String? = nil
    @State private var showSuccess      = false

    private let accent = Color(hex: "962043")
    private var dark: Color { appSettings.isDarkMode ? .white : Color(hex: "1F2126") }
    private var pageBackground: Color { appSettings.isDarkMode ? Color(hex: "0A0A0A") : .white }
    private var surfaceBackground: Color { appSettings.isDarkMode ? Color(hex: "1A1A1A") : .white }

    private var passwordsMatch: Bool   { newPassword == confirmPassword }
    private var newIsStrong: Bool      { newPassword.count >= 8 }
    private var canSubmit: Bool        { !currentPassword.isEmpty && newIsStrong && passwordsMatch }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                pageBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Info banner
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lock.shield")
                                .foregroundColor(accent)
                            Text("Use a strong password with at least 8 characters, including numbers and symbols.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "5A5D65"))
                        }
                        .padding(14)
                        .background(accent.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // Fields card
                        VStack(spacing: 0) {
                            passwordField(label: "Current Password",     text: $currentPassword, show: $showCurrent)
                            passwordField(label: "New Password",         text: $newPassword,     show: $showNew)
                            passwordField(label: "Confirm New Password", text: $confirmPassword, show: $showConfirm, isLast: true)
                        }
                        .background(surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))

                        // Strength indicators
                        VStack(alignment: .leading, spacing: 8) {
                            strengthRow(label: "At least 8 characters", met: newPassword.count >= 8)
                            strengthRow(label: "Contains a number",     met: newPassword.contains { $0.isNumber })
                            strengthRow(label: "Passwords match",       met: passwordsMatch && !newPassword.isEmpty)
                        }
                        .padding(.horizontal, 4)

                        // Error
                        if let err = errorMessage {
                            Text(err).font(.system(size: 13)).foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }

                // Bottom button
                VStack(spacing: 0) {
                    Button(action: submit) {
                        Text("Update Password")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 330, height: 55)
                            .background(canSubmit ? accent : Color(hex: "D4829E"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!canSubmit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(surfaceBackground)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(accent)
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your password has been changed successfully.")
            }
        }
    }

    private func passwordField(label: String, text: Binding<String>, show: Binding<Bool>, isLast: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A8D94"))
                    Group {
                        if show.wrappedValue {
                            TextField("", text: text)
                        } else {
                            SecureField("", text: text)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "1F2126"))
                }
                Button(action: { show.wrappedValue.toggle() }) {
                    Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "ABABAB"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            if !isLast {
                Rectangle().fill(Color(hex: "E8E8EC")).frame(height: 0.5).padding(.leading, 16)
            }
        }
    }

    private func strengthRow(label: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(met ? Color(hex: "00A878") : Color(hex: "C7C7CC"))
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(met ? Color(hex: "3A3C42") : Color(hex: "ABABAB"))
        }
    }

    private func submit() {
        guard canSubmit else { return }
        // Simulate password update (integrate with real auth as needed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showSuccess = true
        }
    }
}
