import SwiftUI

// MARK: - Notification Banner View (Glass-Frosted Effect for OLED)
struct NotificationBannerView: View {
    let notification: NotificationItem
    
    @State private var isAnimatingIn = false
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(notification.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        NotificationManager.shared.dismissAll()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity)
        .background(luminousGlassFrostedBackground())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor(for: notification.type).opacity(0.3),
                            Color.white.opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        // Multiple shadow layers for intense glow
        .shadow(color: accentColor(for: notification.type).opacity(0.6), radius: 24, x: 0, y: 12)
        .shadow(color: accentColor(for: notification.type).opacity(0.4), radius: 16, x: 0, y: 6)
        .shadow(color: accentColor(for: notification.type).opacity(0.2), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .scaleEffect(isAnimatingIn ? 1.0 : 0.92)
        .opacity(isAnimatingIn ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65, blendDuration: 0)) {
                isAnimatingIn = true
            }
            // Subtle pulse animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.8
            }
        }
    }
    
    private func luminousGlassFrostedBackground() -> some View {
        ZStack {
            // Ultra-dark semi-transparent base for glass morphism
            Color.black.opacity(0.25)
            
            // Frosted glass layer with blur effect
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass inner light reflection from top
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.08)
                ]),
                center: UnitPoint(x: 0.5, y: 0.1),
                startRadius: 0,
                endRadius: 100
            )
            
            // Strong accent glow from top
            RadialGradient(
                gradient: Gradient(colors: [
                    accentColor(for: notification.type).opacity(0.30),
                    accentColor(for: notification.type).opacity(0.08)
                ]),
                center: .topLeading,
                startRadius: 0,
                endRadius: 120
            )
            
            // Secondary accent glow from bottom right
            RadialGradient(
                gradient: Gradient(colors: [
                    accentColor(for: notification.type).opacity(0.18),
                    Color.clear
                ]),
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 100
            )
            
            // Ambient accent fill
            LinearGradient(
                gradient: Gradient(colors: [
                    accentColor(for: notification.type).opacity(0.10),
                    Color.clear
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .background(.ultraThinMaterial)
    }
    
    private func accentColor(for type: NotificationItem.NotificationType) -> Color {
        switch type {
        case .success:
            return Color(hex: "962043")  // Brand burgundy
        case .info:
            return Color(hex: "3B82F6")  // Blue
        case .error:
            return Color(hex: "EF4444")  // Red
        case .warning:
            return Color(hex: "F59E0B")  // Amber
        }
    }
}

// MARK: - Notification Container (for RootView)
struct NotificationContainer: View {
    var body: some View {
        VStack(spacing: 0) {
            if let notification = NotificationManager.shared.notifications.first {
                NotificationBannerView(notification: notification)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .frame(maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            NotificationBannerView(
                notification: NotificationItem(
                    title: "Booking Confirmed",
                    subtitle: "Facial Treatment • Haley Avenue • Apr 27, 2026 at 2:00 PM",
                    icon: "checkmark.circle.fill",
                    type: .success
                )
            )
            .padding(16)
            
            Spacer()
        }
    }
}
