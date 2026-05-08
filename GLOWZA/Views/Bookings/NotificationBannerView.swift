import SwiftUI
import UIKit

// MARK: - Notification Banner View (Glass-Frosted Effect for OLED)
struct NotificationBannerView: View {
    let notification: NotificationItem
    
    @State private var isAnimatingIn = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // App Icon (Square with rounded corners)
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Header: Title + Time + Dismiss
                HStack {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
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
                
                // Body
                Text(notification.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(3)
                
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
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
            // Ultra-dark semi-transparent base for glass morphism
            Color.black.opacity(0.24)
            
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
