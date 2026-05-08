import SwiftUI
import LocalAuthentication

// MARK: - Sign In View
struct SignInView: View {

    var onSignIn: (() -> Void)? = nil
    var onCreateAccount: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil

    @StateObject private var viewModel = AuthViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var emailAuthError: String? = nil
    @State private var showFaceIDAuth = false


    @Environment(AppSettings.self) private var appSettings
    private var brand: Color { Color.glowzaPrimary }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Back
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

                // Heading
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

                // Fields
                VStack(spacing: 14) {
                    authInput(placeholder: "Email address", text: $email, isSecure: false)
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

                // Forgot
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

                // Sign In button
                Button(action: signIn) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                                .glowzaFont(size: 17, weight: .semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 330, height: 55)
                    .background(canSignIn ? Color.glowzaPrimary : Color.hotPinkDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canSignIn || isLoading)
                .frame(maxWidth: .infinity)

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

                // Or divider
                dividerText("or")
                    .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                // Face ID button
                Button(action: { showFaceIDAuth = true }) {

                    HStack(spacing: 10) {
                        if viewModel.isAuthenticating {
                            ProgressView().tint(brand)
                        } else {
                            Image(systemName: viewModel.biometricIconName)
                                .glowzaFont(size: 22, weight: .medium)
                            Text(viewModel.biometricButtonTitle)
                                .glowzaFont(size: 16, weight: .semibold)
                        }
                    }
                    .foregroundColor(brand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(brand.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brand.opacity(0.30), lineWidth: 1)
                    )
                }
                .disabled(viewModel.isAuthenticating)
                .padding(.horizontal, 24)

                // Biometric error
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

                HStack(spacing: 12) {
                    socialIcon(label: "f", labelColor: Color(hex: "1877F2"))
                    socialIcon(label: "G", labelColor: Color(hex: "DB4437"))
                    socialIcon(sfSymbol: "apple.logo", labelColor: Color.glowzaTextPrimary)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 36)

                // Footer
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
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated { onSignIn?() }
        }
        .fullScreenCover(isPresented: $showFaceIDAuth) {
            FaceIDAuthView(onAuthSuccess: {
                showFaceIDAuth = false
                onSignIn?()
            })
        }
    }


    // MARK: - Helpers

    private var canSignIn: Bool { !email.isEmpty && !password.isEmpty }

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

    @ViewBuilder
    private func socialIcon(label: String? = nil, sfSymbol: String? = nil, labelColor: Color) -> some View {
        Button(action: {}) {
            Group {
                if let symbol = sfSymbol {
                    Image(systemName: symbol)
                        .glowzaFont(size: 20, weight: .medium)
                        .foregroundColor(labelColor)
                } else {
                    Text(label ?? "")
                        .glowzaFont(size: 20, weight: .bold)
                        .foregroundColor(labelColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(hex: "F2F2F7"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }


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
                    emailAuthError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    SignInView()
}
