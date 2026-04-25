import SwiftUI

private let brand = Color(hex: "FF006E")

// MARK: - Create Account View
struct CreateAccountView: View {

    var onCreateAccount: (() -> Void)? = nil
    var onSignIn: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
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
                    Text("Hello!")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(brand)
                    Text("Register to get started")
                        .font(.system(size: 53, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "55575E"))
                        .lineLimit(2)
                }
                .padding(.horizontal, 28)
                Spacer().frame(height: 26)

                VStack(spacing: 16) {
                    authInput(placeholder: "Username", text: $username, isSecure: false)
                    authInput(placeholder: "Email", text: $email, isSecure: false)
                    authInput(placeholder: "Password", text: $password, isSecure: true)
                    authInput(placeholder: "Confirm password", text: $confirmPassword, isSecure: true)
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 28)

                Button(action: createAccount) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Register")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(canCreate ? brand : Color(hex: "C9CBD0"))
                    .clipShape(Capsule())
                }
                .disabled(!canCreate || isLoading)
                .padding(.horizontal, 28)

                Spacer().frame(height: 24)

                dividerText("Or Register with")
                    .padding(.horizontal, 28)

                Spacer().frame(height: 24)

                HStack(spacing: 12) {
                    socialIcon(text: "f", color: Color(hex: "1877F2"))
                    socialIcon(text: "G", color: Color(hex: "4285F4"))
                    socialIcon(text: "", color: .black)
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 56)

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "5D5F66"))
                    Button(action: { onSignIn?() }) {
                        Text("Login Now")
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

    private var canCreate: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty
        && password == confirmPassword
    }

    private func createAccount() {
        guard canCreate else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            onCreateAccount?()
        }
    }

    private func authInput(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack(spacing: 8) {
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "4F5158"))
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(placeholder == "Email" ? .emailAddress : .default)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "4F5158"))
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
}

#Preview { CreateAccountView() }
