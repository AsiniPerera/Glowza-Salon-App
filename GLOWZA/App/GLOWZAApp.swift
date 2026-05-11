import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct GLOWZAApp: App {

    init() {
        // 1. Core Data
        _ = CoreDataStack.shared

        // 2. Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(TreatmentComparisonStore.shared)
                    .environment(AppSettings.shared)
                    .environment(AuthService.shared) // global auth state

                // Notification overlay
                NotificationContainer()
                    .zIndex(999)
            }
            .buttonStyle(GlowzaRoundedButtonStyle())
        }
    }
}

// MARK: - Screen enum
private enum Screen {
    case splash, landing, onboarding, login, createAccount, forgotPassword, main
}

// MARK: - Root Navigation Controller
struct RootView: View {
    @State private var screen: Screen = .splash
    @Environment(AuthService.self) private var authService
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var systemContrast

    var body: some View {
        ZStack {
            switch screen {

            // ── Splash: always goes to Landing — user must always login ─────
            case .splash:
                SplashView(onFinished: {
                    withAnimation { screen = .landing }
                })
                .transition(.opacity)
                .zIndex(5)

            // ── Landing: Sign In / Create Account options ─────────────────────
            case .landing:
                LandingView(
                    onLogin:  { withAnimation { screen = .login } },
                    onCreate: { withAnimation { screen = .createAccount } },
                    onGuest:  { withAnimation { screen = .main } }
                )
                .transition(.opacity)
                .zIndex(4)

            case .onboarding:
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal:   .move(edge: .leading)
                    ))
                    .zIndex(4)

            // ── Login: enter credentials → Firebase sign in ────────────────────
            case .login:
                SignInView(
                    onSignIn:         { withAnimation { screen = .main } },
                    onCreateAccount:  { withAnimation { screen = .createAccount } },
                    onBack:           { withAnimation { screen = .landing } },
                    onForgotPassword: { withAnimation { screen = .forgotPassword } }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(3)

            // ── Create Account: register → then must login ────────────────────
            case .createAccount:
                CreateAccountView(
                    onCreateAccount: { withAnimation { screen = .login } }, // → must login after registering
                    onSignIn:        { withAnimation { screen = .login } },
                    onBack:          { withAnimation { screen = .landing } }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(3)

            case .forgotPassword:
                ForgotPasswordView(onBack: { withAnimation { screen = .login } })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(3)

            // ── Main Dashboard ─────────────────────────────────────────────────
            case .main:
                MainTabView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .glowzaHighContrastStyle(enabled: settings.isHighContrast)
        .animation(.easeInOut(duration: 0.4), value: screen)
        .onChange(of: systemContrast) { _, val in
            if val == .increased && !settings.isHighContrast {
                settings.isHighContrast = true
            }
        }
        // Sign out notification → go back to login
        .onReceive(NotificationCenter.default.publisher(for: .glowzaSignOut)) { _ in
            withAnimation { screen = .login }
        }
        .onOpenURL { url in
            guard url.scheme?.lowercased() == "glowza" else { return }
            if url.host == "quick-book" {
                let salonName = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "salon" })?
                    .value?.removingPercentEncoding ?? "Golden Avenue"
                screen = .main
                NotificationCenter.default.post(name: .glowzaGoToHomeTab, object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(name: .glowzaQuickBookRequested, object: salonName)
                }
            } else if url.host == "bookings" {
                let showUpcoming = url.path.lowercased().contains("upcoming")
                screen = .main
                NotificationCenter.default.post(name: .glowzaGoToBookingsTab, object: nil)
                if showUpcoming {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(name: .glowzaShowUpcomingBookings, object: nil)
                    }
                }
            }
        }
        .preferredColorScheme(settings.colorScheme)
        .environment(\.isHighContrast, settings.isHighContrast)
    }
}


// MARK: - Placeholder Dashboard
struct PlaceholderDashboardView: View {
    var body: some View {
        ZStack {
            Color.glowzaBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .glowzaFont(size: 56)
                    .foregroundColor(Color.glowzaGold)
                Text("You're In! ")
                    .glowzaFont(size: 28, weight: .bold)
                Text("Dashboard — share Figma design to build")
                    .glowzaFont(size: 14)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
