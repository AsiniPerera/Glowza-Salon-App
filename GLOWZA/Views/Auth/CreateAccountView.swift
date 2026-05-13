// This file handles the "Create Account" screen, where new users can register.
import SwiftUI

// MARK: - Create Account View
struct CreateAccountView: View {

    // Closures passed from the parent view to handle navigation.
    var onCreateAccount: (() -> Void)? = nil
    var onSignIn: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil

    // @State variables to hold the user's input data.
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // Controls for showing/hiding password text.
    @State private var showPassword = false
    @State private var showConfirm = false
    
    @State private var isLoading = false // Shows spinner while creating account.
    @State private var authError: String? = nil // Holds error messages from Firebase.

    @Environment(AppSettings.self) private var appSettings // For theme support.
    private var brand: Color { Color.glowzaPrimary }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // 1. Back Button
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .glowzaFont(size: 17, weight: .semibold)
                        .foregroundColor(Color(hex: "3A3A3C"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "F2F2F7"))
                        .clipShape(Circle())
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)


                Spacer().frame(height: 32)

                // 2. Header Texts
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create Account")
                        .glowzaFont(size: 34, weight: .bold)
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Text("Fill in your details to get started.")
                        .glowzaFont(size: 17)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 36)

                // 3. Input Fields
                VStack(spacing: 12) {
                    authInput(placeholder: "Username", text: $username, isSecure: false, keyboard: false)
                    authInput(placeholder: "Email", text: $email, isSecure: false, keyboard: true)
                    
                    // Password field with toggle.
                    ZStack(alignment: .trailing) {
                        authInput(placeholder: "Password", text: $password, isSecure: !showPassword, keyboard: false)
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .glowzaFont(size: 15)
                                .foregroundColor(Color(hex: "8E8E93"))
                                .padding(.trailing, 18)
                        }
                    }
                    
                    // Confirm Password field with toggle.
                    ZStack(alignment: .trailing) {
                        authInput(placeholder: "Confirm password", text: $confirmPassword, isSecure: !showConfirm, keyboard: false)
                        Button(action: { showConfirm.toggle() }) {
                            Image(systemName: showConfirm ? "eye.slash" : "eye")
                                .glowzaFont(size: 15)
                                .foregroundColor(Color(hex: "8E8E93"))
                                .padding(.trailing, 18)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                // 4. Create Account Button
                Button(action: createAccount) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .glowzaFont(size: 17, weight: .semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    // Button highlights only when all rules are met (see canCreate below).
                    .background(canCreate ? Color.glowzaPrimary : Color.hotPinkDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                }
                .disabled(!canCreate || isLoading)
                .padding(.horizontal, 24)

                // Error message display.
                if let err = authError {
                    Text(err)
                        .glowzaFont(size: 13)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: 28)

                // 5. Divider
                dividerRow
                    .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // 6. Social Icons (UI Only)
                HStack(spacing: 12) {
                    socialIcon(imageName: "fb", labelColor: Color(hex: "1877F2"))
                    socialIcon(imageName: "google", labelColor: Color(hex: "DB4437"))
                    socialIcon(imageName: "apple", labelColor: Color.glowzaTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)

                Spacer().frame(height: 36)

                // 7. Footer (Go to Sign In)
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .glowzaFont(size: 15)
                        .foregroundColor(Color(hex: "8E8E93"))
                    Button(action: { onSignIn?() }) {
                        Text("Sign In")
                            .glowzaFont(size: 15, weight: .semibold)
                            .foregroundColor(Color.glowzaPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
            }
        }
        .background(appSettings.themePage.ignoresSafeArea())
    }

    // MARK: - Helpers

    // A computed property that returns true only if the form is valid.
    // This is a great pattern to prevent users from submitting bad data!
    private var canCreate: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty
        && password == confirmPassword // Ensures they didn't make a typo!
    }

    // This function calls our Firebase service to register the user.
    private func createAccount() {
        guard canCreate else { return }
        isLoading = true
        authError = nil
        
        Task {
            do {
                // We call the singleton instance of AuthService.
                try await AuthService.shared.signUp(
                    fullName: username,
                    email: email,
                    phone: "", // Phone is optional in this step.
                    password: password
                )
                await MainActor.run {
                    isLoading = false
                    onCreateAccount?() // Navigate to next screen.
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Converts Firebase error codes into friendly text.
                    authError = AuthService.friendlyErrorMessage(for: error)
                }
            }
        }
    }

    // Creates a customized text field based on parameters.
    private func authInput(placeholder: String, text: Binding<String>, isSecure: Bool, keyboard: Bool = false) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .glowzaFont(size: 16)
                    .foregroundColor(appSettings.themeText)
            } else {
                TextField(placeholder, text: text)
                    // If it's an email, we show the email keyboard and disable capitalization.
                    .keyboardType(keyboard ? .emailAddress : .default)
                    .autocapitalization(keyboard ? .none : .words)
                    .glowzaFont(size: 16)
                    .foregroundColor(appSettings.themeText)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(appSettings.isHighContrast ? appSettings.themeRaised : Color(hex: "F2F2F7"))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(appSettings.themeElementBorder,
                        lineWidth: appSettings.isHighContrast ? 3 : 0)
        )
    }

    // Reusable divider view.
    private var dividerRow: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color(hex: "E5E5EA")).frame(height: 1)
            Text("or continue with")
                .glowzaFont(size: 13)
                .foregroundColor(Color(hex: "8E8E93"))
                .fixedSize()
            Rectangle().fill(Color(hex: "E5E5EA")).frame(height: 1)
        }
    }

    // Reusable social button view.
    @ViewBuilder
    private func socialIcon(imageName: String? = nil, label: String? = nil, sfSymbol: String? = nil, labelColor: Color) -> some View {
        Button(action: {}) {
            Group {
                if let img = imageName {
                    Image(img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else if let symbol = sfSymbol {
                    Image(systemName: symbol)
                        .glowzaFont(size: 20, weight: .medium)
                        .foregroundColor(labelColor)
                } else {
                    Text(label ?? "")
                        .glowzaFont(size: 20, weight: .bold)
                        .foregroundColor(labelColor)
                }
            }
            .frame(width: 52, height: 52)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color(hex: "E8E8EC"), lineWidth: 1)
            )
        }
    }
}

#Preview { CreateAccountView() }
