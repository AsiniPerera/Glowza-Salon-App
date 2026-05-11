import SwiftUI
import UIKit

// MARK: - Notification Banner View (Glass-Frosted Effect for OLED)
struct NotificationBannerView: View {
    let notification: NotificationItem
    
    @State private var isAnimatingIn = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // App Logo
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .frame(width: 50, height: 50)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                // Header
                HStack {
                    Text("GLOWZA")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("now")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        triggerLightHaptic()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            NotificationManager.shared.dismissAll()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(4)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                
                // Title
                Text(notification.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                // Body
                Text(notification.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.1))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .scaleEffect(isAnimatingIn ? 1.0 : 0.88, anchor: .top)
        .opacity(isAnimatingIn ? 1.0 : 0.0)
        .offset(y: isAnimatingIn ? 0 : -14)
        .onAppear {
            triggerLightHaptic()
            withAnimation(.spring(response: 0.36, dampingFraction: 0.76, blendDuration: 0)) {
                isAnimatingIn = true
            }
        }
    }
    
    private func luminousGlassFrostedBackground() -> some View {
        ZStack {
            // Semi-transparent white base for white glass effect
            Color.white.opacity(0.6)
            
            // Frosted glass layer with blur effect
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.17),
                    Color.white.opacity(0.08)
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

    private func triggerLightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.9)
    }
}

// MARK: - Notification Container (for RootView)
struct NotificationContainer: View {
    @State private var notificationManager = NotificationManager.shared

    var body: some View {
        GeometryReader { proxy in
            let hasNotification = notificationManager.notifications.first != nil

            VStack(spacing: 0) {
                if let notification = notificationManager.notifications.first {
                    NotificationBannerView(notification: notification)
                        .padding(.top, proxy.safeAreaInsets.top + 2)
                        .allowsHitTesting(true)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(hasNotification)
            .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            NotificationBannerView(
                notification: NotificationItem(
                    title: "Booking Confirmed",
                    subtitle: "Facial Treatment • Golden Avenue • Apr 27, 2026 at 2:00 PM",
                    icon: "checkmark.circle.fill",
                    type: .success
                )
            )
            .padding(16)
            
            Spacer()
        }
    }
}
