import SwiftUI


struct CreateAccountView: View {

    @Binding var isAuthenticated: Bool
    var onSignIn: (() -> Void)? = nil

    @State private var fullName     = ""
    @State private var email        = ""
    @State private var phone        = ""
    @State private var password     = ""
    @State private var confirmPwd   = ""
    @State private var showPassword = false
    @State private var showConfirm  = false
    @State private var isLoading    = false
    @State private var errorMsg     = ""
    @State private var showError    = false
    @State private var agreeTerms   = false
    @State private var contentOff:   CGFloat = 22
    @State private var contentAlpha: CGFloat =  0

    var body: some View {
        ZStack {
            // ── Background ──
            LinearGradient(
                colors: [Color(hex: "FAF7F2"), Color(hex: "F0E9DF")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative arc – top left (mirrored from SignIn)
            Circle()
                .stroke(Color(hex: "C4A882").opacity(0.12), lineWidth: 52)
                .frame(width: 380, height: 380)
                .offset(x: -170, y: -210)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ──
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .stroke(Color(hex: "C4A882").opacity(0.28), lineWidth: 1)
                                .frame(width: 90, height: 90)
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F7F0E6"), Color(hex: "EDE0CE")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 76, height: 76)
                                .shadow(color: Color(hex: "B8956A").opacity(0.15), radius: 14, x: 0, y: 5)
                            Text("G")
                                .font(.system(size: 40, weight: .ultraLight, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "B8956A"), Color(hex: "7A5A3A")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        }
                        .padding(.top, 60)

                        Text("Create Account")
                            .font(.system(size: 26, weight: .light))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "2C2420"))
                            .padding(.top, 4)

                        Text("Join Glowza — look your absolute best")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(Color(hex: "8C7B6E"))
                    }
                    .padding(.bottom, 36)

                    VStack(spacing: 16) {

                        // ── Name field ──
                        salonField(icon: "person") {
                            TextField("Full Name", text: $fullName)
                                .autocapitalization(.words)
                                .autocorrectionDisabled()
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "2C2420"))
                        }

                        // ── Email field ──
                        salonField(icon: "envelope") {
                            TextField("Email Address", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "2C2420"))
                        }

                        // ── Phone field ──
                        salonField(icon: "phone") {
                            TextField("Phone Number", text: $phone)
                                .keyboardType(.phonePad)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "2C2420"))
                        }

                        // ── Divider ──
                        HStack(spacing: 14) {
                            Rectangle()
                                .fill(Color(hex: "E8DDD4"))
                                .frame(height: 1)
                            Text("security")
                                .font(.system(size: 11, weight: .light))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "A09080"))
                            Rectangle()
                                .fill(Color(hex: "E8DDD4"))
                                .frame(height: 1)
                        }

                        // ── Password field ──
                        salonField(icon: "lock") {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "2C2420"))
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "B8956A").opacity(0.6))
                            }
                        }

                        // ── Confirm Password field ──
                        salonField(icon: "lock.badge.checkmark") {
                            Group {
                                if showConfirm {
                                    TextField("Confirm Password", text: $confirmPwd)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Confirm Password", text: $confirmPwd)
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "2C2420"))
                            Button(action: { showConfirm.toggle() }) {
                                Image(systemName: showConfirm ? "eye.slash" : "eye")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "B8956A").opacity(0.6))
                            }
                        }

                        // ── Password strength ──
                        if !password.isEmpty {
                            strengthIndicator(for: password)
                        }

                        // ── Terms checkbox ──
                        Button(action: { agreeTerms.toggle() }) {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(agreeTerms ? Color(hex: "C4A882") : Color.white)
                                        .frame(width: 22, height: 22)
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            agreeTerms ? Color(hex: "C4A882") : Color(hex: "D8CCBC"),
                                            lineWidth: 1.5
                                        )
                                        .frame(width: 22, height: 22)
                                    if agreeTerms {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .animation(.spring(response: 0.25), value: agreeTerms)

                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundColor(Color(hex: "8C7B6E"))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(.plain)

                        // ── Error ──
                        if showError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 13))
                                Text(errorMsg)
                                    .font(.system(size: 13, weight: .light))
                                Spacer()
                            }
                            .foregroundColor(Color(hex: "C0392B"))
                            .padding(.horizontal, 2)
                            .transition(.opacity)
                        }

                        // ── Create Account Button ──
                        Button(action: handleCreate) {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 16, weight: .medium))
                                        .tracking(0.4)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "C4A882"), Color(hex: "9A6E4A")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color(hex: "B8956A").opacity(0.28), radius: 12, x: 0, y: 5)
                        }
                        .disabled(isLoading)

                        // ── Sign in link ──
                        HStack(spacing: 5) {
                            Text("Already have an account?")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "8C7B6E"))
                            Button(action: { onSignIn?() }) {
                                Text("Sign In")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "8B6E4E"))
                                    .underline()
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 48)
                    }
                    .padding(.horizontal, 28)
                }
            }
            .offset(y: contentOff)
            .opacity(contentAlpha)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOff = 0; contentAlpha = 1
            }
        }
        .animation(.spring(response: 0.35), value: showError)
        .animation(.spring(response: 0.3), value: password)
    }

    // MARK: - Field builder
    @ViewBuilder
    private func salonField<Content: View>(
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "B8956A").opacity(0.65))
                .frame(width: 20)
            content()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "E0D4C4"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    // MARK: - Strength indicator
    @ViewBuilder
    private func strengthIndicator(for pwd: String) -> some View {
        let info = strengthInfo(pwd)
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i < info.bars ? info.color : Color(hex: "E8DDD4"))
                        .frame(height: 4)
                }
            }
            Text(info.label)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(info.color)
        }
        .padding(.horizontal, 4)
    }

    private func strengthInfo(_ p: String) -> (bars: Int, color: Color, label: String) {
        let hasUpper  = p.range(of: "[A-Z]",        options: .regularExpression) != nil
        let hasDigit  = p.range(of: "[0-9]",        options: .regularExpression) != nil
        let hasSymbol = p.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil
        let score     = (p.count >= 8 ? 1 : 0) + (hasUpper ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSymbol ? 1 : 0)
        switch score {
        case 0, 1: return (1, Color(hex: "C0392B"), "Weak")
        case 2:    return (2, Color(hex: "B8956A"), "Fair")
        case 3:    return (3, Color(hex: "7A9A6A"), "Good")
        default:   return (4, Color(hex: "4A8A6A"), "Strong")
        }
    }

    
    private func handleCreate() {
        guard !fullName.isEmpty     else { fail("Please enter your full name.");              return }
        guard !email.isEmpty        else { fail("Please enter your email address.");          return }
        guard !password.isEmpty     else { fail("Please enter a password.");                  return }
        guard password == confirmPwd else { fail("Passwords do not match.");                 return }
        guard password.count >= 6   else { fail("Password must be at least 6 characters."); return }
        guard agreeTerms            else { fail("Please agree to the Terms of Service.");    return }

        showError = false
        isLoading = true
        Task {
            do {
                try await AuthService.shared.signUp(
                    fullName: fullName,
                    email:    email,
                    phone:    phone,
                    password: password
                )
                await MainActor.run {
                    isLoading = false
                    withAnimation { isAuthenticated = true }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    fail(error.localizedDescription)
                }
            }
        }
    }

    private func fail(_ msg: String) {
        errorMsg  = msg
        showError = true
    }
}

#Preview {
    CreateAccountView(isAuthenticated: .constant(false))
}
