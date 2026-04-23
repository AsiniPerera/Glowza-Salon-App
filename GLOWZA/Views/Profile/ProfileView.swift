import SwiftUI

// MARK: - ProfileView
struct ProfileView: View {
    @State private var showSignOutAlert = false

    // Design tokens matching reference
    private let bg        = Color(hex: "F5EDE8")
    private let card      = Color.white
    private let primary   = Color(hex: "1A1A1A")
    private let secondary = Color(hex: "9A8A82")
    private let accent    = Color(hex: "8B5533")   // warm terracotta-brown

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    heroCard
                    personalDetailsCard
                    beautyPreferencesCard
                    skinConcernsCard
                    paymentMethodCard
                    loyaltyPointsCard
                    quickLinksGrid

                    Button(action: { showSignOutAlert = true }) {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accent)
                    }
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .background(bg.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(primary)
                }
            }
        }
        .alert("Log Out", isPresented: $showSignOutAlert) {
            Button("Log Out", role: .destructive) {
                NotificationCenter.default.post(name: .glowzaSignOut, object: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out of your account?")
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        HStack(alignment: .center, spacing: 16) {
            // Circular avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "E8C9B8"))
                    .frame(width: 82, height: 82)
                Image(systemName: "person.fill")
                    .font(.system(size: 38))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 5) {
                // Name + PRO badge
                HStack(alignment: .center, spacing: 8) {
                    Text("Alina Sharma")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(primary)
                    Text("PRO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(6)
                }

                HStack(spacing: 5) {
                    Image(systemName: "shield")
                        .font(.system(size: 12))
                        .foregroundColor(accent)
                    Text("Glowza Pro Member")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accent)
                }

                Text("Member since May 2024")
                    .font(.system(size: 12))
                    .foregroundColor(secondary)

                Button(action: {}) {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Edit Profile")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(20)
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(16)
        .background(card)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Personal Details
    private var personalDetailsCard: some View {
        profileCard(icon: "person", title: "Personal Details", linkLabel: "View all") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    infoCell(icon: "envelope", text: "alina.sharma@gmail.com")
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(secondary)
                            Text("Date of Birth")
                                .font(.system(size: 12))
                                .foregroundColor(secondary)
                        }
                        Text("12 May 1993")
                            .font(.system(size: 13))
                            .foregroundColor(primary)
                            .padding(.leading, 18)
                    }
                }
                infoCell(icon: "phone", text: "+91 98765 43210")
            }
        }
    }

    // MARK: - Beauty Preferences
    private var beautyPreferencesCard: some View {
        profileCard(icon: "sparkles", title: "Beauty Preferences", linkLabel: "View all") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                prefCell(icon: "scissors",               label: "Hair",              value: "Straight, Medium")
                prefCell(icon: "sun.max",                label: "Skin Type",         value: "Combination")
                prefCell(icon: "paintpalette",           label: "Skin Tone",         value: "Light - Medium")
                prefCell(icon: "clock",                  label: "Preferred Services",value: "HydraFacial, Laser, Facials")
            }
        }
    }

    // MARK: - Skin Concerns
    private var skinConcernsCard: some View {
        profileCard(icon: "face.smiling", title: "Skin Concerns", linkLabel: "View all") {
            ProfileFlowLayout(spacing: 8) {
                ForEach(["Dullness", "Acne Marks", "Uneven Tone", "Dark Spots"], id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13))
                        .foregroundColor(primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "DDD0C8"), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Saved Payment Method
    private var paymentMethodCard: some View {
        profileCard(icon: "creditcard", title: "Saved Payment Method", linkLabel: "Manage") {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "EEF2FF"))
                    .frame(width: 52, height: 34)
                    .overlay(
                        Text("VISA")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "1A3CC8"))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Visa ending in 4242")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primary)
                    Text("Expires 09/26")
                        .font(.system(size: 12))
                        .foregroundColor(secondary)
                }

                Spacer()

                Text("Default")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "3A9E5A"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(hex: "E6F5EC"))
                    .cornerRadius(20)
            }
        }
    }

    // MARK: - Loyalty Points
    private var loyaltyPointsCard: some View {
        profileCard(icon: "star", title: "Loyalty Points", linkLabel: "View Details") {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFF0EC"))
                        .frame(width: 48, height: 48)
                    Image(systemName: "star")
                        .font(.system(size: 20))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("1,280")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(primary)
                        Text("Points")
                            .font(.system(size: 14))
                            .foregroundColor(secondary)
                    }
                    Text("Redeem your points on services & products")
                        .font(.system(size: 12))
                        .foregroundColor(secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(action: {}) {
                    Text("Redeem Points")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color(hex: "F5EDE8"))
                        .cornerRadius(20)
                }
            }
        }
    }

    // MARK: - Quick Links 2×2 Grid
    private var quickLinksGrid: some View {
        let links: [(String, String, String)] = [
            ("calendar.badge.clock", "Booking History",  "View your past & upcoming appointments"),
            ("heart",                "Saved Salons",      "Your favorite salons at your fingertips"),
            ("doc.text",             "Receipts",          "View and download your receipts"),
            ("headphones",           "Help & Support",    "Get help, faqs and contact support"),
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(links, id: \.1) { icon, title, subtitle in
                Button(action: {}) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(primary)
                                .multilineTextAlignment(.leading)
                            Text(subtitle)
                                .font(.system(size: 11))
                                .foregroundColor(secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(card)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Card Container
    private func profileCard<Content: View>(
        icon: String,
        title: String,
        linkLabel: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accent)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primary)
                Spacer()
                Button(action: {}) {
                    Text(linkLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accent)
                }
            }
            content()
        }
        .padding(16)
        .background(card)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Info Cell
    private func infoCell(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(secondary)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(primary)
        }
    }

    // MARK: - Pref Cell
    private func prefCell(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(primary)
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Flow Layout for tag pills
struct ProfileFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0; y += rowH + spacing; rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX; y += rowH + spacing; rowH = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}

// MARK: - Sign Out Notification
extension Notification.Name {
    static let glowzaSignOut = Notification.Name("GlowzaSignOut")
}

#Preview {
    ProfileView()
}

