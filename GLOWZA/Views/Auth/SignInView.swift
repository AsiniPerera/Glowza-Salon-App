import SwiftUI

// MARK: - Sign In View
struct SignInView: View {

    @StateObject private var viewModel = AuthViewModel()
    var onSignIn: (() -> Void)? = nil
    var onCreateAccount: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil

    @State private var showPassword = false
    @State private var showFaceIDAuth = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Back
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
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
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                        Text("Sign in to your account")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 36)
                    
                    // Error message
                    if let error = viewModel.authenticationError {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FFE5E5"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }

                    // Fields
                    VStack(spacing: 14) {
                        authInput(placeholder: "Email address", text: $viewModel.email, isSecure: false)
                        ZStack(alignment: .trailing) {
                            authInput(placeholder: "Password", text: $viewModel.password, isSecure: !showPassword)
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 15))
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
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.glowzaPrimary)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    // Sign In button
                    Button(action: {
                        Task {
                            await viewModel.signIn()
                            if viewModel.isAuthenticated {
                                onSignIn?()
                            }
                        }
                    }) {
                        Group {
                            if viewModel.isAuthenticating {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(canSignIn ? Color.glowzaPrimary : Color(hex: "D4829E"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!canSignIn || viewModel.isAuthenticating)
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: 28)

                    // Or divider
                    dividerText("or continue with")
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Face ID Button
                    NavigationLink(destination: FaceIDAuthView(onAuthSuccess: {
                        onSignIn?()
                    })) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.supportsFaceID ? "faceid" : "touchid")
                                .font(.system(size: 18, weight: .semibold))
                            Text(viewModel.supportsFaceID ? "Sign In with Face ID" : "Sign In with Biometrics")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(Color(hex: "962043"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: 20)

                    // Or divider
                    dividerText("or social")
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    // Social row
                    HStack(spacing: 12) {
                        socialIcon(label: "f", labelColor: Color(hex: "1877F2"))
                        socialIcon(sfSymbol: "apple.logo", labelColor: Color(hex: "1C1C1E"))
                        socialIcon(label: "G", labelColor: Color(hex: "DB4437"))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)

                    // Footer
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Button(action: { onCreateAccount?() }) {
                            Text("Sign Up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.glowzaPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.white.ignoresSafeArea())
        }
    }

    private var canSignIn: Bool { !viewModel.email.isEmpty && !viewModel.password.isEmpty }

    private func authInput(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "1C1C1E"))
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "1C1C1E"))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color(hex: "F2F2F7"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func dividerText(_ text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color(hex: "E5E5EA")).frame(height: 1)
            Text(text)
                .font(.system(size: 13))
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
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(labelColor)
                } else {
                    Text(label ?? "")
                        .font(.system(size: 20, weight: .bold))
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

#Preview {
    SignInView()
}
