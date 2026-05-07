import SwiftUI
import UIKit

// MARK: - Notification Banner View (Glass-Frosted Effect for OLED)
struct NotificationBannerView: View {
    let notification: NotificationItem
    
    @State private var isAnimatingIn = false
    @State private var isExpanded = false
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: notification.icon)
                    .glowzaFont(size: 14, weight: .bold)
                    .foregroundColor(Color(hex: "962043"))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Circle())

                Text(notification.title)
                    .glowzaFont(size: 15, weight: .semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    triggerLightHaptic()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        NotificationManager.shared.dismissAll()
                    }
                }) {
                    Image(systemName: "xmark")
                        .glowzaFont(size: 11, weight: .bold)
                        .foregroundColor(.white.opacity(0.68))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(notification.subtitle)
                        .glowzaFont(size: 12.5, weight: .regular)
                        .foregroundColor(Color.white.opacity(0.84))
                        .lineLimit(2)

                    if notification.type == .success {
                        HStack(spacing: 10) {
                            Button("View Results") {
                                triggerLightHaptic()
                                NotificationCenter.default.post(name: .glowzaGoToBookingsTab, object: nil)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    NotificationCenter.default.post(name: .glowzaShowUpcomingBookings, object: nil)
                                }
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    NotificationManager.shared.dismissAll()
                                }
                            }
                            .glowzaFont(size: 12, weight: .semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(Color(hex: "962043"))
                            .clipShape(Capsule())

                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(luminousGlassFrostedBackground())
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 22 : 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? 22 : 30, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "C6A769").opacity(0.64),
                            Color(hex: "C6A769").opacity(0.28),
                            Color.white.opacity(0.18)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.3
                )
        )
        // Multiple shadow layers for intense glow
        .shadow(color: Color(hex: "C6A769").opacity(0.28), radius: 18, x: 0, y: 10)
        .shadow(color: accentColor(for: notification.type).opacity(0.24), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 20)
        .padding(.top, 0)
        .scaleEffect(isAnimatingIn ? 1.0 : 0.88, anchor: .top)
        .opacity(isAnimatingIn ? 1.0 : 0.0)
        .offset(y: isAnimatingIn ? 0 : -14)
        .onAppear {
            triggerLightHaptic()

            withAnimation(.spring(response: 0.36, dampingFraction: 0.76, blendDuration: 0)) {
                isAnimatingIn = true
            }

            // Start as a compact top pill, then quickly expand to show details.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82, blendDuration: 0)) {
                    isExpanded = true
                }
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
