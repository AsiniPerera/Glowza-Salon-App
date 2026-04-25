import SwiftUI
import LocalAuthentication

private let brand = Color(hex: "AF1C47")

// MARK: - Auth Gate View (Face ID)
struct AuthGateView: View {

    @Binding var isAuthenticated: Bool
    @State private var authError: String? = nil
    @State private var isAuthenticating = false
    @State private var shakeOffset: CGFloat = 0
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Subtle decorative circles
            Circle()
                .fill(brand.opacity(0.06))
                .frame(width: 400, height: 400)
                .offset(x: 180, y: -220)
            Circle()
                .fill(brand.opacity(0.04))
                .frame(width: 300, height: 300)
                .offset(x: -160, y: 340)

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ──
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(brand.opacity(0.10)).frame(width: 72, height: 72)
                        Circle().fill(brand).frame(width: 52, height: 52)
                            .shadow(color: brand.opacity(0.30), radius: 14)
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Text("GLOWZA")
                        .font(.system(size: 26, weight: .bold))
                        .tracking(6)
                        .foregroundColor(Color(hex: "1A1A1A"))
                }
                .opacity(appear ? 1 : 0)

                Spacer()

                // ── Face ID card ──
                VStack(spacing: 28) {
                    // Face ID icon
                    ZStack {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(brand.opacity(0.06 + Double(i) * 0.03), lineWidth: 1.5)
                                .frame(width: CGFloat(88 + i * 26), height: CGFloat(88 + i * 26))
                                .scaleEffect(isAuthenticating ? 1.12 : 1.0)
                                .animation(
                                    isAuthenticating
                                        ? .easeInOut(duration: 0.9).repeatForever().delay(Double(i) * 0.2)
                                        : .default,
                                    value: isAuthenticating
                                )
                        }
                        Circle()
                            .fill(brand.opacity(0.08))
                            .frame(width: 88, height: 88)
                        Image(systemName: "faceid")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(brand)
                            .symbolEffect(.bounce, value: isAuthenticating)
                    }
                    .offset(x: shakeOffset)

                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Text("Use Face ID to securely access\nyour beauty profile")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "8A8A8A"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    if let error = authError {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(brand)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(brand.opacity(0.08))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Face ID button
                    Button(action: authenticate) {
                        HStack(spacing: 10) {
                            if isAuthenticating {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            Text(isAuthenticating ? "Authenticating…" : "Sign in with Face ID")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isAuthenticating ? Color(hex: "BEBEBE") : brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: isAuthenticating ? .clear : brand.opacity(0.30), radius: 12, x: 0, y: 5)
                    }
                    .disabled(isAuthenticating)

                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 11))
                            .foregroundColor(brand.opacity(0.6))
                        Text("Your data never leaves this device")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 40)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 8)
                .padding(.horizontal, 20)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 24)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appear = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { authenticate() }
        }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        authError = nil
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            withAnimation { authError = "Face ID not available on this device" }
            return
        }
        isAuthenticating = true
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: "Access your GLOWZA beauty profile") { success, err in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    withAnimation(.spring(response: 0.5)) { isAuthenticated = true }
                } else {
                    withAnimation { authError = err?.localizedDescription ?? "Authentication failed" }
                    triggerShake()
                }
            }
        }
    }

    private func triggerShake() {
        withAnimation(.default) { shakeOffset = -10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) { shakeOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring()) { shakeOffset = 0 }
            }
        }
    }
}

#Preview { AuthGateView(isAuthenticated: .constant(false)) }
