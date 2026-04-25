import SwiftUI

// MARK: - Glowza Splash Screen
struct SplashView: View {

    var onLogin: (() -> Void)? = nil
    var onCreate: (() -> Void)? = nil
    var onGuest: (() -> Void)? = nil

    @State private var logoScale: CGFloat = 0.92
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var buttonsOpacity: CGFloat = 0

    private let brand = Color(hex: "FF006E")

    var body: some View {
        ZStack {
            Color(hex: "F1F1F1").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 130)

                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 110)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 38)

                Text("GLOWZA")
                    .font(.system(size: 54, weight: .medium, design: .rounded))
                    .tracking(10)
                    .foregroundColor(Color(hex: "75777D"))
                .opacity(textOpacity)

                Spacer()

                VStack(spacing: 18) {
                    Button(action: { onLogin?() }) {
                        Text("Login")
                            .font(.system(size: 38, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(brand)
                            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                    }

                    Button(action: { onCreate?() }) {
                        Text("Register")
                            .font(.system(size: 38, weight: .medium, design: .rounded))
                            .foregroundColor(brand)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 36, style: .continuous)
                                    .stroke(brand.opacity(0.9), lineWidth: 2)
                            )
                    }

                    Button(action: { onGuest?() }) {
                        Text("Continue as a guest")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "5B5B5F"))
                            .underline()
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 56)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                logoScale = 1; logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.25)) {
                textOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                buttonsOpacity = 1
            }
        }
    }
}

#Preview {
    SplashView()
}
