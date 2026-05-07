import SwiftUI
import FirebaseAuth

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
    @State private var isUpdating       = false   // true while Firebase call is in progress

    private var accent: Color { appSettings.themeBrand }
    private var dark: Color { appSettings.themeText }
    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }

    private var passwordsMatch: Bool   { newPassword == confirmPassword }
    private var newIsStrong: Bool      { newPassword.count >= 8 }
    private var canSubmit: Bool        { !currentPassword.isEmpty && newIsStrong && passwordsMatch && !isUpdating }

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
                                .glowzaFont(size: 13)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .stroke(
                                    appSettings.isHighContrast ? Color.white.opacity(0.85) : Color.clear,
                                    lineWidth: appSettings.isHighContrast ? 3 : 0
                                )
                        )

                        // Strength indicators
                        VStack(alignment: .leading, spacing: 8) {
                            strengthRow(label: "At least 8 characters", met: newPassword.count >= 8)
                            strengthRow(label: "Contains a number",     met: newPassword.contains { $0.isNumber })
                            strengthRow(label: "Passwords match",       met: passwordsMatch && !newPassword.isEmpty)
                        }
                        .padding(.horizontal, 4)

                        // Error
                        if let err = errorMessage {
                            Text(err).glowzaFont(size: 13).foregroundColor(.red)
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
                        Group {
                            if isUpdating {
                                ProgressView().tint(.white)
                            } else {
                                Text("Update Password")
                                    .glowzaFont(size: 15, weight: .semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(canSubmit ? accent : Color(hex: "D4829E"))
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Cancel")
                        }
                        .glowzaFont(size: 16, weight: .medium)
                        .foregroundColor(accent)
                        .fixedSize()
                    }
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
                        .glowzaFont(size: 12)
                        .foregroundColor(Color(hex: "8A8D94"))
                    Group {
                        if show.wrappedValue {
                            TextField("", text: text)
                        } else {
                            SecureField("", text: text)
                        }
                    }
                    .glowzaFont(size: 15)
                    .foregroundColor(Color(hex: "1F2126"))
                }
                Button(action: { show.wrappedValue.toggle() }) {
                    Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                        .glowzaFont(size: 16)
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
                .glowzaFont(size: 14)
                .foregroundColor(met ? Color(hex: "00A878") : Color(hex: "C7C7CC"))
            Text(label)
                .glowzaFont(size: 13)
                .foregroundColor(met ? Color(hex: "3A3C42") : Color(hex: "ABABAB"))
        }
    }

    // MARK: - Firebase Auth Password Update
    private func submit() {
        guard canSubmit else { return }
        errorMessage = nil
        isUpdating = true

        Task {
            do {
                guard let user = Auth.auth().currentUser,
                      let email = user.email else {
                    await MainActor.run {
                        errorMessage = "Could not find your account. Please sign in again."
                        isUpdating = false
                    }
                    return
                }

                // Step 1: Re-authenticate with current password (required by Firebase)
                let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
                try await user.reauthenticate(with: credential)

                // Step 2: Update to the new password
                try await user.updatePassword(to: newPassword)

                print("✅ Password updated in Firebase Auth")

                await MainActor.run {
                    isUpdating = false
                    showSuccess = true
                }

            } catch let error as NSError {
                await MainActor.run {
                    isUpdating = false
                    // Map Firebase error codes to friendly messages
                    switch error.code {
                    case AuthErrorCode.wrongPassword.rawValue:
                        errorMessage = "Current password is incorrect."
                    case AuthErrorCode.weakPassword.rawValue:
                        errorMessage = "New password is too weak. Use at least 8 characters."
                    case AuthErrorCode.requiresRecentLogin.rawValue:
                        errorMessage = "Session expired. Please sign out and sign in again."
                    case AuthErrorCode.networkError.rawValue:
                        errorMessage = "No internet connection. Please try again."
                    default:
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}
