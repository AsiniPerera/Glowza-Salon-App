import SwiftUI

private let brand = Color(hex: "AF1C47")

// MARK: - Sign In View
struct SignInView: View {

    var onSignIn: (() -> Void)? = nil
    var onCreateAccount: (() -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var appear = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header ──
                VStack(alignment: .leading, spacing: 8) {
                    // Logo mark
                    ZStack {
                        Circle().fill(brand.opacity(0.10)).frame(width: 56, height: 56)
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(brand)
                    }
                    .padding(.bottom, 8)

                    Text("Welcome back")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text("Sign in to your account")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                .padding(.top, 60)
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 16)

                Spacer().frame(height: 40)

                // ── Form ──
                VStack(spacing: 16) {
                    GlowzaTextField(placeholder: "Email address", text: $email,
                                    keyboardType: .emailAddress, icon: "envelope")

                    GlowzaTextField(placeholder: "Password", text: $password,
                                    isSecure: true, icon: "lock")

                    // Forgot password
                    HStack {
                        Spacer()
                        Button(action: { onForgotPassword?() }) {
                            Text("Forgot password?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(brand)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                // Error
                if let err = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(err)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(brand)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer().frame(height: 28)

                // ── Sign In button ──
                Button(action: signIn) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canSignIn ? brand : Color(hex: "BEBEBE"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: canSignIn ? brand.opacity(0.28) : .clear, radius: 12, x: 0, y: 5)
                }
                .disabled(!canSignIn || isLoading)
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)

                Spacer().frame(height: 20)

                // ── Divider ──
                HStack {
                    Rectangle().fill(Color(hex: "EBEBEB")).frame(height: 1)
                    Text("or").font(.system(size: 13)).foregroundColor(Color(hex: "ABABAB"))
                        .padding(.horizontal, 12)
                    Rectangle().fill(Color(hex: "EBEBEB")).frame(height: 1)
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 20)

                // ── Social buttons ──
                VStack(spacing: 12) {
                    socialButton(icon: "apple.logo", label: "Continue with Apple") {}
                    socialButton(icon: "g.circle.fill", label: "Continue with Google") {}
                }
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)

                Spacer().frame(height: 40)

                // ── Create account link ──
                HStack(spacing: 5) {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Button(action: { onCreateAccount?() }) {
                        Text("Create one")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(brand)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
                .opacity(appear ? 1 : 0)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) {
                appear = true
            }
        }
    }

    private var canSignIn: Bool { !email.isEmpty && !password.isEmpty }

    private func socialButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(hex: "F5F5F5"))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color(hex: "EBEBEB"), lineWidth: 1)
            )
        }
    }

    private func signIn() {
        guard canSignIn else { return }
        isLoading = true
        errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            onSignIn?()
        }
    }
}

#Preview {
    SignInView()
}
