// This file handles the app's launch experience, including the animated splash screen 
// and the landing screen where users choose to sign in or create an account.
import SwiftUI

// MARK: - Splash Helpers
// These are small helper views used to create the effects on the splash screen.

// This creates a single ring that can expand and fade out (ripple effect).
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

// A simple data structure to hold information about a floating particle.
private struct SParticle: Identifiable {
    let id: Int; let x, y, size, drift: CGFloat; let isGold: Bool
}

// This creates a background filled with small floating dots (particles).
private struct ParticleField: View {
    let brand: Color; let pink: Color
    @State private var drifting = false // Controls the animation state.

    // We hardcode the positions of 20 particles to make it look artistic and controlled.
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
                    .blur(radius: p.size * 0.4) // Softens the edges of the dots.
                    // When drifting is true, the dots move up by their 'drift' amount.
                    .offset(x: p.x, y: p.y + (drifting ? p.drift : 0))
            }
        }
        .onAppear {
            // This animation runs forever, moving the dots up and down slowly.
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                drifting = true
            }
        }
    }
}

// MARK: - Glowza Splash Screen
// This is the actual view that shows up when the app opens.

struct SplashView: View {

    // A closure (function) passed from outside. We run this when the animation finishes 
    // to tell the app to switch to the next screen.
    var onFinished: (() -> Void)? = nil

    // These @State variables control the animations. Changing them inside `withAnimation` 
    // triggers the smooth movements you see on screen.
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

    // App's specific brand colors.
    private let brand = Color(hex: "962043")
    private let pink  = Color(hex: "F4A0BB")

    var body: some View {
        ZStack {
            // Solid white background.
            Color.white.ignoresSafeArea()

            // ── Logo Section ─────────────────────────────────────────
            VStack(spacing: 28) {
                ZStack {
                    // Here we draw the logo and a white light (shimmer) that slides over it.
                    ZStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .opacity(logoOpacity)

                        // This is the shiny white bar that slides across the logo.
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.55), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 60, height: 200)
                        .offset(x: shimmerX)
                        .blendMode(.overlay) // Blends the white nicely over the logo.
                        .opacity(logoOpacity)
                    }
                    .frame(width: 200, height: 200)
                    .clipped() // Ensures the shimmer doesn't spill outside the logo box.
                    .scaleEffect(logoScale)
                }
            }
        }
        // When this screen appears on the phone, we start the animations!
        .onAppear { startAnimations() }
    }

    // This function triggers all the animations in a timed sequence.
    private func startAnimations() {
        // 1. The background circles expand outward and fade away.
        withAnimation(.easeOut(duration: 1.5).delay(0.05)) { r1Scale = 1.45; r1Opacity = 0 }
        withAnimation(.easeOut(duration: 1.8).delay(0.30)) { r2Scale = 1.45; r2Opacity = 0 }
        withAnimation(.easeOut(duration: 2.1).delay(0.55)) { r3Scale = 1.45; r3Opacity = 0 }

        // 2. The little background dots fade in.
        withAnimation(.easeIn(duration: 1.2).delay(0.4)) { particleOpacity = 1 }

        // 3. The main logo pops in with a spring (bouncy) animation.
        withAnimation(.spring(response: 0.65, dampingFraction: 0.60).delay(0.28)) { logoScale = 1.0 }
        withAnimation(.easeOut(duration: 0.45).delay(0.28)) { logoOpacity = 1 }

        // 4. Any text (if added) would slide up here.
        withAnimation(.easeOut(duration: 0.55).delay(0.75)) { titleOpacity = 1; titleOffset = 0 }
        withAnimation(.easeOut(duration: 0.50).delay(1.05)) { subtitleOpacity = 1 }

        // 5. The shiny light bar slides across the logo.
        withAnimation(.easeInOut(duration: 0.75).delay(1.35)) { shimmerX = 240 }

        // 6. After 3.3 seconds, we run the onFinished closure to move to the next screen!
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            onFinished?()
        }
    }
}

// MARK: - Landing Screen (Sign In / Create Account)
// This is the screen shown AFTER the splash screen finishes.

struct LandingView: View {

    // Closures to handle button clicks, passed in from the main app file.
    var onLogin:  (() -> Void)? = nil
    var onCreate: (() -> Void)? = nil
    var onGuest:  (() -> Void)? = nil

    // Holds the animation states for fading in the content.
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
                Spacer() // Pushes everything down to the center.

                // ── Logo & Text Section ─────────────────────────────────────────
                VStack(spacing: 26) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 180)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 8) {
                        Text("GLOWZA")
                            .glowzaFont(.h1, weight: .bold)
                            .foregroundStyle(
                                // A premium gradient for the brand text.
                                LinearGradient(
                                    colors: [brand, Color(hex: "D63063"), brand],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .tracking(6) // Spreads the letters apart.
                        Text("Your beauty, simplified.")
                            .glowzaFont(.body)
                            .foregroundColor(brand.opacity(0.45))
                    }
                    .multilineTextAlignment(.center)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer() // Pushes buttons to the bottom.

                // ── Action Buttons Section ─────────────────────────────────────────
                VStack(spacing: 14) {
                    Button(action: { onLogin?() }) {
                        Text("Sign In")
                    }
                    .buttonStyle(GlowzaPrimaryButtonStyle()) // Uses custom style defined elsewhere.

                    Button(action: { onCreate?() }) {
                        Text("Create Account")
                    }
                    .buttonStyle(GlowzaSecondaryButtonStyle())

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
            // When screen loads, content smoothly fades in and slides up!
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1; contentOffset = 0
            }
        }
    }
}

// MARK: - Previews
// These let developers see the screen directly inside Xcode without running the app.

#Preview("Splash") {
    SplashView()
        .environment(AppSettings.shared)
}

#Preview("Landing") {
    LandingView()
        .environment(AppSettings.shared)
}
