import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0

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
        .tint(Color(hex: "AF1C47"))
        .onAppear { styleTabBar() }
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white

        let normalAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color(hex: "BEBEBE"))
        ]
        let selectedAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color(hex: "AF1C47"))
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "BEBEBE"))
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "AF1C47"))

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
            Color.white.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 52))
                    .foregroundColor(Color(hex: "AF1C47").opacity(0.4))
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
            }
        }
    }
}

#Preview { MainTabView() }
