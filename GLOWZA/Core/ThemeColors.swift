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

// MARK: - Spacing Constants
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let base: CGFloat = 16
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius Constants
struct CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let base: CGFloat = 12
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 30
}

// MARK: - Typography
struct Typography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let headlineSmall = Font.system(size: 15, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)
    static let callout = Font.system(size: 14, weight: .semibold)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let caption2 = Font.system(size: 12, weight: .regular)
    static let overline = Font.system(size: 11, weight: .semibold)
}

// MARK: - Shadow Styles
struct ShadowStyle {
    static let small = (radius: CGFloat(4), yOffset: CGFloat(2))
    static let medium = (radius: CGFloat(8), yOffset: CGFloat(4))
    static let large = (radius: CGFloat(12), yOffset: CGFloat(6))
}

// MARK: - Color Extensions
extension Color {
    // Primary Colors
    static let glowzaGold = Color(hex: "E5A820")
    static let glowzaGoldDark = Color(hex: "C8860A")
    static let glowzaBrown = Color(hex: "4A3828")
    
    // Neutral Colors
    static let glowzaBackground = Color(hex: "F5F0E8")
    static let glowzaSurface = Color.white
    static let glowzaCardBg = Color(hex: "F0E6D2")
    
    // Text Colors
    static let glowzaTextPrimary = Color(hex: "1A1A1A")
    static let glowzaTextSecondary = Color(hex: "5E5E5E")
    static let glowzaSubtext = Color(hex: "8A8A8A")
    static let glowzaTextDisabled = Color(hex: "ABABAB")
    
    // Border / Divider
    static let glowzaBorder = Color(hex: "E0D5C5")

    // State Colors
    static let glowzaSuccess = Color(hex: "4CAF50")
    static let glowzaWarning = Color(hex: "FF9800")
    static let glowzaError = Color(hex: "F44336")
    static let glowzaInfo = Color(hex: "2196F3")
}
