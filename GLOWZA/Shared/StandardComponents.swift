import SwiftUI

// MARK: - Brand Colors (quick access)
private var brand: Color { Color.glowzaPrimary }
private let brandDark = Color(hex: "8A1538")
private let brandTint = Color(hex: "FFF0F4")

// MARK: - Standard Card
struct StandardCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = CornerRadius.base

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.glowzaCardBg)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Primary Button (hot pink)
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    private let hotPink = Color(hex: "962043")

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .glowzaFont(size: 15, weight: .semibold)
                }
            }
            .frame(width: 330, height: 55)
            .foregroundColor(.white)
            .background(
                (isDisabled || isLoading) ? Color(hex: "D4829E") : hotPink
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - Secondary Button (hot pink outline)
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    private let hotPink = Color(hex: "962043")

    var body: some View {
        Button(action: action) {
            Text(title)
                .glowzaFont(size: 15, weight: .semibold)
                .foregroundColor(hotPink)
                .frame(width: 330, height: 55)
                .background(Color.glowzaCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(hotPink, lineWidth: 1.5)
                    )
        }
    }
}

// MARK: - Standard Search Bar
struct StandardSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSearch: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .glowzaFont(size: 14, weight: .medium)
                .foregroundColor(Color(hex: "ABABAB"))

            TextField(placeholder, text: $text)
                .glowzaFont(size: 15)
                .submitLabel(.search)
                .onSubmit { onSearch?() }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .glowzaFont(size: 15)
                        .foregroundColor(Color(hex: "ABABAB"))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.glowzaCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Standard Badge
struct StandardBadge: View {
    let title: String
    var backgroundColor: Color = Color(hex: "962043")
    var textColor: Color = .white

    var body: some View {
        Text(title)
            .glowzaFont(size: 11, weight: .semibold)
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?

    init(_ title: String, subtitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .glowzaFont(size: 20, weight: .bold)
                    .foregroundColor(Color(hex: "1A1A1A"))
                if let subtitle {
                    Text(subtitle)
                        .glowzaFont(size: 13)
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
            }
            Spacer()
            if let action {
                Button(action: action) {
                    Text("See All")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(brand)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Rating Stars View
struct RatingView: View {
    let rating: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: Double(i) <= rating ? "star.fill" : (Double(i) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .glowzaFont(size: size)
                    .foregroundColor(Double(i) <= rating ? Color(hex: "F59E0B") : Color(hex: "DCDCDC"))
            }
        }
    }
}

// MARK: - Location Chip
struct LocationChip: View {
    let location: String
    let distance: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .glowzaFont(size: 13)
                .foregroundColor(brand)
            VStack(alignment: .leading, spacing: 0) {
                Text(location)
                    .glowzaFont(size: 13)
                    .foregroundColor(Color(hex: "1A1A1A"))
                if let distance {
                    Text(distance)
                        .glowzaFont(size: 11)
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color.glowzaCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .glowzaFont(size: 13, weight: isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : Color(hex: "1A1A1A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? brand : Color.glowzaCardBg)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.glowzaBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Glowza Text Field
struct GlowzaTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var icon: String? = nil

    @State private var showPassword = false
    private var appSettings: AppSettings { AppSettings.shared }

    var body: some View {
        let isHC = appSettings.isHighContrast
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .glowzaFont(size: 16)
                    .foregroundColor(appSettings.themeTextSecondary)
                    .frame(width: 20)
            }
            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .glowzaFont(size: 15)
                    .foregroundColor(appSettings.themeText)
            } else {
                TextField(placeholder, text: $text)
                    .glowzaFont(size: 15)
                    .keyboardType(keyboardType)
                    .foregroundColor(appSettings.themeText)
            }
            if isSecure {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .glowzaFont(size: 15)
                        .foregroundColor(appSettings.themeTextSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(isHC ? appSettings.themeRaised : Color(hex: "F8F8F8"))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(appSettings.themeElementBorder,
                        lineWidth: isHC ? 3 : 1)
        )
    }
}

// MARK: - Divider
struct GlowzaDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.glowzaBorder)
            .frame(height: 1)
            .padding(.horizontal, 20)
    }
}
