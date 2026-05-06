import SwiftUI

// MARK: - Theme Helper
struct ThemeHelper {
    @Environment(AppSettings.self) static var settings
    
    /// Background color that adapts to theme
    static func backgroundColor(_ colorScheme: ColorScheme?) -> Color {
        return Color.white
    }
    
    /// Card/Surface color for theme
    static func surfaceColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color(hex: "1A1A1A")  // Slightly lighter black
        }
        return Color.white  // Pure white
    }
    
    /// Text color for theme
    static func textColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color.white
        }
        return Color.black
    }
    
    /// Tertiary text color for theme
    static func tertiaryTextColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.6)
        }
        return Color.black.opacity(0.6)
    }
    
    /// Border color based on theme
    static func borderColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.15)
        }
        return Color.black.opacity(0.1)
    }
}

// MARK: - View Extensions for Dynamic Colors
extension View {
    /// Apply background color that respects theme
    func themeBackground(_ colorScheme: ColorScheme?) -> some View {
        self.background(ThemeHelper.backgroundColor(colorScheme))
    }
    
    /// Get appropriate foreground color for theme
    func themeForeground(_ colorScheme: ColorScheme?) -> some View {
        self.foregroundColor(ThemeHelper.textColor(colorScheme))
    }
}
