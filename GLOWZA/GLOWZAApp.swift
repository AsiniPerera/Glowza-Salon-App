import SwiftUI
import FirebaseCore

@main
struct GLOWZAApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(TreatmentComparisonStore.shared)
        }
    }
}

// MARK: - Screen enum
private enum Screen {
    case splash, onboarding, login, createAccount, main
}

// MARK: - Root Navigation Controller
struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var screen: Screen = .splash
    @State private var isAuthenticated = false

    var body: some View {
        ZStack {
            switch screen {

            case .splash:
                SplashView(
                    onLogin:   { withAnimation { screen = .login } },
                    onCreate:  { withAnimation { screen = .createAccount } },
                    onFaceID:  { withAnimation { isAuthenticated = true } }
                )
                .transition(.opacity)
                .zIndex(5)

            case .onboarding:
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal:   .move(edge: .leading)
                    ))
                    .zIndex(4)

            case .login:
                SignInView(
                    isAuthenticated: $isAuthenticated,
                    onCreateAccount: { withAnimation { screen = .createAccount } }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(3)

            case .createAccount:
                CreateAccountView(
                    isAuthenticated: $isAuthenticated,
                    onSignIn: { withAnimation { screen = .login } }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(3)

            case .main:
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1)
            }
        }
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
