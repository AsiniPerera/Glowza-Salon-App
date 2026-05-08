import SwiftUI

private var brand: Color { Color.glowzaPrimary }
private let hotPink = Color(hex: "962043")

// MARK: - Onboarding Data Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let badge: String
    let titleLine1: String
    let titleLine2: String
    let subtitle: String
}

// MARK: - Main Onboarding View
struct OnboardingView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentIndex = 0
    @Environment(AppSettings.self) private var appSettings

    private var pageBackground: Color { appSettings.themePage }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "scissors",
            badge: "Expert Care",
            titleLine1: "Meet Your",
            titleLine2: "Expert Stylist",
            subtitle: "Our curated professionals are dedicated to bringing your unique vision to life with precision and luxury."
        ),
        OnboardingPage(
            icon: "map.fill",
            badge: "Smart Search",
            titleLine1: "Find Salons",
            titleLine2: "Near You",
            subtitle: "Discover top-rated clinics filtered by services, distance, and reputation scores — right on the map."
        ),
        OnboardingPage(
            icon: "wand.and.stars",
            badge: "AI Powered",
            titleLine1: "AI Skin",
            titleLine2: "Analysis",
            subtitle: "On-device AI analyzes your skin and suggests clinical treatments. Your photos never leave your device."
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            pageBackground.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(
                        page: page,
                        isLast: index == pages.count - 1,
                        onNext: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                if index < pages.count - 1 {
                                    currentIndex = index + 1
                                } else {
                                    hasSeenOnboarding = true
                                }
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentIndex ? hotPink : Color(hex: "E5E5EA"))
                        .frame(width: i == currentIndex ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentIndex)
                }
            }
            .padding(.bottom, 112)
        }
    }
}

// MARK: - Single Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLast: Bool
    let onNext: () -> Void

    @State private var heroScale:  CGFloat = 0.85
    @State private var heroOpacity: CGFloat = 0
    @State private var txtOffset:  CGFloat = 28
    @State private var txtOpacity: CGFloat = 0
    @Environment(AppSettings.self) private var appSettings

    private var pageBackground: Color { appSettings.themePage }
    private var heroBackground: Color { appSettings.themeSurface }

    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Hero illustration area ──
                ZStack {
                    // Background shape
                    RoundedRectangle(cornerRadius: 0)
                        .fill(heroBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.46)

                    VStack(spacing: 20) {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(brand.opacity(0.10))
                                .frame(width: 130, height: 130)
                            Circle()
                                .fill(brand.opacity(0.16))
                                .frame(width: 100, height: 100)
                            Circle()
                                .fill(brand)
                                .frame(width: 80, height: 80)
                                .shadow(color: brand.opacity(0.30), radius: 18, x: 0, y: 8)
                            Image(systemName: page.icon)
                                .glowzaFont(size: 34, weight: .medium)
                                .foregroundColor(.white)
                        }

                        // Badge
                        Label(page.badge, systemImage: "checkmark.seal.fill")
                            .glowzaFont(size: 12, weight: .semibold)
                            .foregroundColor(brand)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(brand.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }
                .scaleEffect(heroScale)
                .opacity(heroOpacity)
                .clipShape(RoundedRectangle(cornerRadius: 0))

                // ── Text block ──
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(page.titleLine1)
                            .glowzaFont(size: 18, weight: .semibold)
                            .foregroundColor(appSettings.themeText)

                        Text(page.titleLine2)
                            .glowzaFont(size: 18, weight: .semibold)
                            .foregroundColor(brand)
                    }

                    Text(page.subtitle)
                        .glowzaFont(size: 15)
                        .foregroundColor(Color(hex: "8E8E93"))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 28)
                .padding(.horizontal, 28)
                .offset(y: txtOffset)
                .opacity(txtOpacity)

                Spacer()

                // ── CTA button ──
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Text(isLast ? "Get Started" : "Continue")
                            .glowzaFont(size: 15, weight: .semibold)
                        Image(systemName: isLast ? "sparkles" : "arrow.right")
                            .glowzaFont(size: 13, weight: .semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 330, height: 55)
                    .background(hotPink)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 52)
                .offset(y: txtOffset)
                .opacity(txtOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                heroScale = 1; heroOpacity = 1
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.12)) {
                txtOffset = 0; txtOpacity = 1
            }
        }
        .onChange(of: page.id) { _, _ in
            heroScale = 0.85; heroOpacity = 0
            txtOffset = 28; txtOpacity = 0
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                heroScale = 1; heroOpacity = 1
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.12)) {
                txtOffset = 0; txtOpacity = 1
            }
        }
    }
}

#Preview { OnboardingView() }
