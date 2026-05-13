import SwiftUI
import FirebaseCore
import FirebaseAuth

// This is the main entry point of the app!
// The @main attribute tells the system that this struct contains the app's configuration.
@main
struct GLOWZAApp: App {

    init() {
        // 1. Initialize Core Data
        // This loads the persistent store!
        _ = CoreDataStack.shared

        // 2. Configure Firebase
        // This must be done before using any Firebase services!
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // We inject these shared objects into the environment so any view can access them!
                .environment(TreatmentComparisonStore.shared)
                .environment(AppSettings.shared)
                .environment(AuthService.shared) // global auth state
                .buttonStyle(GlowzaRoundedButtonStyle()) // Custom button style for the app.
        }
    }
}

// MARK: - Screen enum
// Defines all the major screens for root navigation.
private enum Screen {
    case splash, landing, onboarding, login, createAccount, forgotPassword, main
}

// MARK: - Root Navigation Controller
// This view manages which screen is currently shown to the user.
struct RootView: View {
    @State private var screen: Screen = .splash // Start with the splash screen!
    @Environment(AuthService.self) private var authService
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var systemContrast

    var body: some View {
        ZStack {
            switch screen {

            // ── Splash: always goes to Landing — user must always login ─────
            case .splash:
                SplashView(onFinished: {
                    // Transition to landing screen after splash finishes!
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
            // Automatically enable high contrast if system setting is on!
            if val == .increased && !settings.isHighContrast {
                settings.isHighContrast = true
            }
        }
        // Listening for sign out notification to go back to login screen!
        .onReceive(NotificationCenter.default.publisher(for: .glowzaSignOut)) { _ in
            withAnimation { screen = .login }
        }
        // Handles deep links (e.g., glowza://quick-book?salon=Golden%20Avenue)
        .onOpenURL { url in
            guard url.scheme?.lowercased() == "glowza" else { return }
            
            if url.host == "quick-book" {
                // Parse the salon name from query parameters!
                let salonName = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "salon" })?
                    .value?.removingPercentEncoding ?? "Golden Avenue"
                
                screen = .main
                // Tell the tab view to go home first!
                NotificationCenter.default.post(name: .glowzaGoToHomeTab, object: nil)
                
                // Delay slightly to allow the view to load before showing booking!
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
// This is a backup view used during development!
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
