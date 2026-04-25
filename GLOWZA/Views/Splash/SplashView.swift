import SwiftUI
import LocalAuthentication

// MARK: - Glowza Splash Screen
struct SplashView: View {

    var onLogin:   (() -> Void)? = nil
    var onCreate:  (() -> Void)? = nil
    var onFaceID:  (() -> Void)? = nil

    @State private var logoScale:   CGFloat = 0.7
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var btnOpacity:  CGFloat = 0
    @State private var btnOffset:   CGFloat = 20
    @State private var faceIDAvailable = false

    private let brand = Color(hex: "AF1C47")

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Decorative soft circles
            Circle()
                .fill(Color(hex: "AF1C47").opacity(0.05))
                .frame(width: 360, height: 360)
                .offset(x: 160, y: -220)

            Circle()
                .fill(Color(hex: "AF1C47").opacity(0.04))
                .frame(width: 260, height: 260)
                .offset(x: -140, y: 340)

            VStack(spacing: 0) {
                Spacer()

                // ── Logo mark ──
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(brand.opacity(0.08))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(brand.opacity(0.12))
                        .frame(width: 116, height: 116)

                    Circle()
                        .fill(brand)
                        .frame(width: 92, height: 92)
                        .shadow(color: brand.opacity(0.35), radius: 20, x: 0, y: 8)

                    Text("G")
                        .font(.system(size: 52, weight: .light, design: .serif))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 32)

                // ── Brand text ──
                VStack(spacing: 8) {
                    Text("GLOWZA")
                        .font(.system(size: 32, weight: .bold))
                        .tracking(8)
                        .foregroundColor(Color(hex: "1A1A1A"))

                    Text("Premium Beauty & Wellness")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(1.0)
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                .opacity(textOpacity)

                Spacer()

                // ── Action buttons ──
                VStack(spacing: 12) {
                    // Face ID button (shown if biometrics available)
                    if faceIDAvailable {
                        Button(action: { onFaceID?() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Continue with Face ID")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: brand.opacity(0.30), radius: 12, x: 0, y: 6)
                        }
                    }

                    // Sign In button
                    Button(action: { onLogin?() }) {
                        Text(faceIDAvailable ? "Sign In with Password" : "Sign In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(faceIDAvailable ? brand : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(faceIDAvailable ? Color(hex: "FFF0F4") : brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(faceIDAvailable ? brand.opacity(0.2) : Color.clear, lineWidth: 1)
                            )
                            .shadow(
                                color: faceIDAvailable ? Color.clear : brand.opacity(0.30),
                                radius: 12, x: 0, y: 6
                            )
                    }

                    // Create account
                    Button(action: { onCreate?() }) {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(hex: "F5F5F5"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // Privacy note
                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 11))
                            .foregroundColor(brand.opacity(0.7))
                        Text("Your data is private & secure")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(btnOpacity)
                .offset(y: btnOffset)
            }
        }
        .onAppear {
            checkFaceID()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                logoScale = 1; logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) { textOpacity = 1 }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.55)) {
                btnOpacity = 1; btnOffset = 0
            }
        }
    }

    private func checkFaceID() {
        let ctx = LAContext()
        var err: NSError?
        faceIDAvailable = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }
}

#Preview {
    SplashView()
}
