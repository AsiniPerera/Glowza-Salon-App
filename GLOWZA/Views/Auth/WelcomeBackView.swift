// This file shows a personalized "Welcome Back" screen to the user after they log in.
// It also shows a mock "Upcoming Appointment" card to make the app feel alive.
import SwiftUI

private var brand: Color { Color.glowzaPrimary }
private let hotPink = Color(hex: "962043")

// MARK: - Welcome Back View
struct WelcomeBackView: View {

    // We pass the user's name from the previous screen to personalize the greeting!
    let userName: String
    var onContinue: () -> Void // Runs when they click "Go to Dashboard".
    var onBack: (() -> Void)? = nil // Optional back button closure.

    // @State variables to control the entry animations.
    @State private var avatarScale: CGFloat = 0.5
    @State private var avatarOpacity: CGFloat = 0
    @State private var contentOpacity: CGFloat = 0
    @State private var contentOffset: CGFloat = 24
    
    @Environment(AppSettings.self) private var appSettings

    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var dividerColor: Color { appSettings.themeDivider }
    private var primaryText: Color { appSettings.themeText }

    var body: some View {
        ZStack(alignment: .topLeading) {
            pageBackground.ignoresSafeArea()

            // 1. Decorative background circle.
            Circle()
                .fill(brand.opacity(0.05))
                .frame(width: 340, height: 340)
                .offset(x: 160, y: -200)

            // 2. Optional Back button (only shows if onBack is provided).
            GlowzaCircleBackButton(action: { onBack?() })
                .padding(.top, 60)
                .padding(.leading, 24)
                .opacity(onBack != nil ? 1 : 0)
                
            VStack(spacing: 0) {
                Spacer()

                // ── Logo & Greeting Section ──
                VStack(spacing: 24) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 500, height: 260)
                        .scaleEffect(avatarScale) // Springs up!
                        .opacity(avatarOpacity)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 6) {
                        Text("Hello, Welcome Back ")
                            .glowzaFont(size: 20, weight: .semibold)
                            .foregroundColor(Color(hex: "4A4A4A"))
                        
                        // Displaying the dynamic user name here!
                        Text(userName)
                            .glowzaFont(size: 22, weight: .bold)
                            .foregroundColor(primaryText)
                            
                        Text("Great to have you back!")
                            .glowzaFont(size: 14)
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    .multilineTextAlignment(.center)
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)
                }

                Spacer().frame(height: 32)

                // ── Upcoming Appointment Card (Mock Data) ──
                // This is a great pattern for students: hardcoding data for a demo 
                // when you don't have a full backend hooked up yet.
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("Upcoming Appointment", systemImage: "calendar.badge.clock")
                            .glowzaFont(size: 13, weight: .semibold)
                            .foregroundColor(brand)
                        Spacer()
                        Text("View")
                            .glowzaFont(size: 13, weight: .medium)
                            .foregroundColor(brand)
                    }
                    .padding(.bottom, 14)

                    Rectangle().fill(dividerColor).frame(height: 1)
                        .padding(.bottom, 14)

                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(brand.opacity(0.08))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .glowzaFont(size: 20)
                                    .foregroundColor(brand)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Laser Treatment")
                                .glowzaFont(size: 15, weight: .semibold)
                                .foregroundColor(primaryText)
                            Text("Tomorrow · 10:00 AM")
                                .glowzaFont(size: 13)
                                .foregroundColor(Color(hex: "6B6B6B"))
                            Text("Golden Avenue, Colombo")
                                .glowzaFont(size: 12)
                                .foregroundColor(brand)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .glowzaFont(size: 12, weight: .semibold)
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                }
                .padding(20)
                .background(surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                .padding(.horizontal, 24)
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer()

                // ── Call To Action Button (Go to Dashboard) ──
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Go to Dashboard")
                            .glowzaFont(size: 15, weight: .semibold)
                        Image(systemName: "arrow.right")
                            .glowzaFont(size: 13, weight: .bold)
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
            // Animate the logo with a springy bounce.
            withAnimation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.1)) {
                avatarScale = 1; avatarOpacity = 1
            }
            // Animate the text and card sliding up.
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                contentOpacity = 1; contentOffset = 0
            }
        }
    }
}

#Preview { WelcomeBackView(userName: "Asini") {} }
