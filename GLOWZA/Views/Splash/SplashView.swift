import SwiftUI

// MARK: - Glowza Splash Screen (simplified, 3s)
struct SplashView: View {

    var onFinished: (() -> Void)? = nil

    @State private var logoScale: CGFloat = 0.75
    @State private var logoOpacity: CGFloat = 0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: CGFloat = 0
    @State private var waveScale: CGFloat = 0.95
    @State private var waveOpacity: CGFloat = 0.35

    @Environment(AppSettings.self) private var appSettings

    private let brand = Color(hex: "962043")
    private var bg: Color { appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color(hex: "FAFAFA") }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            // Ambient background glow
            Circle()
                .fill(brand.opacity(0.1))
                .frame(width: 420, height: 420)
                .offset(x: -120, y: -270)
                .blur(radius: 70)
            Circle()
                .fill(brand.opacity(0.08))
                .frame(width: 320, height: 320)
                .offset(x: 160, y: 280)
                .blur(radius: 60)

            // Centered splash content
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(brand.opacity(0.2), lineWidth: 1.2)
                        .frame(width: 170, height: 170)
                        .scaleEffect(waveScale)
                        .opacity(waveOpacity)

                    Circle()
                        .stroke(brand.opacity(0.12), lineWidth: 1)
                        .frame(width: 210, height: 210)
                        .scaleEffect(waveScale * 1.04)
                        .opacity(waveOpacity * 0.8)

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 190, height: 190)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 6) {
                    Text("GLOWZA")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(brand)
                        .tracking(5)
                    Text("Premium Salon Experience")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "9A9A9F"))
                }
                .multilineTextAlignment(.center)
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
            titleOpacity = 1
            titleOffset = 0
        }

        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            waveScale = 1.05
            waveOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                onFinished?()
            }
        }
    }
}

// MARK: - Landing Screen (Sign In / Create Account)
struct LandingView: View {

    var onLogin:  (() -> Void)? = nil
    var onCreate: (() -> Void)? = nil
    var onGuest:  (() -> Void)? = nil

    @State private var contentOpacity: CGFloat = 0
    @State private var contentOffset: CGFloat  = 30
    @Environment(AppSettings.self) private var appSettings

    private let brand = Color(hex: "962043")
    private var bg: Color { appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color(hex: "FAFAFA") }
    private var secondaryBg: Color { appSettings.isDarkMode ? Color(hex: "1A1A1A") : brand.opacity(0.08) }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            // Soft background blobs
            Circle()
                .fill(brand.opacity(0.06))
                .frame(width: 320, height: 320)
                .offset(x: -140, y: -260)
                .blur(radius: 55)
            Circle()
                .fill(brand.opacity(0.04))
                .frame(width: 220, height: 220)
                .offset(x: 160, y: 250)
                .blur(radius: 45)

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 26) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 246)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 8) {
                        Text("GLOWZA")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(brand)
                            .tracking(6)
                        Text("Your beauty, simplified.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(hex: "9A9A9F"))
                    }
                    .multilineTextAlignment(.center)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer()

                // Buttons
                VStack(spacing: 14) {
                    Button(action: { onLogin?() }) {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: { onCreate?() }) {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(brand)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(secondaryBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(brand.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Button(action: { onGuest?() }) {
                        Text("Continue as Guest")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.55) : Color(hex: "9A9A9F"))
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 56)
                .opacity(contentOpacity)
                .offset(y: contentOffset)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1; contentOffset = 0
            }
        }
    }
}

#Preview("Splash") {
    SplashView()
        .environment(AppSettings.shared)
}

#Preview("Landing") {
    LandingView()
        .environment(AppSettings.shared)
}
