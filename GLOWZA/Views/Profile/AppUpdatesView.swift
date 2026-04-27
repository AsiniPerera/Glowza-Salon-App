import SwiftUI

// MARK: - App Updates View
struct AppUpdatesView: View {

    @Environment(\.dismiss) private var dismiss
    private let accent = Color(hex: "962043")

    private let changes: [(version: String, date: String, notes: [String])] = [
        (
            version: "Version 2.1.0",
            date: "April 2026",
            notes: [
                "Complete booking flow with consent form & payment",
                "New treatment comparison view with 10 treatments",
                "Improved AI Beauty Engine skin analysis",
                "Face ID / biometric login support",
                "Profile photo picker & edit profile"
            ]
        ),
        (
            version: "Version 2.0.0",
            date: "March 2026",
            notes: [
                "Redesigned home and salon discovery",
                "Added booking history and cancellation",
                "Dark mode & accessibility improvements",
                "Firebase integration for real-time data"
            ]
        ),
        (
            version: "Version 1.0.0",
            date: "January 2026",
            notes: [
                "Initial launch of GLOWZA",
                "Browse and book salon services",
                "User account creation and authentication"
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Current version hero
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(accent)
                        Text("GLOWZA")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "8A8D94"))
                            .tracking(4)
                        Text("Version 2.1.0")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "1F2126"))
                        Text("You're on the latest version")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "00A878"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.white)

                    VStack(spacing: 20) {
                        ForEach(changes, id: \.version) { release in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(release.version)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "1F2126"))
                                    Spacer()
                                    Text(release.date)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "ABABAB"))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(release.notes, id: \.self) { note in
                                        HStack(alignment: .top, spacing: 10) {
                                            Circle()
                                                .fill(accent)
                                                .frame(width: 5, height: 5)
                                                .padding(.top, 6)
                                            Text(note)
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "5A5D65"))
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
            .navigationTitle("App Updates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(accent)
                }
            }
        }
    }
}

// MARK: - Terms & Conditions View
struct TermsConditionsView: View {

    @Environment(\.dismiss) private var dismiss
    private let accent = Color(hex: "962043")

    private let sections: [(title: String, body: String)] = [
        (
            "1. Acceptance of Terms",
            "By downloading or using GLOWZA, you agree to be bound by these Terms and Conditions. If you disagree with any part, you may not access the service."
        ),
        (
            "2. Use of Service",
            "GLOWZA provides a platform to discover, compare, and book beauty and aesthetic salon services. You must be at least 18 years of age to use this application. You are responsible for maintaining the confidentiality of your account credentials."
        ),
        (
            "3. Bookings & Payments",
            "All bookings made through GLOWZA are subject to availability and confirmation from the salon. Payments are processed securely. Cancellations and refunds are governed by the individual salon's policy."
        ),
        (
            "4. Medical Disclaimer",
            "GLOWZA does not provide medical advice. Treatments offered by partnered salons are cosmetic in nature. Always consult a qualified professional before undergoing any procedure."
        ),
        (
            "5. Privacy Policy",
            "We collect and process personal data in accordance with our Privacy Policy. We do not sell your information to third parties. Profile photos and biometric data remain on your device."
        ),
        (
            "6. Intellectual Property",
            "All content, branding, and technology within GLOWZA is the intellectual property of GLOWZA Pvt Ltd and may not be reproduced without written permission."
        ),
        (
            "7. Limitation of Liability",
            "GLOWZA is not liable for any damages arising from the use of services booked through the platform. We act solely as an intermediary between users and salons."
        ),
        (
            "8. Changes to Terms",
            "We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms."
        ),
        (
            "9. Contact",
            "For questions about these terms, contact us at legal@glowza.lk"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Terms & Conditions")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "1F2126"))
                        Text("Last updated: April 2026")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .background(Color.white)

                    VStack(spacing: 12) {
                        ForEach(sections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(accent)
                                Text(section.body)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "5A5D65"))
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(accent)
                }
            }
        }
    }
}
