import SwiftUI
import UIKit

// MARK: - Notification Banner View (Glass-Frosted Effect for OLED)
// This view displays a custom in-app notification banner at the top of the screen.
struct NotificationBannerView: View {
    let notification: NotificationItem // The data to display.
    
    @State private var isAnimatingIn = false // Controls the entrance animation.
    @State private var offset: CGFloat = 0 // Tracks the drag offset for dismissal.
    @State private var isExpanded = false // Tracks if the banner is expanded to show full text.
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(alignment: .center, spacing: 14) {
            // App Logo (Circular like the picture!)
            Image("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 42, height: 42)
                .background(Color.white)
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                // Top line: Title and "now"
                HStack {
                    Text(notification.title)
                        .font(.system(size: 15, weight: .semibold)) // Semibold instead of Bold!
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("now")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Body (Standard regular font case!)
                Text(notification.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
            }
        }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            luminousGlassFrostedBackground()
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(LinearGradient(colors: [Color(hex: "FFFDD0").opacity(0.7), .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5) // Cream hairline!
        )
        .buttonStyle(NotificationButtonStyle()) // Apply custom style!
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .scaleEffect(isAnimatingIn ? 1.0 : 0.88, anchor: .top)
        .opacity(isAnimatingIn ? 1.0 : 0.0)
        .offset(y: isAnimatingIn ? offset : -14)
        // Drag gesture to swipe up and dismiss!
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.translation.height < 0 {
                        offset = gesture.translation.height // Only allow dragging up!
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.height < -30 {
                        // If dragged up enough, dismiss it!
                        withAnimation(.easeInOut(duration: 0.2)) {
                            offset = -100
                            isAnimatingIn = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            NotificationManager.shared.dismissAll()
                        }
                    } else {
                        // Otherwise, snap back to original position.
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
        )
        .onAppear {
            triggerHaptic(for: notification.type) // Synchronized haptic!
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) { // Weighted spring!
                isAnimatingIn = true
            }
        }
    }
    
    // Unused helper, but kept for reference or future use!
    private func luminousGlassFrostedBackground() -> some View {
        ZStack {
            Color.white.opacity(0.01) // Even more transparent!
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.02)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.01)
                ]),
                center: UnitPoint(x: 0.5, y: 0.1),
                startRadius: 0,
                endRadius: 100
            )
            RadialGradient(
                gradient: Gradient(colors: [
                    accentColor(for: notification.type).opacity(0.10),
                    accentColor(for: notification.type).opacity(0.02)
                ]),
                center: .topLeading,
                startRadius: 0,
                endRadius: 120
            )
            RadialGradient(
                gradient: Gradient(colors: [
                    accentColor(for: notification.type).opacity(0.05),
                    Color.clear
                ]),
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 100
            )
            LinearGradient(
                gradient: Gradient(colors: [
                    accentColor(for: notification.type).opacity(0.02),
                    Color.clear
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .background(.ultraThinMaterial)
    }
    
    // Returns a color based on the notification type.
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

    // Helper to trigger haptic feedback based on type.
    private func triggerHaptic(for type: NotificationItem.NotificationType) {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.prepare()
        
        switch type {
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .info:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred(intensity: 0.9)
        }
    }
}

// Custom button style for shrink effect on press!
struct NotificationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Notification Container (for RootView)
// This view sits at the top of the app and listens for notifications to display.
struct NotificationContainer: View {
    var body: some View {
        EmptyView() // In-app banners removed!
    }
}
