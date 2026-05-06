import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct GLOWZAApp: App {
    init() {
        // Initialize Core Data first
        _ = CoreDataStack.shared
        print("✅ Core Data stack initialized")
        
        // Then Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(TreatmentComparisonStore.shared)
                    .environment(AppSettings.shared)
                
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
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var screen: Screen = .splash
    @State private var isAuthenticated = false
    @Environment(AppSettings.self) private var settings
    @State private var authService = AuthService.shared

    var body: some View {
        ZStack {
            if isAuthenticated {
                // User is signed in, show main app
                MainTabView()
                    .transition(.opacity)
                    .zIndex(2)
            } else {
                // User is not signed in, show auth screens
                switch screen {

                case .splash:
                    SplashView(
                        onFinished: { withAnimation { screen = .landing } }
                    )
                    .transition(.opacity)
                    .zIndex(5)

                case .landing:
                    LandingView(
                        onLogin:  { withAnimation { screen = .login } },
                        onCreate: { withAnimation { screen = .createAccount } },
                        onGuest:  { withAnimation { isAuthenticated = true } }
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

                case .login:
                    SignInView(
                        onSignIn:        { withAnimation { isAuthenticated = true } },
                        onCreateAccount: { withAnimation { screen = .createAccount } },
                        onForgotPassword: { withAnimation { screen = .forgotPassword } }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(3)

                case .createAccount:
                    CreateAccountView(
                        onCreateAccount: { withAnimation { isAuthenticated = true } },
                        onSignIn: { withAnimation { screen = .login } }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(3)

                case .forgotPassword:
                    ForgotPasswordView(onBack: { withAnimation { screen = .login } })
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .zIndex(3)

                case .main:
                    MainTabView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .glowzaHighContrastStyle(enabled: settings.isHighContrast)
        .animation(.easeInOut(duration: 0.4), value: screen)
        .onChange(of: isAuthenticated) { _, newValue in
            if newValue {
                withAnimation { screen = .main }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .glowzaSignOut)) { _ in
            withAnimation {
                isAuthenticated = false
                screen = .login
            }
        }
        .onOpenURL { url in
            guard url.scheme?.lowercased() == "glowza" else { return }

            if url.host == "quick-book" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let salonName = components?
                    .queryItems?
                    .first(where: { $0.name == "salon" })?
                    .value?
                    .removingPercentEncoding
                    ?? "Haley Avenue"

                if !isAuthenticated {
                    withAnimation {
                        isAuthenticated = true
                        screen = .main
                    }
                }

                NotificationCenter.default.post(name: .glowzaGoToHomeTab, object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(name: .glowzaQuickBookRequested, object: salonName)
                }
            } else if url.host == "bookings" {
                let showUpcoming = url.path.lowercased().contains("upcoming")

                if !isAuthenticated {
                    withAnimation {
                        isAuthenticated = true
                        screen = .main
                    }
                }

                NotificationCenter.default.post(name: .glowzaGoToBookingsTab, object: nil)
                if showUpcoming {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(name: .glowzaShowUpcomingBookings, object: nil)
                    }
                }
            }
        }
        .preferredColorScheme(settings.isHighContrast ? .dark : settings.colorScheme)
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
                    .font(.system(size: 56))
                    .foregroundColor(Color.glowzaGold)
                Text("You're In! 🎉")
                    .font(.system(size: 28, weight: .bold))
                Text("Dashboard — share Figma design to build")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
