import SwiftUI
import LocalAuthentication

// MARK: - Welcome Back View (cream + gold theme, matches home palette)
struct WelcomeBackView: View {

    let userName: String
    var onContinue: () -> Void

    @State private var avatarScale: CGFloat = 0.5
    @State private var avatarOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var textOffset: CGFloat = 24
    @State private var cardOpacity: CGFloat = 0
    @State private var cardOffset: CGFloat = 20
    @State private var buttonOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            Color(hex: "F5F0E8").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Avatar + Greeting ──
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "E5A820").opacity(0.25), Color(hex: "E5A820").opacity(0.05)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 112, height: 112)

                        Circle()
                            .stroke(Color(hex: "E5A820").opacity(0.5), lineWidth: 2)
                            .frame(width: 112, height: 112)

                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "C8860A"))
                    }
                    .scaleEffect(avatarScale)
                    .opacity(avatarOpacity)

                    VStack(spacing: 6) {
                        Text("Hello, Welcome Back 👋")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A1A"))

                        Text(userName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "C8860A"))

                        Text("We're glad to have you back.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                }

                Spacer().frame(height: 32)

                // ── Upcoming Appointment Card ──
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("Upcoming Appointment", systemImage: "calendar.badge.clock")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "C8860A"))
                        Spacer()
                    }
                    .padding(.bottom, 12)

                    Divider().background(Color(hex: "E5A820").opacity(0.3))
                        .padding(.bottom, 14)

                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "E5A820").opacity(0.15))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "C8860A"))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Laser Treatment")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            Text("Tomorrow · 10:00 AM")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "8A8A8A"))
                            Text("Haley Avenue, Colombo")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "C8860A"))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "C8860A").opacity(0.6))
                    }
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                .padding(.horizontal, 24)
                .opacity(cardOpacity)
                .offset(y: cardOffset)

                Spacer()

                // ── Enter Button ──
                Button(action: onContinue) {
                    HStack(spacing: 10) {
                        Text("Go to Dashboard")
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(hex: "E5A820").opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(buttonOpacity)
            }
        }
        .onAppear { animateIn() }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.1)) {
            avatarScale = 1.0; avatarOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
            textOpacity = 1.0; textOffset = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
            cardOpacity = 1.0; cardOffset = 0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            buttonOpacity = 1.0
        }
    }
}

#Preview {
    WelcomeBackView(userName: "Asini") {}
}
