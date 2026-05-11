import SwiftUI

// MARK: - Splash helpers

private struct RippleRing: View {
    let ringSize: CGFloat
    let color: Color
    let scale: CGFloat
    let opacity: CGFloat

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 1.2)
            .frame(width: ringSize, height: ringSize)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

private struct SParticle: Identifiable {
    let id: Int; let x, y, size, drift: CGFloat; let isGold: Bool
}

private struct ParticleField: View {
    let brand: Color; let pink: Color
    @State private var drifting = false

    private let pts: [SParticle] = [
        .init(id:  0, x: -140, y: -320, size: 3, drift: -14, isGold: false),
        .init(id:  1, x:   80, y: -350, size: 2, drift: -10, isGold: true ),
        .init(id:  2, x: -170, y: -180, size: 4, drift: -16, isGold: false),
        .init(id:  3, x:  160, y: -200, size: 3, drift: -12, isGold: true ),
        .init(id:  4, x:  -90, y:  -80, size: 5, drift: -18, isGold: false),
        .init(id:  5, x:  170, y:   20, size: 2, drift:  -9, isGold: true ),
        .init(id:  6, x: -160, y:  100, size: 3, drift: -15, isGold: false),
        .init(id:  7, x:  130, y:  160, size: 4, drift: -11, isGold: true ),
        .init(id:  8, x:  -50, y:  220, size: 2, drift: -13, isGold: false),
        .init(id:  9, x:  150, y:  280, size: 3, drift: -16, isGold: true ),
        .init(id: 10, x: -120, y:  340, size: 5, drift: -10, isGold: false),
        .init(id: 11, x:   60, y:  380, size: 2, drift: -14, isGold: true ),
        .init(id: 12, x: -180, y:   50, size: 3, drift: -12, isGold: false),
        .init(id: 13, x:   20, y: -250, size: 4, drift: -17, isGold: true ),
        .init(id: 14, x:  -30, y:  120, size: 2, drift:  -9, isGold: false),
        .init(id: 15, x:  110, y: -120, size: 3, drift: -15, isGold: true ),
        .init(id: 16, x: -100, y: -280, size: 4, drift: -11, isGold: false),
        .init(id: 17, x:  170, y:  -60, size: 2, drift: -13, isGold: true ),
        .init(id: 18, x:  -60, y:  300, size: 5, drift: -16, isGold: false),
        .init(id: 19, x:   90, y:  220, size: 3, drift: -10, isGold: true )
    ]

    var body: some View {
        ZStack {
            ForEach(pts) { p in
                Circle()
                    .fill(p.isGold ? pink.opacity(0.65) : brand.opacity(0.28))
                    .frame(width: p.size, height: p.size)
                    .blur(radius: p.size * 0.4)
                    .offset(x: p.x, y: p.y + (drifting ? p.drift : 0))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                drifting = true
            }
        }
    }
}

// MARK: - Glowza Splash Screen

struct SplashView: View {

    var onFinished: (() -> Void)? = nil

    @State private var logoScale:       CGFloat = 0.3
    @State private var logoOpacity:     CGFloat = 0
    @State private var particleOpacity: CGFloat = 0
    @State private var titleOpacity:    CGFloat = 0
    @State private var titleOffset:     CGFloat = 24
    @State private var subtitleOpacity: CGFloat = 0
    @State private var shimmerX:        CGFloat = -240
    @State private var r1Scale:  CGFloat = 0.25; @State private var r1Opacity: CGFloat = 0.85
    @State private var r2Scale:  CGFloat = 0.25; @State private var r2Opacity: CGFloat = 0.78
    @State private var r3Scale:  CGFloat = 0.25; @State private var r3Opacity: CGFloat = 0.68

    private let brand = Color(hex: "962043")
    private let pink  = Color(hex: "F4A0BB")

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()


            // ── Logo + brand text ─────────────────────────────────────────
            VStack(spacing: 28) {
                ZStack {

                    // Logo + shimmer scan (clipped together)
                    ZStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .opacity(logoOpacity)

                        LinearGradient(
                            colors: [.clear, .white.opacity(0.55), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 60, height: 200)
                        .offset(x: shimmerX)
                        .blendMode(.overlay)
                        .opacity(logoOpacity)
                    }
                    .frame(width: 200, height: 200)

                    .clipped()
                    .scaleEffect(logoScale)
                }

                // Removed brand name and tagline per user request
            }
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        // Ripple rings expand outward and fade to 0
        withAnimation(.easeOut(duration: 1.5).delay(0.05)) { r1Scale = 1.45; r1Opacity = 0 }
        withAnimation(.easeOut(duration: 1.8).delay(0.30)) { r2Scale = 1.45; r2Opacity = 0 }
        withAnimation(.easeOut(duration: 2.1).delay(0.55)) { r3Scale = 1.45; r3Opacity = 0 }

        // Particles fade in
        withAnimation(.easeIn(duration: 1.2).delay(0.4)) { particleOpacity = 1 }

        // Logo springs in with a bounce
        withAnimation(.spring(response: 0.65, dampingFraction: 0.60).delay(0.28)) { logoScale = 1.0 }
        withAnimation(.easeOut(duration: 0.45).delay(0.28)) { logoOpacity = 1 }

        // Brand text slides up
        withAnimation(.easeOut(duration: 0.55).delay(0.75)) { titleOpacity = 1; titleOffset = 0 }
        withAnimation(.easeOut(duration: 0.50).delay(1.05)) { subtitleOpacity = 1 }

        // Shimmer scan across logo
        withAnimation(.easeInOut(duration: 0.75).delay(1.35)) { shimmerX = 240 }

        // Dismiss at 3.3 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            onFinished?()
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
    private let pink  = Color(hex: "F4A0BB")
    private var bg: Color { Color(hex: "FFFFFF") }
    private var secondaryBg: Color { pink.opacity(0.15) }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 26) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 180)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 8) {
                        Text("GLOWZA")
                            .glowzaFont(size: 34, weight: .bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [brand, Color(hex: "D63063"), brand],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .tracking(6)
                        Text("Your beauty, simplified.")
                            .glowzaFont(size: 15, weight: .regular)
                            .foregroundColor(brand.opacity(0.45))
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
                            .glowzaFont(size: 17, weight: .semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: { onCreate?() }) {
                        Text("Create Account")
                            .glowzaFont(size: 17, weight: .semibold)
                            .foregroundColor(brand)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(secondaryBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(pink.opacity(0.35), lineWidth: 1)
                            )
                    }

                    Button(action: { onGuest?() }) {
                        Text("Continue as Guest")
                            .glowzaFont(size: 14, weight: .regular)
                            .foregroundColor(brand.opacity(0.50))
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
