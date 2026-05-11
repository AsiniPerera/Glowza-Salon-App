import SwiftUI

// MARK: - Create Account View
struct CreateAccountView: View {

    var onCreateAccount: (() -> Void)? = nil
    var onSignIn: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirm = false
    @State private var isLoading = false
    @State private var authError: String? = nil

    @Environment(AppSettings.self) private var appSettings
    private var brand: Color { Color.glowzaPrimary }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Back button
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

                VStack(spacing: 12) {
                    authInput(placeholder: "Username", text: $username, isSecure: false, keyboard: false)
                    authInput(placeholder: "Email", text: $email, isSecure: false, keyboard: true)
                    ZStack(alignment: .trailing) {
                        authInput(placeholder: "Password", text: $password, isSecure: !showPassword, keyboard: false)
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .glowzaFont(size: 15)
                                .foregroundColor(Color(hex: "8E8E93"))
                                .padding(.trailing, 18)
                        }
                    }
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
                    .background(canCreate ? Color.glowzaPrimary : Color.hotPinkDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canCreate || isLoading)
                .padding(.horizontal, 24)

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

                dividerRow
                    .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                HStack(spacing: 12) {
                    socialIcon(label: "f", labelColor: Color(hex: "1877F2"))
                    socialIcon(label: "G", labelColor: Color(hex: "DB4437"))
                    socialIcon(sfSymbol: "apple.logo", labelColor: Color.glowzaTextPrimary)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 36)

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

    private var canCreate: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty
        && password == confirmPassword
    }

    private func createAccount() {
        guard canCreate else { return }
        isLoading = true
        authError = nil
        Task {
            do {
                try await AuthService.shared.signUp(
                    fullName: username,
                    email: email,
                    phone: "",
                    password: password
                )
                await MainActor.run {
                    isLoading = false
                    onCreateAccount?()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func authInput(placeholder: String, text: Binding<String>, isSecure: Bool, keyboard: Bool = false) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .glowzaFont(size: 16)
                    .foregroundColor(appSettings.themeText)
            } else {
                TextField(placeholder, text: text)
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
}

#Preview { CreateAccountView() }
