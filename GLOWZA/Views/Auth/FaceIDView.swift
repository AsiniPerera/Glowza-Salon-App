import SwiftUI
import LocalAuthentication

private var brand: Color { Color.glowzaPrimary }

// MARK: - Face ID Auth View
struct FaceIDAuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isDetecting = false
    @State private var showDetectionUI = true

    @State private var successAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    let onAuthSuccess: () -> Void
    @Environment(AppSettings.self) private var appSettings

    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var primaryText: Color { appSettings.themeText }

    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()

            if showDetectionUI {

                // Creative Face ID Detection UI
                detectionScreen
                    .transition(.opacity)
            } else {
                // Initial Sign In Screen
                initialScreen
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .alert("Authentication Issue", isPresented: errorBinding) {
            Button("OK", role: .cancel) { viewModel.resetError() }
        } message: {
            Text(viewModel.authenticationError ?? "")
        }
        .onChange(of: viewModel.isAuthenticated) { _, newValue in
            if newValue {
                successAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onAuthSuccess()
                }
            }
        }
        .onAppear {
            viewModel.authenticate()
        }

    }

    private var initialScreen: some View {
        ZStack {
            Circle().fill(brand.opacity(0.06)).frame(width: 360).offset(x: 160, y: -200)
            Circle().fill(brand.opacity(0.04)).frame(width: 280).offset(x: -130, y: 320)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Icon
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

    private var detectionScreen: some View {
        ZStack {
            // Background gradient
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
                // Status indicator
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
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
                            .fill(successAnimation ? Color.green.opacity(0.1) : brand.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: successAnimation ? "checkmark" : "faceid")
                            .glowzaFont(size: 16, weight: .semibold)
                            .foregroundColor(successAnimation ? .green : brand)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)

                Spacer()

                // Creative detection animation
                ZStack {
                    // Outer scanning ring
                    Circle()
                        .stroke(brand.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 280, height: 280)

                    // Pulsing circles
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

                    // Center face icon with rotation
                    ZStack {
                        Circle()
                            .fill(brand.opacity(0.08))
                            .frame(width: 200, height: 200)

                        if successAnimation {
                            // Success checkmark
                            Image(systemName: "checkmark.circle.fill")
                                .glowzaFont(size: 80, weight: .semibold)
                                .foregroundColor(.green)
                                .scaleEffect(1.0)
                                .transition(.scale)
                        } else {
                            // Scanning face
                            VStack(spacing: 16) {
                                Image(systemName: "faceid")
                                    .glowzaFont(size: 60, weight: .light)
                                    .foregroundColor(brand)
                                    .rotationEffect(.degrees(rotationAngle))

                                // Scanning line
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
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }

                Spacer()

                // Status text
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

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.authenticationError != nil },
            set: { if !$0 { viewModel.resetError() } }
        )
    }
}

#Preview {
    FaceIDAuthView(onAuthSuccess: {})
}
