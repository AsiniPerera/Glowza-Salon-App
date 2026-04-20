import SwiftUI
import LocalAuthentication

// MARK: - Glowza Splash Screen
struct SplashView: View {

    var onLogin:   (() -> Void)? = nil
    var onCreate:  (() -> Void)? = nil
    var onFaceID:  (() -> Void)? = nil   // called after successful Face ID

    @State private var logoOpacity:    CGFloat = 0
    @State private var logoOff:        CGFloat = 18
    @State private var textOpacity:    CGFloat = 0
    @State private var btnOpacity:     CGFloat = 0
    @State private var btnOff:         CGFloat = 14
    @State private var faceIDAvailable = false
    @State private var faceIDError     = false

    var body: some View {
        ZStack {
            // ── Background: warm cream ──
            LinearGradient(
                colors: [Color(hex: "FAF7F2"), Color(hex: "F0E9DF")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── Subtle decorative arch – top right ──
            Circle()
                .stroke(Color(hex: "C4A882").opacity(0.13), lineWidth: 56)
                .frame(width: 400, height: 400)
                .offset(x: 170, y: -210)

            // ── Subtle arc – bottom left ──
            Circle()
                .stroke(Color(hex: "C4A882").opacity(0.09), lineWidth: 40)
                .frame(width: 280, height: 280)
                .offset(x: -155, y: 330)

            // ── Main content ──
            VStack(spacing: 0) {
                Spacer()

                // ── G Logo ──
                ZStack {
                    // Thin outer ring
                    Circle()
                        .stroke(Color(hex: "C4A882").opacity(0.3), lineWidth: 1)
                        .frame(width: 136, height: 136)

                    // Warm inner fill
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F7F0E6"), Color(hex: "EDE0CE")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(
                            color: Color(hex: "B8956A").opacity(0.18),
                            radius: 22, x: 0, y: 8
                        )

                    // Letter G
                    Text("G")
                        .font(.system(size: 68, weight: .ultraLight, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "B8956A"), Color(hex: "7A5A3A")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .opacity(logoOpacity)
                .offset(y: logoOff)

                Spacer().frame(height: 34)

                // ── Brand name ──
                VStack(spacing: 10) {
                    Text("GLOWZA")
                        .font(.system(size: 36, weight: .ultraLight))
                        .tracking(11)
                        .foregroundColor(Color(hex: "2C2420"))

                    Rectangle()
                        .fill(Color(hex: "C4A882").opacity(0.5))
                        .frame(width: 42, height: 1)

                    Text("Premium Beauty & Wellness")
                        .font(.system(size: 13, weight: .light))
                        .tracking(1.2)
                        .foregroundColor(Color(hex: "8C7B6E"))
                }
                .opacity(textOpacity)

                Spacer().frame(height: 60)

                // ── CTA Buttons ──
                VStack(spacing: 13) {

                    // Face ID (primary — shown only when available)
                    if faceIDAvailable {
                        Button(action: authenticateWithFaceID) {
                            HStack(spacing: 12) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 20))
                                Text("Continue with Face ID")
                                    .font(.system(size: 16, weight: .medium))
                                    .tracking(0.3)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "C4A882"), Color(hex: "9A6E4A")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(
                                color: Color(hex: "B8956A").opacity(0.28),
                                radius: 14, x: 0, y: 6
                            )
                        }

                        // Divider
                        HStack(spacing: 14) {
                            Rectangle().fill(Color(hex: "D8CCBF")).frame(height: 1)
                            Text("or")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(Color(hex: "A09080"))
                            Rectangle().fill(Color(hex: "D8CCBF")).frame(height: 1)
                        }
                    }

                    // Create Account
                    Button(action: { onCreate?() }) {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .medium))
                            .tracking(0.4)
                            .foregroundColor(faceIDAvailable ? Color(hex: "7A5A3A") : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                faceIDAvailable
                                    ? AnyShapeStyle(Color.white.opacity(0.75))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color(hex: "C4A882"), Color(hex: "9A6E4A")],
                                        startPoint: .leading, endPoint: .trailing
                                      ))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        faceIDAvailable
                                            ? Color(hex: "C4A882").opacity(0.5)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: faceIDAvailable ? .clear : Color(hex: "B8956A").opacity(0.28),
                                radius: 14, x: 0, y: 6
                            )
                    }

                    // Sign In
                    Button(action: { onLogin?() }) {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .medium))
                            .tracking(0.4)
                            .foregroundColor(Color(hex: "7A5A3A"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: "C4A882").opacity(0.5), lineWidth: 1)
                            )
                    }

                    if faceIDError {
                        Text("Face ID failed. Please sign in manually.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "C0392B").opacity(0.8))
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 32)
                .opacity(btnOpacity)
                .offset(y: btnOff)

                Spacer().frame(height: 24)

                Text("Sri Lanka's Finest Clinical Beauty")
                    .font(.system(size: 11, weight: .light))
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "8C7B6E").opacity(0.55))
                    .opacity(textOpacity)
                    .padding(.bottom, 44)

                Spacer()
            }
        }
        .onAppear {
            checkFaceID()
            withAnimation(.easeOut(duration: 0.8).delay(0.25)) {
                logoOpacity = 1; logoOff = 0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.75)) {
                textOpacity = 1
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(1.05)) {
                btnOpacity = 1; btnOff = 0
            }
        }
        .animation(.spring(response: 0.3), value: faceIDAvailable)
        .animation(.spring(response: 0.3), value: faceIDError)
    }

    // MARK: - Face ID
    private func checkFaceID() {
        let ctx = LAContext()
        var err: NSError?
        faceIDAvailable = ctx.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &err
        )
    }

    private func authenticateWithFaceID() {
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Use Another Method"
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Sign in to Glowza"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    onFaceID?()
                } else {
                    withAnimation { faceIDError = true }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
