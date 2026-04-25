import SwiftUI

// MARK: - Glowza Design Tokens (Also defined in ThemeColors.swift for centralization)
// Keep these for backward compatibility if needed, but prefer ThemeColors.swift

// MARK: - View Extensions
extension View {
    /// Applies the standard Glowza card style
    func glowzaCard(radius: CGFloat = 16) -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    /// Applies the standard Glowza screen background (white)
    func glowzaBackground() -> some View {
        self.background(Color.white.ignoresSafeArea())
    }
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

