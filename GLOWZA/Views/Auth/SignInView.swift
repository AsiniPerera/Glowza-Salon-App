import SwiftUI
import LocalAuthentication

// MARK: - Sign In View
struct SignInView: View {

    @Binding var isAuthenticated: Bool
    var onCreateAccount: (() -> Void)? = nil

    @State private var email           = ""
    @State private var password        = ""
    @State private var showPassword    = false
    @State private var isLoading       = false
    @State private var errorMsg        = ""
    @State private var showError       = false
    @State private var faceIDAvailable = false
    @State private var contentOff: CGFloat = 22
    @State private var contentAlpha: CGFloat = 0

    var body: some View {
        ZStack {
            // ── Background ──
            LinearGradient(
                colors: [Color(hex: "FAF7F2"), Color(hex: "F0E9DF")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative arc – top right
            Circle()
                .stroke(Color(hex: "C4A882").opacity(0.12), lineWidth: 52)
                .frame(width: 380, height: 380)
                .offset(x: 170, y: -210)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ──
                    VStack(spacing: 10) {
                        // G logo
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

                        Text("Welcome Back")
                            .font(.system(size: 26, weight: .light))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "2C2420"))
                            .padding(.top, 4)

                        Text("Sign in to your Glowza account")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(Color(hex: "8C7B6E"))
                    }
                    .padding(.bottom, 36)

                    VStack(spacing: 16) {

                        // ── Face ID Card ──
                        Button(action: authenticateWithFaceID) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "C4A882").opacity(0.14))
                                        .frame(width: 46, height: 46)
                                    Image(systemName: "faceid")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(hex: "8B6E4E"))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Continue with Face ID")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(hex: "2C2420"))
                                    Text("Quick & secure access")
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundColor(Color(hex: "8C7B6E"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "C4A882"))
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: "E0D4C4"), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)

                        // Or divider
                        HStack(spacing: 14) {
                            Rectangle()
                                .fill(Color(hex: "E8DDD4"))
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(Color(hex: "A09080"))
                            Rectangle()
                                .fill(Color(hex: "E8DDD4"))
                                .frame(height: 1)
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

                        // ── Sign In Button ──
                        Button(action: signIn) {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In")
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

                        // ── Create account link ──
                        HStack(spacing: 5) {
                            Text("New to Glowza?")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "8C7B6E"))
                            Button(action: { onCreateAccount?() }) {
                                Text("Create Account")
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
            checkFaceID()
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOff = 0; contentAlpha = 1
            }
        }
        .animation(.spring(response: 0.35), value: showError)
        .animation(.spring(response: 0.3), value: showError)
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

    // MARK: - Actions
    private func checkFaceID() {
        let ctx = LAContext()
        var err: NSError?
        faceIDAvailable = ctx.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &err
        )
    }

    private func authenticateWithFaceID() {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Use Email Instead"
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Sign in to Glowza"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation { isAuthenticated = true }
                } else {
                    errorMsg  = "Face ID authentication failed."
                    showError = true
                }
            }
        }
    }

    private func signIn() {
        guard !email.isEmpty    else { errorMsg = "Please enter your email.";    showError = true; return }
        guard !password.isEmpty else { errorMsg = "Please enter your password."; showError = true; return }
        showError = false
        isLoading = true
        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    withAnimation { isAuthenticated = true }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMsg  = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    SignInView(isAuthenticated: .constant(false))
}
