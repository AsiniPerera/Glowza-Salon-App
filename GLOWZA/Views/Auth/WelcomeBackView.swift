import SwiftUI

private let brand = Color(hex: "962043")
private let hotPink = Color(hex: "962043")

// MARK: - Welcome Back View
struct WelcomeBackView: View {

    let userName: String
    var onContinue: () -> Void

    @State private var avatarScale: CGFloat = 0.5
    @State private var avatarOpacity: CGFloat = 0
    @State private var contentOpacity: CGFloat = 0
    @State private var contentOffset: CGFloat = 24

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Soft backdrop
            Circle()
                .fill(brand.opacity(0.05))
                .frame(width: 340, height: 340)
                .offset(x: 160, y: -200)

            VStack(spacing: 0) {
                Spacer()

                // ── Logo + greeting ──
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 112)
                        .scaleEffect(avatarScale)
                        .opacity(avatarOpacity)

                    VStack(spacing: 6) {
                        Text("Hello, Welcome Back ")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "4A4A4A"))
                        Text(userName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Text("Great to have you back!")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)
                }

                Spacer().frame(height: 32)

                // ── Upcoming appointment card ──
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("Upcoming Appointment", systemImage: "calendar.badge.clock")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(brand)
                        Spacer()
                        Text("View")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(brand)
                    }
                    .padding(.bottom, 14)

                    Rectangle().fill(Color(hex: "F5F5F5")).frame(height: 1)
                        .padding(.bottom, 14)

                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(brand.opacity(0.08))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundColor(brand)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Laser Treatment")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            Text("Tomorrow · 10:00 AM")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "6B6B6B"))
                            Text("Haley Avenue, Colombo")
                                .font(.system(size: 12))
                                .foregroundColor(brand)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                .padding(.horizontal, 24)
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer()

                // ── CTA ──
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Go to Dashboard")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 330, height: 55)
                    .background(hotPink)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 52)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.1)) {
                avatarScale = 1; avatarOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                contentOpacity = 1; contentOffset = 0
            }
        }
    }
}

#Preview { WelcomeBackView(userName: "Asini") {} }
