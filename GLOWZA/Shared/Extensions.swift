import SwiftUI

// MARK: - View Extensions
// Extensions on 'View' allow us to create custom modifiers that can be used on any SwiftUI view!
extension View {
    /// Applies the standard Glowza card style.
    /// In High Contrast: ultra-dark glass (#1A1A1A) + 3 px white border.
    func glowzaCard(radius: CGFloat = 16) -> some View {
        // Read directly from UserDefaults for performance in this modifier!
        let isHC = UserDefaults.standard.bool(forKey: "app_highContrast")
        let rose  = Color(hex: "FF2D55")
        return self
            .background(
                ZStack {
                    if isHC {
                        // Glassmorphism base!
                        Color(hex: "1A1A1A")
                        // Subtle pink glass shimmer!
                        rose.opacity(0.04)
                    } else {
                        Color.white
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                // Add a border for high contrast mode accessibility!
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(isHC ? Color.white.opacity(0.85) : Color.clear,
                            lineWidth: isHC ? 3 : 0)
            )
            .shadow(color: isHC ? Color.white.opacity(0.08) : Color.black.opacity(0.05),
                    radius: isHC ? 12 : 10, x: 0, y: isHC ? 0 : 4)
    }

    /// Applies the standard Glowza screen background!
    func glowzaBackground() -> some View {
        self.background(Color.glowzaBackground.ignoresSafeArea())
    }

    /// Applies OLED-black + Electric Rose high-contrast style when enabled!
    func glowzaHighContrastStyle(enabled: Bool) -> some View {
        self
            .tint(enabled ? Color(hex: "FF2D55") : Color.glowzaPrimary)
            .foregroundStyle(enabled ? Color.white : Color.primary)
            .background((enabled ? Color.black : Color.clear).ignoresSafeArea())
    }
}

// MARK: - Scaled Font ViewModifier
// This custom modifier scales fonts based on the user's preference in AppSettings!
private struct GlowzaScaledFont: ViewModifier {
    private var appSettings: AppSettings { AppSettings.shared }
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        let fontName: String
        // Map SwiftUI weights to custom font file names!
        switch weight {
        case .bold: fontName = "Urbanist-Bold"
        case .semibold: fontName = "Urbanist-SemiBold"
        case .medium: fontName = "Urbanist-Medium"
        case .light: fontName = "Urbanist-Light"
        default: fontName = "Urbanist-Regular"
        }
        
        // Multiply base size by the scale factor from settings!
        // Note: Make sure the "Urbanist" font files are added to your project!
        return content.font(.custom(fontName, size: baseSize * appSettings.fontMultiplier))
    }
}

// Enum to define standardized text sizes across the app!
enum GlowzaTextSize {
    case h1      // 34 (Large Title)
    case h2      // 28 (Title)
    case h3      // 24 (Header)
    case h4      // 20 (Small Title / Subhead)
    case callout // 17 (Buttons)
    case body    // 15 (Body)
    case caption // 12 (Caption)
    
    var size: CGFloat {
        switch self {
        case .h1: return 34
        case .h2: return 28
        case .h3: return 24
        case .h4: return 20
        case .callout: return 17
        case .body: return 15
        case .caption: return 12
        }
    }
}

extension View {
    // Convenience methods to apply the custom font modifier!
    func glowzaFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(GlowzaScaledFont(baseSize: size, weight: weight, design: design))
    }
    
    func glowzaFont(_ style: GlowzaTextSize, weight: Font.Weight = .regular) -> some View {
        glowzaFont(size: style.size, weight: weight)
    }
}

// MARK: - Global Button Styles
// Custom button styles to keep the UI consistent!
struct GlowzaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glowzaFont(.callout, weight: .semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(Color(hex: "962043")) // Brand color!
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            // Add visual feedback when pressed!
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GlowzaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glowzaFont(.callout, weight: .semibold)
            .foregroundColor(Color(hex: "962043"))
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(Color(hex: "962043").opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(Color(hex: "962043").opacity(0.35), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Fallback style used globally!
struct GlowzaRoundedButtonStyle: ButtonStyle {
    @Environment(\.isHighContrast) private var isHighContrast

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(Color(hex: "FF2D55").opacity(isHighContrast ? 0.65 : 0),
                            lineWidth: isHighContrast ? 3 : 0)
            )
            .shadow(color: Color(hex: "FF2D55").opacity(isHighContrast ? 0.25 : 0),
                    radius: isHighContrast ? 8 : 0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
    }
}

extension View {
    /// Adds a 3 px WHITE border overlay on any card/container in HC — maximum contrast for accessibility.
    func hcBorder(radius: CGFloat = 16) -> some View {
        let isHC = UserDefaults.standard.bool(forKey: "app_highContrast")
        return self.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(
                    isHC ? Color.white.opacity(0.85) : Color.clear,
                    lineWidth: isHC ? 3 : 0
                )
        )
    }

    /// Adds a 3 px WHITE border on Capsule-shaped inputs/bars in HC.
    func hcBorderCapsule() -> some View {
        let isHC = UserDefaults.standard.bool(forKey: "app_highContrast")
        return self.overlay(
            Capsule()
                .stroke(
                    isHC ? Color.white.opacity(0.85) : Color.clear,
                    lineWidth: isHC ? 3 : 0
                )
        )
    }
}

// MARK: - Notification Names
// Centralized list of Notification names for app-wide events!
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
    // Formats a rating to 1 decimal place (e.g. 4.5)!
    var ratingFormatted: String { String(format: "%.1f", self) }
}

// MARK: - Date Extensions
extension Date {
    // Formats time (e.g. 10:30 AM)!
    var timeFormatted: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }

    // Formats date (e.g. Oct 23, 2023)!
    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: self)
    }

    // Formats to day and month (e.g. 23 Oct)!
    var dayMonth: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: self)
    }
}

// MARK: - Standard Back Button
// A reusable circle back button used in many custom navigation bars!
struct GlowzaCircleBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "3A3A3C"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "F2F2F7"))
                .clipShape(Circle())
        }
    }
}
// MARK: - Justified Text Support
// Standard SwiftUI Text doesn't support full justification.
// This wrapper uses UIKit's UILabel to achieve a clean, book-like justified look.
struct GlowzaJustifiedText: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor
    let lineSpacing: CGFloat
    var numberOfLines: Int = 0

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = numberOfLines
        label.textAlignment = .justified
        label.lineBreakMode = numberOfLines > 0 ? .byTruncatingTail : .byWordWrapping
        
        // Critical: Ensure the label doesn't resist growing vertically!
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.numberOfLines = numberOfLines
        uiView.lineBreakMode = numberOfLines > 0 ? .byTruncatingTail : .byWordWrapping
        uiView.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 48
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.hyphenationFactor = 1.0 

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        uiView.attributedText = NSAttributedString(string: text, attributes: attributes)
        uiView.invalidateIntrinsicContentSize()
    }
}
