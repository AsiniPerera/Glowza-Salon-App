import SwiftUI

// MARK: - High Contrast environment key
struct HighContrastKey: EnvironmentKey {
	static let defaultValue = false
}

extension EnvironmentValues {
	var isHighContrast: Bool {
		get { self[HighContrastKey.self] }
		set { self[HighContrastKey.self] = newValue }
	}
}

// MARK: - App-wide Settings (Observable singleton injected via environment)
@Observable
final class AppSettings {

	static let shared = AppSettings()

	var isDarkMode: Bool {
		didSet { UserDefaults.standard.set(isDarkMode, forKey: "app_darkMode") }
	}

	var isHighContrast: Bool {
		didSet { UserDefaults.standard.set(isHighContrast, forKey: "app_highContrast") }
	}

	private init() {
		isDarkMode = UserDefaults.standard.bool(forKey: "app_darkMode")
		isHighContrast = UserDefaults.standard.bool(forKey: "app_highContrast")
	}

	/// The color scheme to apply (.dark / .light / nil = system)
	var colorScheme: ColorScheme? {
		isDarkMode ? .dark : .light
	}
}
