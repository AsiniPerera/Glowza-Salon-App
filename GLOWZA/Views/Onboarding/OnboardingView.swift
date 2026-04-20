import SwiftUI

// MARK: - Onboarding Data Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let badge: String
    let titleLine1: String
    let titleLine2: String
    let subtitle: String
}

// MARK: - Main Onboarding View
struct OnboardingView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "onboarding1",
            badge: "Expert Care",
            titleLine1: "Meet Your",
            titleLine2: "Expert Stylist",
            subtitle: "Our curated team of professionals is dedicated to bringing your unique vision to life with precision and luxury."
        ),
        OnboardingPage(
            imageName: "onboarding2",
            badge: "Smart Search",
            titleLine1: "Find Salons",
            titleLine2: "Near You",
            subtitle: "Discover top-rated clinics on an interactive map, filtered by services, distance, and reputation scores."
        ),
        OnboardingPage(
            imageName: "onboarding3",
            badge: "Privacy First",
            titleLine1: "AI Analysis,",
            titleLine2: "Zero Cloud",
            subtitle: "Our on-device AI analyzes your skin and suggests clinical treatments — your photos never leave your device."
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "FDF8F2").ignoresSafeArea()

            // ── Paged content ──
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

            // ── Page indicators ──
            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentIndex ? Color(hex: "E5A820") : Color.gray.opacity(0.25))
                        .frame(width: i == currentIndex ? 22 : 7, height: 7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentIndex)
                }
            }
            .padding(.bottom, 104) // above the button
        }
    }
}

// MARK: - Single Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLast: Bool
    let onNext: () -> Void

    @State private var imageOpacity: CGFloat = 0
    @State private var contentOffset: CGFloat = 24
    @State private var contentOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            Color(hex: "FDF8F2").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Hero Image ──
                ZStack(alignment: .bottomLeading) {
                    Image(page.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.52)
                        .clipped()
                        .clipShape(DiagonalBottomClip())
                        .opacity(imageOpacity)

                    // Badge over image
                    Label(page.badge, systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "E5A820"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.leading, 24)
                        .padding(.bottom, 28)
                        .opacity(contentOpacity)
                }

                // ── Text Block ──
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(page.titleLine1)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))

                        Text(page.titleLine2)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(hex: "E5A820"))
                    }

                    Text(page.subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "6B6B6B"))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .offset(y: contentOffset)
                .opacity(contentOpacity)

                Spacer()

                // ── Button ──
                Button(action: onNext) {
                    HStack {
                        Text(isLast ? "Get Started" : "Continue")
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Image(systemName: isLast ? "sparkles" : "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(hex: "E5A820").opacity(0.35), radius: 12, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(contentOpacity)
                .offset(y: contentOffset)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                imageOpacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                contentOffset = 0
                contentOpacity = 1
            }
        }
    }
}

// MARK: - Diagonal Clip
struct DiagonalBottomClip: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 46))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    OnboardingView()
}
