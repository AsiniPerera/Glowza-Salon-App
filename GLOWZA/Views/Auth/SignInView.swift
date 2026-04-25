import SwiftUI

private let brand = Color(hex: "FF006E")

// MARK: - Sign In View
struct SignInView: View {

    var onSignIn: (() -> Void)? = nil
    var onCreateAccount: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "606269"))
                }
                .padding(.top, 24)
                .padding(.horizontal, 28)

                Spacer().frame(height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome back!")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(brand)
                    Text("Glad to see you, Again!")
                        .font(.system(size: 53, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "55575E"))
                        .lineLimit(2)
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 26)

                VStack(spacing: 16) {
                    authInput(placeholder: "Enter your email", text: $email, isSecure: false)
                    authInput(placeholder: "Enter your password", text: $password, isSecure: true)
                }
                .padding(.horizontal, 28)

                HStack {
                    Spacer()
                    Button(action: { onForgotPassword?() }) {
                        Text("Forgot Password?")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "5E6066"))
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 28)

                Spacer().frame(height: 28)

                Button(action: signIn) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Login")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(canSignIn ? brand : Color(hex: "C9CBD0"))
                    .clipShape(Capsule())
                }
                .disabled(!canSignIn || isLoading)
                .padding(.horizontal, 28)

                Spacer().frame(height: 24)

                dividerText("Or Login with")
                    .padding(.horizontal, 28)

                Spacer().frame(height: 24)

                Button(action: {}) {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 20, weight: .medium))
                        Text("Sign in with Face ID")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(brand)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 20)

                HStack(spacing: 12) {
                    socialIcon(text: "f", color: Color(hex: "1877F2"))
                    socialIcon(text: "", color: .black)
                    socialIcon(text: "G", color: Color(hex: "4285F4"))
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 56)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "5D5F66"))
                    Button(action: { onCreateAccount?() }) {
                        Text("Register Now")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(brand)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
            }
        }
        .background(Color(hex: "F1F1F1").ignoresSafeArea())
    }

    private var canSignIn: Bool { !email.isEmpty && !password.isEmpty }

    private func authInput(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack(spacing: 8) {
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "4F5158"))
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(.emailAddress)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "4F5158"))
            }

            if isSecure {
                Image(systemName: "eye")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "7D8088"))
            }
        }
        .padding(.horizontal, 22)
        .frame(height: 70)
        .background(Color(hex: "F1F1F1"))
        .overlay(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .stroke(Color(hex: "D1D3D8"), lineWidth: 1.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
    }

    private func dividerText(_ text: String) -> some View {
        HStack(spacing: 14) {
            Rectangle().fill(Color(hex: "DCDDDF")).frame(height: 1)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "64666D"))
            Rectangle().fill(Color(hex: "DCDDDF")).frame(height: 1)
        }
    }

    private func socialIcon(text: String, color: Color) -> some View {
        Button(action: {}) {
            Text(text)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .background(Color(hex: "F1F1F1"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: "DCDDE0"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func signIn() {
        guard canSignIn else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            onSignIn?()
        }
    }
}

#Preview {
    SignInView()
}
