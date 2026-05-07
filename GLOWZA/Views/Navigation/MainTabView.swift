import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            BookingsView()
                .tabItem {
                    Label("Bookings", systemImage: selectedTab == 1 ? "calendar.badge.clock" : "calendar")
                }
                .tag(1)

            AIBeautyView()
                .tabItem {
                    Label("AI Beauty", systemImage: "wand.and.stars")
                }
                .tag(2)

            CompareView()
                .tabItem {
                    Label("Compare", systemImage: selectedTab == 3 ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .tint(Color.glowzaPrimary)
        .onAppear {
            styleTabBar()
            styleNavigationBar()
        }
        .onChange(of: appSettings.isDarkMode) { _, _ in
            styleTabBar()
            styleNavigationBar()
        }
        .onChange(of: appSettings.isHighContrast) { _, _ in
            styleTabBar()
            styleNavigationBar()
        }
        .onReceive(NotificationCenter.default.publisher(for: .glowzaGoToHomeTab)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .glowzaGoToBookingsTab)) { _ in
            selectedTab = 1
        }
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = appSettings.isHighContrast
            ? UIColor.black
            : appSettings.isDarkMode
                ? UIColor(Color(hex: "0A0A0A"))
                : UIColor.white

        let normalColor  = UIColor((appSettings.isHighContrast || appSettings.isDarkMode) ? Color.white.opacity(0.45) : Color(hex: "BEBEBE"))
        let selectedColor = UIColor(Color.glowzaPrimary)

        let normalAttr: [NSAttributedString.Key: Any]   = [.foregroundColor: normalColor]
        let selectedAttr: [NSAttributedString.Key: Any] = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = normalAttr
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.stackedLayoutAppearance.normal.iconColor   = normalColor
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    /// Style system navigation bars to match the HC / dark-mode theme.
    /// This ensures nav bar backgrounds, title text, and back-button tint all respect the active theme.
    private func styleNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        if appSettings.isHighContrast {
            // HC: OLED black bar, crisp white title, white back button, Electric Rose tint
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
