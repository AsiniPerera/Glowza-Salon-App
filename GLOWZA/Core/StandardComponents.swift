import SwiftUI

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
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(title)
                    .font(Typography.headline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .foregroundColor(.white)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.glowzaGold, Color.glowzaGoldDark]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(CornerRadius.lg)
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.glowzaGoldDark)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color.glowzaGold.opacity(0.12))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Standard Search Bar
struct StandardSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSearch: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.glowzaTextDisabled)
            
            TextField(placeholder, text: $text)
                .font(Typography.body)
                .submitLabel(.search)
                .onSubmit { onSearch?() }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.glowzaTextDisabled)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 44)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Standard Badge
struct StandardBadge: View {
    let title: String
    var backgroundColor: Color = .glowzaGold
    var textColor: Color = .white
    
    var body: some View {
        Text(title)
            .font(Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.xs)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.full)
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
        HStack(spacing: Spacing.base) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title2)
                    .foregroundColor(.glowzaTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(.glowzaSubtext)
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text("See All")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.glowzaGoldDark)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Rating View
struct RatingView: View {
    let rating: Double
    var size: CGFloat = 16
    var spacing: CGFloat = 4
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(index <= Int(rating) ? .glowzaGold : .glowzaTextDisabled)
            }
        }
    }
}

// MARK: - Location Chip
struct LocationChip: View {
    let location: String
    let distance: String?
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.glowzaGoldDark)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(location)
                    .font(Typography.caption)
                    .foregroundColor(.glowzaTextPrimary)
                
                if let distance = distance {
                    Text(distance)
                        .font(Typography.caption2)
                        .foregroundColor(.glowzaSubtext)
                }
            }
            
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.glowzaCardBg.opacity(0.6))
        .cornerRadius(CornerRadius.base)
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
                .font(Typography.bodySmall)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : .glowzaBrown)
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.sm)
                .background(
                    isSelected
                    ? LinearGradient(
                        gradient: Gradient(colors: [Color.glowzaGold, Color.glowzaGoldDark]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.white]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(CornerRadius.full)
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.glowzaGold.opacity(0.3),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? Color.glowzaGold.opacity(0.25) : Color.clear,
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
    }
}
