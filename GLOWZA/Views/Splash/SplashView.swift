import SwiftUI

// MARK: - Glowza Splash Screen
struct SplashView: View {

    var onLogin: (() -> Void)? = nil
    var onCreate: (() -> Void)? = nil
    var onGuest: (() -> Void)? = nil

    @State private var logoScale: CGFloat = 0.88
    @State private var logoOpacity: CGFloat = 0
    @State private var buttonsOpacity: CGFloat = 0

    private let brand = Color(hex: "962043")

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // Logo + tagline
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 114)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    VStack(spacing: 6) {
                        Text("GLOWZA")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(brand)
                            .tracking(2)
                        Text("Your beauty, simplified.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(hex: "9A9A9F"))
                    }
                    .opacity(logoOpacity)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { onLogin?() }) {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 330, height: 55)
                            .background(brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: { onCreate?() }) {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(brand)
                            .frame(width: 330, height: 55)
                            .background(brand.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: { onGuest?() }) {
                        Text("Continue as Guest")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "9A9A9F"))
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 56)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75)) {
                logoScale = 1; logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.35)) {
                buttonsOpacity = 1
            }
        }
    }
}

#Preview {
    SplashView()
}
