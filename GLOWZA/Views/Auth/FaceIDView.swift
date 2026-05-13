// This file creates a beautiful and creative full-screen experience for Face ID authentication.
// It shows a cool scanning animation while Apple's Face ID is doing its work!
import SwiftUI
import LocalAuthentication

private var brand: Color { Color.glowzaPrimary }

// MARK: - Face ID Auth View
struct FaceIDAuthView: View {
    
    // We use the same AuthViewModel to handle the actual Face ID logic.
    @StateObject private var viewModel = AuthViewModel()
    
    // These @State variables control the visual animations on this screen.
    @State private var isDetecting = false
    @State private var showDetectionUI = true // Toggles between the info screen and scanning screen.
    @State private var successAnimation = false // True when face is successfully scanned.
    @State private var rotationAngle: Double = 0 // Rotates the face icon while scanning.
    @State private var pulseScale: CGFloat = 1.0 // Pulses the rings.
    
    // Closures to tell the parent view what happened.
    let onAuthSuccess: () -> Void
    let onCancel: () -> Void
    
    @Environment(AppSettings.self) private var appSettings

    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var primaryText: Color { appSettings.themeText }

    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()

            // We switch between the cool "Detection UI" and the static "Initial Screen".
            if showDetectionUI {
                detectionScreen
                    .transition(.opacity) // Smooth crossfade.
            } else {
                initialScreen
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true) // We use our own custom back/cancel buttons.
        
        // Shows a popup alert if Face ID fails.
        .alert("Authentication Issue", isPresented: errorBinding) {
            Button("OK", role: .cancel) { viewModel.resetError() }
        } message: {
            Text(viewModel.authenticationError ?? "")
        }
        
        // We watch the ViewModel. When it says isAuthenticated = true, we trigger our success animation!
        .onChange(of: viewModel.isAuthenticated) { _, newValue in
            if newValue {
                // Play success animation first, then tell parent view we succeeded!
                withAnimation(.spring()) {
                    successAnimation = true
                }
                // Delay moving to next screen so user sees the checkmark!
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onAuthSuccess()
                }
            }
        }
        
        // Automatically start the Face ID scan when this screen opens!
        .onAppear {
            viewModel.authenticate()
        }
    }

    // SCREEN 1: The introduction screen explaining Face ID.
    private var initialScreen: some View {
        ZStack {
            // Decorative background circles.
            Circle().fill(brand.opacity(0.06)).frame(width: 360).offset(x: 160, y: -200)
            Circle().fill(brand.opacity(0.04)).frame(width: 280).offset(x: -130, y: 320)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Big Face ID Icon with layered circles.
                    ZStack {
                        Circle().fill(brand.opacity(0.08)).frame(width: 130, height: 130)
                        Circle().fill(brand.opacity(0.12)).frame(width: 100, height: 100)
                        Circle().fill(brand).frame(width: 76, height: 76)
                            .shadow(color: brand.opacity(0.30), radius: 16)
                        Image(systemName: viewModel.biometricIconName)
                            .glowzaFont(size: 34, weight: .light)
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 10) {
                        Text("Secure Sign In")
                            .glowzaFont(size: 28, weight: .bold)
                            .foregroundColor(primaryText)
                        Text("Use Face ID for a faster, private\nsign in to your GLOWZA account.")
                            .glowzaFont(size: 15)
                            .foregroundColor(Color(hex: "6B6B6B"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }

                Spacer().frame(height: 44)

                // Action Card at the bottom.
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetectionUI = true
                        }
                        viewModel.authenticate()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.biometricIconName)
                                .glowzaFont(size: 14, weight: .medium)
                            Text(viewModel.biometricButtonTitle)
                                .glowzaFont(size: 15, weight: .semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(brand)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(viewModel.isAuthenticating)
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield")
                            .glowzaFont(size: 11)
                            .foregroundColor(brand.opacity(0.6))
                        Text("Your biometric data stays on this device")
                            .glowzaFont(size: 12)
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                }
                .padding(28)
                .background(surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(appSettings.themeRaised, lineWidth: 1)
                )

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }

    // SCREEN 2: The active scanning screen with cool animations!
    private var detectionScreen: some View {
        ZStack {
            // Soft gradient background.
            LinearGradient(
                gradient: Gradient(colors: [
                    brand.opacity(0.05),
                    pageBackground
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Navigation Header.
                HStack(alignment: .center) {
                    Button(action: {
                        onCancel()
                    }) {
                        Text("Cancel")
                            .glowzaFont(size: 15, weight: .semibold)
                            .foregroundColor(brand)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("Detecting Face ID")
                            .glowzaFont(size: 15, weight: .semibold)
                            .foregroundColor(appSettings.themeText)
                        Text(successAnimation ? "Face ID Verified" : "Position your face in frame")
                            .glowzaFont(size: 12)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(brand.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "faceid")
                            .glowzaFont(size: 16, weight: .semibold)
                            .foregroundColor(brand)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)

                Spacer()

                // Center Animation Area.
                ZStack {
                    // Outer static scanning ring.
                    Circle()
                        .stroke(brand.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 280, height: 280)

                    // 3 Pulsing circles that expand and fade.
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(brand.opacity(0.08), lineWidth: 1)
                            .frame(width: 280 - CGFloat(index) * 40, height: 280 - CGFloat(index) * 40)
                            .scaleEffect(successAnimation ? 1.2 : 0.9)
                            .opacity(successAnimation ? 0 : 0.8 - Double(index) * 0.2)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: successAnimation
                            )
                    }

                    // Center box holding either the scanning face or the success checkmark.
                    ZStack {
                        Circle()
                            .fill(brand.opacity(0.08))
                            .frame(width: 200, height: 200)

                        if successAnimation {
                            // Shows big pink checkmark when authenticated!
                            Image(systemName: "checkmark.circle.fill")
                                .glowzaFont(size: 80, weight: .semibold)
                                .foregroundColor(brand)
                                .scaleEffect(1.0)
                                .transition(.scale)
                        } else {
                            // Shows the scanning face icon.
                            VStack(spacing: 16) {
                                Image(systemName: "faceid")
                                    .glowzaFont(size: 60, weight: .light)
                                    .foregroundColor(brand)
                                    // Rotates slowly to look like it's processing!
                                    .rotationEffect(.degrees(rotationAngle))

                                // Visual "Scanning lines" under the icon.
                                VStack(spacing: 0) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        Rectangle()
                                            .fill(brand.opacity(0.2))
                                            .frame(height: 8)
                                            .padding(.vertical, 4)
                                    }
                                }
                                .frame(width: 60, height: 40)
                            }
                        }
                    }
                }
                // Triggers the continuous rotation of the face icon!
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }

                Spacer()

                // Status Text at the bottom.
                VStack(spacing: 12) {
                    if successAnimation {
                        VStack(spacing: 4) {
                            Text("Authentication Successful!")
                                .glowzaFont(size: 18, weight: .bold)
                                .foregroundColor(appSettings.themeText)
                            Text("Welcome back to GLOWZA")
                                .glowzaFont(size: 14)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        VStack(spacing: 4) {
                            Text("Scanning Your Face")
                                .glowzaFont(size: 18, weight: .bold)
                                .foregroundColor(appSettings.themeText)
                            Text("Please remain still")
                                .glowzaFont(size: 14)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // This converts the ViewModel's error string into a simple True/False boolean 
    // that the SwiftUI `.alert` modifier needs to know when to pop up.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.authenticationError != nil },
            set: { if !$0 { viewModel.resetError() } }
        )
    }
}

#Preview {
    FaceIDAuthView(onAuthSuccess: {}, onCancel: {})
}
