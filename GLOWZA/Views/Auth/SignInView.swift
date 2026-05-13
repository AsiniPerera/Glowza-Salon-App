// This file handles the "Sign In" screen, allowing users to log in with Email or Face ID.
import SwiftUI
import LocalAuthentication // Needed for Face ID / Touch ID biometrics.

// MARK: - Sign In View
struct SignInView: View {

    // These closures (functions) are passed in from the parent view to handle navigation.
    var onSignIn: (() -> Void)? = nil
    var onCreateAccount: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil

    // We use a separate ViewModel to handle the complex Face ID logic.
    @StateObject private var viewModel = AuthViewModel()

    // @State variables hold the text as the user types.
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false // Controls whether to show dots or real letters.
    @State private var isLoading = false // Shows a spinner while logging in.
    @State private var emailAuthError: String? = nil // Holds error messages from Firebase.
    @State private var showFaceIDAuth = false // Triggers the Face ID sheet.


    @Environment(AppSettings.self) private var appSettings // For dark mode support.
    private var brand: Color { Color.glowzaPrimary } // Quick access to app's main color.

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
                .padding(.top, 20)
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                // 2. Welcome Headers
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back")
                        .glowzaFont(size: 34, weight: .bold)
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Text("Sign in to your account")
                        .glowzaFont(size: 17, weight: .regular)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 36)

                // 3. Input Fields (Email & Password)
                VStack(spacing: 14) {
                    authInput(placeholder: "Email address", text: $email, isSecure: false)
                    
                    // Password field has an "eye" icon to toggle visibility.
                    ZStack(alignment: .trailing) {
                        authInput(placeholder: "Password", text: $password, isSecure: !showPassword)
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .glowzaFont(size: 15)
                                .foregroundColor(Color(hex: "8E8E93"))
                                .padding(.trailing, 18)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // 4. Forgot Password Button
                HStack {
                    Spacer()
                    Button(action: { onForgotPassword?() }) {
                        Text("Forgot Password?")
                            .glowzaFont(size: 14, weight: .medium)
                            .foregroundColor(brand)
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                // 5. Sign In Button
                Button(action: signIn) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white) // Loading spinner.
                        } else {
                            Text("Sign In")
                                .glowzaFont(size: 17, weight: .semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    // Button changes color and disables if fields are empty.
                    .background(canSignIn ? Color.glowzaPrimary : Color.hotPinkDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canSignIn || isLoading)
                .padding(.horizontal, 24)

                // Shows error if login fails.
                if let err = emailAuthError {
                    Text(err)
                        .glowzaFont(size: 13)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: 16)

                // 6. "OR" Divider
                dividerText("or")
                    .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                // 7. Face ID / Biometric Login Button
                Button(action: { showFaceIDAuth = true }) {
                    HStack(spacing: 10) {
                        if viewModel.isAuthenticating {
                            ProgressView().tint(brand)
                        } else {
                            Image(systemName: viewModel.biometricIconName)
                                .glowzaFont(size: 22, weight: .medium)
                            Text(email.isEmpty ? "Enter Email to use Face ID" : viewModel.biometricButtonTitle)
                                .glowzaFont(size: 16, weight: .semibold)
                        }
                    }
                    .foregroundColor(email.isEmpty ? Color(hex: "8E8E93") : brand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(email.isEmpty ? Color(hex: "F2F2F7") : Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(email.isEmpty ? Color(hex: "E5E5EA") : brand, lineWidth: 1)
                    )
                }
                .disabled(viewModel.isAuthenticating || email.isEmpty)
                .padding(.horizontal, 24)

                // Biometric error message if Face ID fails.
                if let err = viewModel.authenticationError {
                    Text(err)
                        .glowzaFont(size: 13)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: 20)

                // 8. Social Login Icons (UI only for demonstration).
                HStack(spacing: 12) {
                    socialIcon(imageName: "fb", labelColor: Color(hex: "1877F2"))
                    socialIcon(imageName: "google", labelColor: Color(hex: "DB4437"))
                    socialIcon(imageName: "apple", labelColor: Color.glowzaTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)

                Spacer().frame(height: 36)

                // 9. Footer (Sign Up link).
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .glowzaFont(size: 14)
                        .foregroundColor(Color(hex: "8E8E93"))
                    Button(action: { onCreateAccount?() }) {
                        Text("Sign Up")
                            .glowzaFont(size: 14, weight: .semibold)
                            .foregroundColor(Color.glowzaPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
            }
        }
        .background(appSettings.themePage.ignoresSafeArea())
        // Listeners for success states.
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated { onSignIn?() }
        }
        // Shows the Face ID scan view as a full screen cover.
        .fullScreenCover(isPresented: $showFaceIDAuth) {
            FaceIDAuthView(onAuthSuccess: {
                showFaceIDAuth = false
                // Call simulated Face ID sign in matching the entered email!
                Task {
                    do {
                        try await AuthService.shared.signInWithFaceID(email: email)
                        await MainActor.run {
                            onSignIn?()
                        }
                    } catch {
                        await MainActor.run {
                            emailAuthError = error.localizedDescription
                        }
                    }
                }
            }, onCancel: {
                showFaceIDAuth = false
            })
        }
    }


    // MARK: - Helpers
    // These functions clean up the main body code by extracting repeated UI elements.

    // Checks if the user has typed anything before allowing them to click Sign In.
    private var canSignIn: Bool { !email.isEmpty && !password.isEmpty }

    // Creates a custom styled text field or secure field.
    private func authInput(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .glowzaFont(size: 16)
                    .foregroundColor(appSettings.themeText)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
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

    // Creates the horizontal line with text in the middle (e.g. "--- or ---").
    private func dividerText(_ text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color(hex: "E5E5EA")).frame(height: 1)
            Text(text)
                .glowzaFont(size: 13)
                .foregroundColor(Color(hex: "8E8E93"))
                .fixedSize()
            Rectangle().fill(Color(hex: "E5E5EA")).frame(height: 1)
        }
    }

    // Creates circular buttons for Facebook, Google, and Apple login.
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


    // Calls Firebase to verify the email and password.
    private func signIn() {
        guard canSignIn else { return }
        isLoading = true
        emailAuthError = nil
        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    onSignIn?()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    emailAuthError = AuthService.friendlyErrorMessage(for: error)
                }
            }
        }
    }
}

#Preview {
    SignInView()
}
