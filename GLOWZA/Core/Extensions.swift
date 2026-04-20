import SwiftUI

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Glowza Design Tokens
extension Color {
    static let glowzaBackground = Color(hex: "F5F0E8")
    static let glowzaGold       = Color(hex: "E5A820")
    static let glowzaGoldDark   = Color(hex: "C8860A")
    static let glowzaDark       = Color(hex: "1A1A1A")
    static let glowzaCardBg     = Color(hex: "F0E6D2")
    static let glowzaSubtext    = Color(hex: "8A8A8A")
    static let glowzaBrown      = Color(hex: "4A3828")
}

// MARK: - View Extensions
extension View {
    /// Applies the standard Glowza card style
    func glowzaCard(radius: CGFloat = 16) -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    /// Applies the standard Glowza screen background
    func glowzaBackground() -> some View {
        self.background(Color.glowzaBackground.ignoresSafeArea())
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
