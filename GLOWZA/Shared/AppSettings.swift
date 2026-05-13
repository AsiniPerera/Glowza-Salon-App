import SwiftUI
import AVFoundation

// MARK: - App Font Size

// This enum defines the available font size steps in the app!
// It conforms to String so we can save its raw value to UserDefaults.
enum GlowzaFontSize: String, CaseIterable, Equatable {
    case small      = "small"
    case normal     = "normal"
    case large      = "large"
    case extraLarge = "xl"

    // Human-readable labels!
    var label: String {
        switch self {
        case .small:      return "Small"
        case .normal:     return "Normal"
        case .large:      return "Large"
        case .extraLarge: return "XL"
        }
    }

    // Letter size used in the profile picker preview bubble!
    var previewFontSize: CGFloat {
        switch self {
        case .small:      return 12
        case .normal:     return 16
        case .large:      return 20
        case .extraLarge: return 25
        }
    }

    // Scale factor applied to all fixed-size fonts app-wide!
    var fontMultiplier: CGFloat {
        switch self {
        case .small:      return 0.85
        case .normal:     return 1.0
        case .large:      return 1.15
        case .extraLarge: return 1.35
        }
    }

    // Maps our custom sizes to SwiftUI's system DynamicTypeSize!
    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small:      return .small
        case .normal:     return .large       // iOS system default!
        case .large:      return .xLarge
        case .extraLarge: return .xxLarge
        }
    }
}

// MARK: - High Contrast environment key
// This allows us to pass the high-contrast boolean down the SwiftUI environment tree!
struct HighContrastKey: EnvironmentKey {
	static let defaultValue = false
}

// Extend EnvironmentValues to make our custom key accessible!
extension EnvironmentValues {
	var isHighContrast: Bool {
		get { self[HighContrastKey.self] }
		set { self[HighContrastKey.self] = newValue }
	}
}

// MARK: - App-wide Settings
// Observable singleton that holds all accessibility and theme settings.
// Views can observe this and update automatically when settings change!
@Observable
final class AppSettings {

	static let shared = AppSettings() // Singleton instance!

    // Each property uses didSet to save changes to UserDefaults immediately!
	var isDarkMode: Bool {
		didSet { UserDefaults.standard.set(isDarkMode, forKey: "app_darkMode") }
	}

	var isHighContrast: Bool {
		didSet { UserDefaults.standard.set(isHighContrast, forKey: "app_highContrast") }
	}

	var fontSizeScale: GlowzaFontSize {
		didSet { UserDefaults.standard.set(fontSizeScale.rawValue, forKey: "app_fontSizeScale") }
	}

	var isVoiceOverEnabled: Bool {
		didSet { UserDefaults.standard.set(isVoiceOverEnabled, forKey: "app_voiceOverEnabled") }
	}

    // Used to speak text aloud for accessibility!
	private let synthesizer = AVSpeechSynthesizer()

	func speak(_ text: String) {
		guard isVoiceOverEnabled else { return }
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
		synthesizer.speak(utterance)
	}

	// Convenience: current scale factor for font sizing.
	var fontMultiplier: CGFloat { fontSizeScale.fontMultiplier }

	private init() {
        // Load saved settings from UserDefaults on app launch!
		isDarkMode      = UserDefaults.standard.bool(forKey: "app_darkMode")
		isHighContrast  = UserDefaults.standard.bool(forKey: "app_highContrast")
		isVoiceOverEnabled = UserDefaults.standard.bool(forKey: "app_voiceOverEnabled")
		fontSizeScale   = GlowzaFontSize(rawValue: UserDefaults.standard.string(forKey: "app_fontSizeScale") ?? "") ?? .normal
	}

	// The color scheme to apply (forces dark in high contrast mode!).
	var colorScheme: ColorScheme? {
		(isHighContrast || isDarkMode) ? .dark : .light
	}

	// MARK: - Theme Helpers
    // These compute properties return different colors based on the current mode!
    // This allows us to use dynamic colors without hardcoding them in views.

	// OLED black page / window background
	var themePage: Color {
		isHighContrast ? .black :
		isDarkMode     ? Color(hex: "0A0A0A") : .white
	}

	// Card and sheet surface — ultra-dark glass in HC
	var themeSurface: Color {
		isHighContrast ? Color(hex: "0D0D0D") :
		isDarkMode     ? Color(hex: "1A1A1A") : .white
	}

	// Raised chip / bubble / text-field background
	var themeRaised: Color {
		isHighContrast ? Color(hex: "1A1A1A") :
		isDarkMode     ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")
	}

	// Primary text — crisp white in HC / dark, near-black in light
	var themeText: Color {
		(isHighContrast || isDarkMode) ? .white : Color(hex: "1A1A1A")
	}

	// Secondary / subdued text
	var themeTextSecondary: Color {
		isHighContrast ? .white.opacity(0.70) :
		isDarkMode     ? .white.opacity(0.60) : Color(hex: "8A8E95")
	}

	// Subtle divider line
	var themeDivider: Color {
		isHighContrast ? Color(hex: "FF2D55").opacity(0.25) :
		isDarkMode     ? .white.opacity(0.10) : Color(hex: "E5E5EA")
	}

	// Neon border stroke (3 px) for HC cards / inputs
	var themeBorder: Color {
		isHighContrast ? Color(hex: "FF2D55").opacity(0.60) :
		isDarkMode     ? .white.opacity(0.12) : Color(hex: "E5E5EA")
	}

	// White 3 px border for interactive input elements in HC (text fields, form rows)
	var themeElementBorder: Color {
		isHighContrast ? .white.opacity(0.85) :
		isDarkMode     ? .white.opacity(0.15) : Color(hex: "E5E5EA")
	}

	// Glassmorphism pink tint overlay (very subtle, only in HC)
	var themeGlassOverlay: Color {
		isHighContrast ? Color(hex: "FF2D55").opacity(0.04) : .clear
	}

	// Brand / accent / CTA — Electric Rose in HC, deep rose normally
	var themeBrand: Color {
		isHighContrast ? Color(hex: "FF2D55") : Color(hex: "962043")
	}

	// Muted / disabled brand
	var themeBrandMuted: Color {
		isHighContrast ? Color(hex: "FF2D55").opacity(0.45) : Color(hex: "D4829E")
	}
}
