import SwiftUI

// MARK: - Glowza Design Tokens (Also defined in ThemeColors.swift for centralization)
// Keep these for backward compatibility if needed, but prefer ThemeColors.swift

// MARK: - View Extensions
extension View {
    /// Applies the standard Glowza card style
    func glowzaCard(radius: CGFloat = 16) -> some View {
        let isHighContrast = UserDefaults.standard.bool(forKey: "app_highContrast")
        return self
            .background(isHighContrast ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(isHighContrast ? 1.0 : 0), lineWidth: isHighContrast ? 3 : 0)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    /// Applies the standard Glowza screen background
    func glowzaBackground() -> some View {
        self.background(Color.glowzaBackground.ignoresSafeArea())
    }

    /// Applies a global neon high-contrast style when enabled.
    func glowzaHighContrastStyle(enabled: Bool) -> some View {
        self
            .tint(enabled ? Color(hex: "FF66B2") : Color.glowzaPrimary)
            .foregroundStyle(enabled ? Color.white : Color.primary)
            .background((enabled ? Color.black : Color.clear).ignoresSafeArea())
    }
}

// MARK: - Global Button Style
struct GlowzaRoundedButtonStyle: ButtonStyle {
    @Environment(\.isHighContrast) private var isHighContrast

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(Color.white.opacity(isHighContrast ? 1.0 : 0), lineWidth: isHighContrast ? 3 : 0)
            )
            .opacity(configuration.isPressed ? 0.92 : 1.0)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let glowzaSignOut = Notification.Name("glowzaSignOut")
    static let glowzaProfileUpdated = Notification.Name("glowzaProfileUpdated")
    static let glowzaSalonsUpdated = Notification.Name("glowzaSalonsUpdated")
    static let glowzaQuickBookRequested = Notification.Name("glowzaQuickBookRequested")
    static let glowzaGoToHomeTab = Notification.Name("glowzaGoToHomeTab")
    static let glowzaGoToBookingsTab = Notification.Name("glowzaGoToBookingsTab")
    static let glowzaShowUpcomingBookings = Notification.Name("glowzaShowUpcomingBookings")
}

// MARK: - Double Formatting
extension Double {
    var ratingFormatted: String { String(format: "%.1f", self) }
}

// MARK: - Date Extensions
extension Date {
    var timeFormatted: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: self)
    }

    var dayMonth: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: self)
    }
}

