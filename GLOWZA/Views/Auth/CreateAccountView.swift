import SwiftUI

private let brand = Color(hex: "AF1C47")

// MARK: - Create Account View
struct CreateAccountView: View {

    var onCreateAccount: (() -> Void)? = nil
    var onSignIn: (() -> Void)? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    @State private var isLoading = false
    @State private var appear = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header ──
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        Circle().fill(brand.opacity(0.10)).frame(width: 56, height: 56)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(brand)
                    }
                    .padding(.bottom, 8)

                    Text("Create Account")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text("Join GLOWZA and discover beauty")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                .padding(.top, 60)
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)

                Spacer().frame(height: 36)

                // ── Form ──
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        GlowzaTextField(placeholder: "First name", text: $firstName)
                        GlowzaTextField(placeholder: "Last name", text: $lastName)
                    }

                    GlowzaTextField(placeholder: "Email address", text: $email,
                                    keyboardType: .emailAddress, icon: "envelope")

                    GlowzaTextField(placeholder: "Phone number", text: $phone,
                                    keyboardType: .phonePad, icon: "phone")

                    GlowzaTextField(placeholder: "Password", text: $password,
                                    isSecure: true, icon: "lock")

                    GlowzaTextField(placeholder: "Confirm password", text: $confirmPassword,
                                    isSecure: true, icon: "lock.rotation")

                    // Password strength
                    if !password.isEmpty {
                        passwordStrengthBar
                    }

                    // Terms
                    Button(action: { agreeToTerms.toggle() }) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(agreeToTerms ? brand : Color(hex: "DCDCDC"), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                if agreeToTerms {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(brand)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            Group {
                                Text("I agree to the ").foregroundColor(Color(hex: "6B6B6B"))
                                + Text("Terms of Service").foregroundColor(brand)
                                + Text(" and ").foregroundColor(Color(hex: "6B6B6B"))
                                + Text("Privacy Policy").foregroundColor(brand)
                            }
                            .font(.system(size: 13))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)

                // Error
                if let err = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(err)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(brand)
                    .padding(.horizontal, 28)
                    .padding(.top, 10)
                    .transition(.opacity)
                }

                Spacer().frame(height: 28)

                // ── Create button ──
                Button(action: createAccount) {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canCreate ? brand : Color(hex: "BEBEBE"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: canCreate ? brand.opacity(0.28) : .clear, radius: 12, x: 0, y: 5)
                }
                .disabled(!canCreate || isLoading)
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)

                Spacer().frame(height: 32)

                // ── Sign in link ──
                HStack(spacing: 5) {
                    Text("Already have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Button(action: { onSignIn?() }) {
                        Text("Sign in")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(brand)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 48)
                .opacity(appear ? 1 : 0)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) { appear = true }
        }
    }

    // MARK: - Password Strength
    private var passwordStrength: Int {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*")) != nil { score += 1 }
        return score
    }

    private var strengthLabel: String {
        switch passwordStrength {
        case 0, 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        default: return "Strong"
        }
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 0, 1: return brand
        case 2: return Color(hex: "F59E0B")
        case 3: return Color(hex: "3B82F6")
        default: return Color(hex: "00A878")
        }
    }

    @ViewBuilder
    private var passwordStrengthBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < passwordStrength ? strengthColor : Color(hex: "EBEBEB"))
                        .frame(height: 4)
                }
            }
            Text("Password strength: \(strengthLabel)")
                .font(.system(size: 12))
                .foregroundColor(strengthColor)
        }
    }

    private var canCreate: Bool {
        !firstName.isEmpty && !email.isEmpty && !password.isEmpty
        && password == confirmPassword && agreeToTerms && password.count >= 6
    }

    private func createAccount() {
        guard canCreate else { return }
        if password != confirmPassword {
            errorMessage = "Passwords don't match"
            return
        }
        isLoading = true; errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            onCreateAccount?()
        }
    }
}

#Preview { CreateAccountView() }
