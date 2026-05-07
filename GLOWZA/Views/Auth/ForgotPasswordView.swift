import SwiftUI

// MARK: - Forgot Password Step Enum
enum ForgotPasswordStep: Int {
    case email = 1
    case verification = 2
    case resetPassword = 3
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    var onBack: (() -> Void)? = nil
    @State private var step: ForgotPasswordStep = .email
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showSuccess = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false

    private var accent: Color { appSettings.themeBrand }
    private var dark: Color { appSettings.themeText }
    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }

    private var canProceedEmail: Bool {
        !email.isEmpty && email.contains("@")
    }

    private var canProceedCode: Bool {
        !verificationCode.isEmpty && verificationCode.count == 6
    }

    private var passwordsMatch: Bool {
        newPassword == confirmPassword
    }

    private var newIsStrong: Bool {
        newPassword.count >= 8
    }

    private var canSubmitPassword: Bool {
        newIsStrong && passwordsMatch
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                pageBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(headerTitle)
                                .glowzaFont(size: 28, weight: .bold)
                                .foregroundColor(dark)
                            Text(headerSubtitle)
                                .glowzaFont(size: 15)
                                .foregroundColor(Color(hex: "8A8D94"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                        // Progress indicators
                        HStack(spacing: 12) {
                            progressCircle(1, isActive: step.rawValue >= 1)
                            progressLine(step.rawValue >= 2)
                            progressCircle(2, isActive: step.rawValue >= 2)
                            progressLine(step.rawValue >= 3)
                            progressCircle(3, isActive: step.rawValue >= 3)
                        }
                        .padding(.vertical, 8)

                        // Content based on step
                        Group {
                            switch step {
                            case .email:
                                emailStep
                            case .verification:
                                verificationStep
                            case .resetPassword:
                                resetPasswordStep
                            }
                        }

                        // Error message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .glowzaFont(size: 13)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(surfaceBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "FFE5E5"), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                // Bottom button
                VStack(spacing: 0) {
                    Button(action: handleNext) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(buttonTitle)
                                .glowzaFont(size: 15, weight: .semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(isButtonEnabled ? accent : Color(hex: "D4829E"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(!isButtonEnabled || isLoading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(surfaceBackground)

                    if step != .email {
                        Button(action: handleBack) {
                            Text("Back")
                                .glowzaFont(size: 15, weight: .semibold)
                                .foregroundColor(accent)
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if onBack != nil {
                            onBack?()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .glowzaFont(size: 17, weight: .semibold)
                            .foregroundColor(accent)
                    }
                }
            }
            .alert("Password Reset Successful", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your password has been reset successfully. Please sign in with your new password.")
            }
        }
    }

    // MARK: - Step Views

    private var emailStep: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(Color(hex: "8A8D94"))
                    TextField("Enter your email", text: $email)
                        .glowzaFont(size: 15)
                        .foregroundColor(dark)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(surfaceBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .stroke(
                                    appSettings.isHighContrast ? Color.white.opacity(0.85) : Color(hex: "E8E8EC"),
                                    lineWidth: appSettings.isHighContrast ? 3 : 1
                                )
                        )
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundColor(accent)
                    .glowzaFont(size: 14)
                Text("We'll send a verification code to this email address.")
                    .glowzaFont(size: 13)
                    .foregroundColor(Color(hex: "5A5D65"))
            }
            .padding(14)
            .background(accent.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var verificationStep: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Code")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(Color(hex: "8A8D94"))
                    TextField("000000", text: $verificationCode)
                        .glowzaFont(size: 18, weight: .semibold, design: .monospaced)
                        .foregroundColor(dark)
                        .keyboardType(.numberPad)
                        .tracking(8)
                        .frame(height: 50)
                        .padding(14)
                        .background(surfaceBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .stroke(
                                    appSettings.isHighContrast ? Color.white.opacity(0.85) : Color(hex: "E8E8EC"),
                                    lineWidth: appSettings.isHighContrast ? 3 : 1
                                )
                        )
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "envelope.open")
                    .foregroundColor(accent)
                    .glowzaFont(size: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Check your email")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(Color(hex: "5A5D65"))
                    Text("We sent a 6-digit code to \(email)")
                        .glowzaFont(size: 12)
                        .foregroundColor(Color(hex: "8A8D94"))
                }
            }
            .padding(14)
            .background(accent.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 4) {
                Text("Didn't receive the code?")
                    .glowzaFont(size: 13)
                    .foregroundColor(Color(hex: "8A8D94"))
                Button(action: { /* Resend logic */ }) {
                    Text("Resend")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var resetPasswordStep: some View {
        VStack(spacing: 16) {
            // Password strength info
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

            // Password fields
            VStack(spacing: 0) {
                passwordField(
                    label: "New Password",
                    text: $newPassword,
                    show: $showNewPassword
                )
                Rectangle()
                    .fill(Color(hex: "E8E8EC"))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
                passwordField(
                    label: "Confirm Password",
                    text: $confirmPassword,
                    show: $showConfirmPassword,
                    isLast: true
                )
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
                strengthRow(label: "Contains a number", met: newPassword.contains { $0.isNumber })
                strengthRow(label: "Passwords match", met: passwordsMatch && !newPassword.isEmpty)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Components

    private func progressCircle(_ step: Int, isActive: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isActive ? accent : Color(hex: "E8E8EC"))
                .frame(height: 32)
            Text("\(step)")
                .glowzaFont(size: 13, weight: .semibold)
                .foregroundColor(isActive ? .white : Color(hex: "C7C7CC"))
        }
    }

    private func progressLine(_ isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? accent : Color(hex: "E8E8EC"))
            .frame(height: 2)
    }

    private func passwordField(
        label: String,
        text: Binding<String>,
        show: Binding<Bool>,
        isLast: Bool = false
    ) -> some View {
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
                    .foregroundColor(dark)
                }
                Button(action: { show.wrappedValue.toggle() }) {
                    Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                        .glowzaFont(size: 16)
                        .foregroundColor(Color(hex: "ABABAB"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

    // MARK: - Computed Properties

    private var headerTitle: String {
        switch step {
        case .email:
            return "Reset Password"
        case .verification:
            return "Verify Email"
        case .resetPassword:
            return "Create New Password"
        }
    }

    private var headerSubtitle: String {
        switch step {
        case .email:
            return "Enter your email to receive a verification code"
        case .verification:
            return "Check your email for the verification code"
        case .resetPassword:
            return "Enter your new password"
        }
    }

    private var buttonTitle: String {
        switch step {
        case .email:
            return "Send Code"
        case .verification:
            return "Verify"
        case .resetPassword:
            return "Reset Password"
        }
    }

    private var isButtonEnabled: Bool {
        switch step {
        case .email:
            return canProceedEmail && !isLoading
        case .verification:
            return canProceedCode && !isLoading
        case .resetPassword:
            return canSubmitPassword && !isLoading
        }
    }

    // MARK: - Actions

    private func handleNext() {
        errorMessage = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Simulate API calls - replace with real API calls
            switch step {
            case .email:
                // Validate email exists in system
                step = .verification
            case .verification:
                // Validate verification code
                step = .resetPassword
            case .resetPassword:
                // Update password in system
                showSuccess = true
            }
            isLoading = false
        }
    }

    private func handleBack() {
        if step.rawValue > 1 {
            step = ForgotPasswordStep(rawValue: step.rawValue - 1)!
        } else {
            // At email step - go back to SignIn
            onBack?() ?? dismiss()
        }
        errorMessage = nil
    }
}

#Preview {
    ForgotPasswordView()
}
