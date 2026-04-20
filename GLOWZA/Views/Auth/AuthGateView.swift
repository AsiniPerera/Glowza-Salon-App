import SwiftUI
import LocalAuthentication

// MARK: - Auth Gate View (Face ID Entry)
struct AuthGateView: View {

    @Binding var isAuthenticated: Bool
    @State private var authError: String? = nil
    @State private var isAuthenticating = false
    @State private var shakeOffset: CGFloat = 0
    @State private var contentOpacity: CGFloat = 0
    @State private var contentOffset: CGFloat = 30

    var body: some View {
        ZStack {
            // ── Background ──
            LinearGradient(
                colors: [Color(hex: "1A1A1A"), Color(hex: "2C2014"), Color(hex: "1A1A1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ──
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                            .shadow(color: Color(hex: "E5A820").opacity(0.45), radius: 20)

                        Image(systemName: "sparkles")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Text("GLOWZA")
                        .font(.system(size: 26, weight: .bold))
                        .tracking(6)
                        .foregroundColor(.white)
                }

                Spacer()

                // ── Face ID Card ──
                VStack(spacing: 28) {

                    // Face ID icon with pulse ring
                    ZStack {
                        // Pulse rings
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(Color(hex: "E5A820").opacity(0.12 - Double(i) * 0.03), lineWidth: 1)
                                .frame(width: CGFloat(90 + i * 28), height: CGFloat(90 + i * 28))
                                .scaleEffect(isAuthenticating ? 1.15 : 1.0)
                                .animation(
                                    isAuthenticating
                                        ? .easeInOut(duration: 0.8).repeatForever().delay(Double(i) * 0.2)
                                        : .default,
                                    value: isAuthenticating
                                )
                        }

                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 90, height: 90)

                        Image(systemName: isAuthenticating ? "faceid" : "faceid")
                            .font(.system(size: 44))
                            .foregroundColor(Color(hex: "E5A820"))
                            .symbolEffect(.bounce, value: isAuthenticating)
                    }
                    .offset(x: shakeOffset)

                    // Text
                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Use Face ID to securely access\nyour beauty profile")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    // Error message
                    if let error = authError {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "E5A820"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "E5A820").opacity(0.1))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }

                    // ── Face ID Button ──
                    Button(action: authenticate) {
                        HStack(spacing: 10) {
                            if isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Text(isAuthenticating ? "Authenticating..." : "Sign in with Face ID")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: isAuthenticating
                                    ? [Color.gray.opacity(0.4), Color.gray.opacity(0.3)]
                                    : [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color(hex: "E5A820").opacity(isAuthenticating ? 0 : 0.4),
                                radius: 12, x: 0, y: 6)
                    }
                    .disabled(isAuthenticating)

                    // ── Privacy Note ──
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "E5A820").opacity(0.7))
                        Text("Your data never leaves this device")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .offset(y: contentOffset)
                .opacity(contentOpacity)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) {
                contentOpacity = 1
                contentOffset = 0
            }
            // Auto-trigger Face ID on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                authenticate()
            }
        }
    }

    // MARK: - LocalAuthentication
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        authError = nil

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            withAnimation { authError = "Face ID not available on this device" }
            return
        }

        isAuthenticating = true
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Access your Glowza beauty profile"
        ) { success, evaluationError in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    withAnimation(.spring(response: 0.5)) {
                        isAuthenticated = true
                    }
                } else {
                    withAnimation {
                        authError = evaluationError?.localizedDescription ?? "Authentication failed"
                    }
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

#Preview {
    AuthGateView(isAuthenticated: .constant(false))
}
