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

    private let brand = Color(hex: "962043")
    private let hotPink = Color(hex: "962043")

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Back button
                Button(action: { onBack?() }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F2F2F7"))
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Create Account")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Text("Fill in your details to get started.")
                        .font(.system(size: 17))
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
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .padding(.trailing, 18)
                        }
                    }
                    ZStack(alignment: .trailing) {
                        authInput(placeholder: "Confirm password", text: $confirmPassword, isSecure: !showConfirm, keyboard: false)
                        Button(action: { showConfirm.toggle() }) {
                            Image(systemName: showConfirm ? "eye.slash" : "eye")
                                .font(.system(size: 15))
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
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 330, height: 55)
                    .background(canCreate ? hotPink : Color(hex: "D4829E"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canCreate || isLoading)
                .frame(maxWidth: .infinity)

                Spacer().frame(height: 28)

                dividerRow
                    .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                HStack(spacing: 12) {
                    socialIcon(label: "f", labelColor: Color(hex: "1877F2"))
                    socialIcon(label: "G", labelColor: Color(hex: "DB4437"))
                    socialIcon(sfSymbol: "apple.logo", labelColor: .black)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 36)

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8E8E93"))
                    Button(action: { onSignIn?() }) {
                        Text("Sign In")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(hotPink)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white.ignoresSafeArea())
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

    private func authInput(placeholder: String, text: Binding<String>, isSecure: Bool, keyboard: Bool = false) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "1C1C1E"))
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard ? .emailAddress : .default)
                    .autocapitalization(keyboard ? .none : .words)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "1C1C1E"))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color(hex: "F2F2F7"))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }

    private var dividerRow: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color(hex: "E5E5EA")).frame(height: 1)
            Text("or continue with")
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

#Preview { CreateAccountView() }
