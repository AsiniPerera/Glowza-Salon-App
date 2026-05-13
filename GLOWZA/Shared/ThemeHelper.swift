import SwiftUI

// MARK: - Theme Helper
// This struct provides helper methods to get colors based on the current ColorScheme (Light/Dark)!
// Note: AppSettings has more comprehensive theme helpers that also support High Contrast mode.
struct ThemeHelper {
    static var settings: AppSettings { AppSettings.shared }
    
    /// Background color that adapts to theme!
    static func backgroundColor(_ colorScheme: ColorScheme?) -> Color {
        return Color.white // Currently hardcoded to white!
    }
    
    /// Card/Surface color for theme!
    static func surfaceColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color(hex: "1A1A1A")  // Slightly lighter black for dark mode!
        }
        return Color.white  // Pure white for light mode!
    }
    
    /// Text color for theme!
    static func textColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color.white
        }
        return Color.black
    }
    
    /// Tertiary text color for theme!
    static func tertiaryTextColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.6)
        }
        return Color.black.opacity(0.6)
    }
    
    /// Border color based on theme!
    static func borderColor(_ colorScheme: ColorScheme?) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.15)
        }
        return Color.black.opacity(0.1)
    }
}

// MARK: - View Extensions for Dynamic Colors
// Extensions to make applying theme colors easier in views!
extension View {
    /// Apply background color that respects theme!
    func themeBackground(_ colorScheme: ColorScheme?) -> some View {
        self.background(ThemeHelper.backgroundColor(colorScheme))
    }
    
    /// Get appropriate foreground color for theme!
    func themeForeground(_ colorScheme: ColorScheme?) -> some View {
        self.foregroundColor(ThemeHelper.textColor(colorScheme))
    }
}
