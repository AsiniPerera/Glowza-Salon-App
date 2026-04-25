import SwiftUI

// MARK: - Brand Colors (quick access)
private let brand = Color(hex: "AF1C47")
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
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Primary Button (rose fill)
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundColor(.white)
            .background(
                (isDisabled || isLoading) ? Color(hex: "BEBEBE") : brand
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - Secondary Button (rose outline)
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(brand)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(brandTint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(brand.opacity(0.3), lineWidth: 1)
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "ABABAB"))

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .submitLabel(.search)
                .onSubmit { onSearch?() }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "ABABAB"))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color(hex: "F5F5F5"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Standard Badge
struct StandardBadge: View {
    let title: String
    var backgroundColor: Color = .glowzaPrimary
    var textColor: Color = .white

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
            }
            Spacer()
            if let action {
                Button(action: action) {
                    Text("See All")
                        .font(.system(size: 14, weight: .semibold))
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
                    .font(.system(size: size))
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
                .font(.system(size: 13))
                .foregroundColor(brand)
            VStack(alignment: .leading, spacing: 0) {
                Text(location)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "1A1A1A"))
                if let distance {
                    Text(distance)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "F9F9F9"))
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
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color(hex: "1A1A1A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? brand : Color(hex: "F5F5F5"))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color(hex: "EBEBEB"), lineWidth: 1)
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

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "ABABAB"))
                    .frame(width: 20)
            }
            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 15))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .keyboardType(keyboardType)
            }
            if isSecure {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "ABABAB"))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(hex: "F8F8F8"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "EBEBEB"), lineWidth: 1)
        )
    }
}

// MARK: - Divider
struct GlowzaDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "F0F0F0"))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }
}
