import SwiftUI

// This is the root navigation container for the app after the user logs in.
// It sets up the bottom tab bar with 5 main sections.
struct MainTabView: View {

    @State private var selectedTab = 0 // Tracks which tab is currently active.
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        TabView(selection: $selectedTab) {

            // Tab 1: Home
            HomeView()
                .tabItem {
                    // Changes icon filled/empty state based on selection!
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0) // Tag matches the selectedTab state value!

            // Tab 2: Bookings
            BookingsView()
                .tabItem {
                    Label("Bookings", systemImage: selectedTab == 1 ? "calendar.badge.clock" : "calendar")
                }
                .tag(1)

            // Tab 3: AI Beauty
            AIBeautyView()
                .tabItem {
                    Label("AI Beauty", systemImage: "wand.and.stars")
                }
                .tag(2)

            // Tab 4: Compare
            CompareView()
                .tabItem {
                    Label("Compare", systemImage: selectedTab == 3 ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle")
                }
                .tag(3)

            // Tab 5: Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .tint(Color.glowzaPrimary) // Sets the accent color for active items.
        .overlay(alignment: .bottomTrailing) {
            VoiceOverControlView()
        }
        .onAppear {
            // We need to style the UIKit appearances on load!
            styleTabBar()
            styleNavigationBar()
        }
        // These watchers ensure the bars redraw if the user toggles dark/HC mode!
        .onChange(of: appSettings.isDarkMode) { _, _ in
            styleTabBar()
            styleNavigationBar()
        }
        .onChange(of: appSettings.isHighContrast) { _, _ in
            styleTabBar()
            styleNavigationBar()
        }
        // Listening for system-wide notifications to switch tabs programmatically!
        .onReceive(NotificationCenter.default.publisher(for: .glowzaGoToHomeTab)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .glowzaGoToBookingsTab)) { _ in
            selectedTab = 1
        }
        // VoiceOver: Speak screen summary when the tab changes!
        .onChange(of: selectedTab) { _, newValue in
            speakTabSummary(for: newValue)
        }
    }

    // Provides a spoken summary for each main screen!
    private func speakTabSummary(for tabIndex: Int) {
        let summary: String
        switch tabIndex {
        case 0: summary = "Welcome to GLOWZA Home. Discover top salons and latest offers."
        case 1: summary = "Your Bookings. View and manage your upcoming and past appointments."
        case 2: summary = "AI Beauty Analysis. Get personalized skincare advice from our AI."
        case 3: summary = "Compare Salons. Easily compare prices and ratings side by side."
        case 4: summary = "Your Profile. Manage your account, security, and app preferences."
        default: return
        }
        appSettings.currentScreenSummary = summary
        appSettings.speak(summary)
    }

    // Since SwiftUI TabView has limited styling options, we drop down to 
    // UIKit's UITabBarAppearance to achieve the premium blur and colors!
    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Pick background color based on active theme
        appearance.backgroundColor = appSettings.isHighContrast
            ? UIColor.black
            : appSettings.isDarkMode
                ? UIColor(Color(hex: "0A0A0A"))
                : UIColor.white

        let normalColor  = UIColor((appSettings.isHighContrast || appSettings.isDarkMode) ? Color.white.opacity(0.45) : Color(hex: "BEBEBE"))
        let selectedColor = UIColor(Color.glowzaPrimary)

        let normalAttr: [NSAttributedString.Key: Any]   = [.foregroundColor: normalColor]
        let selectedAttr: [NSAttributedString.Key: Any] = [.foregroundColor: selectedColor]
        
        // Apply text and icon colors for normal and selected states!
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = normalAttr
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.stackedLayoutAppearance.normal.iconColor   = normalColor
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // Style system navigation bars to match the High Contrast / dark-mode theme.
    // This ensures nav bar backgrounds, title text, and back-button tint all respect the active theme.
    private func styleNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        if appSettings.isHighContrast {
            // HC: OLED black bar, crisp white title, Electric Rose tint
            appearance.backgroundColor = .black
            appearance.titleTextAttributes         = [.foregroundColor: UIColor.white,
                                                      .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
            appearance.largeTitleTextAttributes    = [.foregroundColor: UIColor.white,
                                                      .font: UIFont.systemFont(ofSize: 34, weight: .bold)]
            appearance.shadowColor = .clear                        // remove the hairline
            UINavigationBar.appearance().tintColor = UIColor(Color(hex: "FF2D55"))  // back chevron + buttons
        } else if appSettings.isDarkMode {
            // Dark mode: near-black bar, white title, rose tint
            appearance.backgroundColor = UIColor(Color(hex: "0A0A0A"))
            appearance.titleTextAttributes         = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes    = [.foregroundColor: UIColor.white]
            appearance.shadowColor = .clear
            UINavigationBar.appearance().tintColor = UIColor(Color(hex: "962043"))
        } else {
            // Light mode: white bar, dark title
            appearance.backgroundColor = .white
            appearance.titleTextAttributes         = [.foregroundColor: UIColor(Color(hex: "1A1A1A"))]
            appearance.largeTitleTextAttributes    = [.foregroundColor: UIColor(Color(hex: "1A1A1A"))]
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.06)
            UINavigationBar.appearance().tintColor = UIColor(Color(hex: "962043"))
        }

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
    }
}

// MARK: - Placeholder views kept for build compatibility
// These are not used in the final app but kept so the project builds if referenced elsewhere!
struct BookingsPlaceholderView: View {
    var body: some View {
        PlaceholderScreen(icon: "calendar", title: "Bookings", subtitle: "")
    }
}

struct AIPlaceholderView: View {
    var body: some View {
        PlaceholderScreen(icon: "wand.and.stars", title: "AI Beauty", subtitle: "")
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        PlaceholderScreen(icon: "person.circle", title: "Profile", subtitle: "")
    }
}

struct PlaceholderScreen: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            Color.glowzaBackground.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .glowzaFont(size: 52)
                    .foregroundColor(Color(hex: "962043").opacity(0.4))
                Text(title)
                    .glowzaFont(size: 22, weight: .bold)
                    .foregroundColor(Color(hex: "1A1A1A"))
            }
        }
    }
}

#Preview { MainTabView() }
