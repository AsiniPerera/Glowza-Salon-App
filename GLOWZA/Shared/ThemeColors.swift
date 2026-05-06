import SwiftUI

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
        let effectiveHex = Color.highContrastRemappedHexIfNeeded(cleaned)
        var int: UInt64 = 0
        Scanner(string: effectiveHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch effectiveHex.count {
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

    private static func highContrastRemappedHexIfNeeded(_ hex: String) -> String {
        guard UserDefaults.standard.bool(forKey: "app_highContrast") else {
            return hex
        }

        let neon = "FF66B2"

        // Brand and action colors become neon pink.
        let brandLike: Set<String> = [
            "962043", "8A1538", "D4829E", "E5A820", "C8860A", "4A3828", "F5E8EE",
            "F59E0B", "DB4437", "1877F2", "2196F3", "4CAF50", "FF9800", "F44336", "00A878"
        ]
        if brandLike.contains(hex) {
            return neon
        }

        // Light surfaces become black for high contrast base.
        let lightSurfaces: Set<String> = [
            "FFFFFF", "FAFAFA", "F8F8F8", "F2F2F7", "EBEBEB", "E5E5EA", "E8E8EC", "FFF0F4", "F0F0F0"
        ]
        if lightSurfaces.contains(hex) {
            return "000000"
        }

        // Common text grays become white for readability.
        let textLike: Set<String> = [
            "1A1A1A", "1C1C1E", "1F2126", "3A3A3C", "5A5D65", "5E5E5E", "8A8A8A", "8A8D94",
            "8E8E93", "9A9A9F", "ABABAB", "C7C7CC"
        ]
        if textLike.contains(hex) {
            return "FFFFFF"
        }

        return hex
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
    private static var neonHighContrastEnabled: Bool {
        UserDefaults.standard.bool(forKey: "app_highContrast")
    }

    // Brand Colors
    static var glowzaPrimary: Color { neonHighContrastEnabled ? Color(hex: "FF66B2") : Color(hex: "962043") }
    static var glowzaPrimaryTint: Color { neonHighContrastEnabled ? .black : Color(hex: "F5E8EE") }

    // Primary Colors
    static var glowzaGold: Color { neonHighContrastEnabled ? Color(hex: "FF66B2") : Color(hex: "E5A820") }
    static var glowzaGoldDark: Color { neonHighContrastEnabled ? Color(hex: "FF66B2") : Color(hex: "C8860A") }
    static var glowzaBrown: Color { neonHighContrastEnabled ? .white : Color(hex: "4A3828") }
    
    // Neutral Colors
    static var glowzaBackground: Color { neonHighContrastEnabled ? .black : .white }
    static var glowzaSurface: Color { neonHighContrastEnabled ? .black : .white }
    static var glowzaCardBg: Color { neonHighContrastEnabled ? .black : .white }
    
    // Text Colors
    static var glowzaTextPrimary: Color { neonHighContrastEnabled ? .white : Color(hex: "1A1A1A") }
    static var glowzaTextSecondary: Color { neonHighContrastEnabled ? .white.opacity(0.92) : Color(hex: "5E5E5E") }
    static var glowzaSubtext: Color { neonHighContrastEnabled ? .white.opacity(0.78) : Color(hex: "8A8A8A") }
    static var glowzaTextDisabled: Color { neonHighContrastEnabled ? .white.opacity(0.55) : Color(hex: "ABABAB") }
    
    // Border / Divider
    static var glowzaBorder: Color { neonHighContrastEnabled ? .white : Color(hex: "EBEBEB") }

    // Brand CTA
    static var hotPink: Color { neonHighContrastEnabled ? Color(hex: "FF66B2") : Color(hex: "962043") }
    static var hotPinkDisabled: Color { neonHighContrastEnabled ? Color(hex: "FF66B2").opacity(0.55) : Color(hex: "D4829E") }

    // State Colors
    static let glowzaSuccess = Color(hex: "4CAF50")
    static let glowzaWarning = Color(hex: "FF9800")
    static let glowzaError = Color(hex: "F44336")
    static let glowzaInfo = Color(hex: "2196F3")
}

// MARK: - High Contrast View Modifier
/// Increases visual contrast when the user enables High Contrast Mode in Profile Settings.
/// Applies heavier font weight and stronger border strokes to any view it wraps.
struct HighContrastModifier: ViewModifier {
    @Environment(\.isHighContrast) private var isHighContrast

    func body(content: Content) -> some View {
        content
            .bold(isHighContrast)
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(Color.white.opacity(isHighContrast ? 1.0 : 0), lineWidth: isHighContrast ? 3 : 0)
            )
    }
}

extension View {
    /// Apply this to any card / row that should respond to High Contrast Mode.
    func highContrastAware() -> some View {
        modifier(HighContrastModifier())
    }
}
