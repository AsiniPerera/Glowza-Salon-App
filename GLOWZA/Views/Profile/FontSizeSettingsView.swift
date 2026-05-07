import SwiftUI

// MARK: - Font Size Settings
struct FontSizeSettingsView: View {

    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    /// Local preview state — does NOT touch appSettings until the user taps Save
    @State private var selectedSize: GlowzaFontSize = .normal
    /// Tracks whether the user changed anything so we can animate the Save button
    @State private var hasChanged = false

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Custom nav bar
            HStack(spacing: 0) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(appSettings.themeBrand)
                }
                .frame(minWidth: 70, alignment: .leading)

                Spacer()

                Text("Font Size")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(appSettings.themeText)

                Spacer()

                Button(action: save) {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hasChanged ? appSettings.themeBrand : appSettings.themeTextSecondary)
                }
                .frame(minWidth: 70, alignment: .trailing)
                .disabled(!hasChanged)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Rectangle()
                .fill(appSettings.themeDivider)
                .frame(height: 0.5)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // MARK: Live preview card
                    VStack(alignment: .leading, spacing: 0) {
                        // header strip
                        HStack {
                            Label("Preview", systemImage: "eye.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(appSettings.themeTextSecondary)
                                .textCase(.uppercase)
                                .tracking(0.4)
                            Spacer()
                            Text(selectedSize.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(appSettings.themeBrand)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(appSettings.themeBrand.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Rectangle()
                            .fill(appSettings.themeDivider)
                            .frame(height: 0.5)

                        // Sample text at the chosen size
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Glowza Beauty")
                                .font(.title2.bold())
                                .foregroundColor(appSettings.themeText)

                            Text("Book personalised beauty treatments crafted for your skin type and lifestyle.")
                                .font(.body)
                                .foregroundColor(appSettings.themeText)

                            Text("Trusted by thousands across Sri Lanka.")
                                .font(.subheadline)
                                .foregroundColor(appSettings.themeTextSecondary)
                        }
                        .padding(16)
                        // Apply the preview size only to this content block
                        .environment(\.dynamicTypeSize, selectedSize.dynamicTypeSize)
                        .animation(.spring(duration: 0.3), value: selectedSize)
                    }
                    .background(appSettings.themeSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .hcBorder(radius: 16)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)

                    // MARK: Size option rows
                    VStack(spacing: 0) {
                        ForEach(Array(GlowzaFontSize.allCases.enumerated()), id: \.element) { idx, size in
                            sizeOptionRow(size)

                            if idx < GlowzaFontSize.allCases.count - 1 {
                                Rectangle()
                                    .fill(appSettings.themeDivider)
                                    .frame(height: 0.5)
                                    .padding(.leading, 76)
                            }
                        }
                    }
                    .background(appSettings.themeSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .hcBorder(radius: 16)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)

                    // MARK: Footer note
                    Text("Changes apply across the entire app. Tap Save to confirm, or Back to discard.")
                        .font(.system(size: 12))
                        .foregroundColor(appSettings.themeTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }

            // MARK: Pinned Save & Apply button
            Button(action: save) {
                Text("Save & Apply")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(hasChanged ? .white : appSettings.themeTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(hasChanged ? appSettings.themeBrand : appSettings.themeRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!hasChanged)
            .animation(.easeInOut(duration: 0.2), value: hasChanged)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(appSettings.themePage.ignoresSafeArea())
        .onAppear { selectedSize = appSettings.fontSizeScale }
    }

    // MARK: - Row builder

    private func sizeOptionRow(_ size: GlowzaFontSize) -> some View {
        let isSelected = selectedSize == size
        return Button(action: {
            withAnimation(.spring(duration: 0.25)) {
                selectedSize = size
                hasChanged = (size != appSettings.fontSizeScale)
            }
        }) {
            HStack(spacing: 14) {
                // "A" bubble
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? appSettings.themeBrand : appSettings.themeRaised)
                        .frame(width: 46, height: 46)
                    Text("A")
                        .font(.system(size: size.previewFontSize, weight: .bold))
                        .foregroundColor(isSelected ? .white : appSettings.themeText)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(size.label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(appSettings.themeText)
                    Text(sizeDescription(size))
                        .font(.system(size: 12))
                        .foregroundColor(appSettings.themeTextSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? appSettings.themeBrand : appSettings.themeTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sizeDescription(_ size: GlowzaFontSize) -> String {
        switch size {
        case .small:      return "Compact — fits more content on screen"
        case .normal:     return "Default system text size"
        case .large:      return "Easier to read at a glance"
        case .extraLarge: return "Maximum accessibility size"
        }
    }

    private func save() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appSettings.fontSizeScale = selectedSize
            hasChanged = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { dismiss() }
    }
}

#Preview {
    FontSizeSettingsView()
        .environment(AppSettings.shared)
}
