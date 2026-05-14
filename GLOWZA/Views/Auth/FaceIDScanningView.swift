import SwiftUI

// MARK: - Face ID Scanning View
// A premium, immersive interface that appears when the user is authenticating with Face ID.
struct FaceIDScanningView: View {
    @Binding var isPresented: Bool
    let onCancel: () -> Void
    
    @State private var scanOffset: CGFloat = -120
    @State private var iconScale: CGFloat = 1.0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.0
    
    @Environment(AppSettings.self) private var appSettings
    
    // Calm & Soft Pink Palette
    private let bgGradient = LinearGradient(
        colors: [Color(hex: "FFF0F5"), Color(hex: "FFE4E1")], // Lavender Blush to Misty Rose
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let softPink = Color(hex: "FFB6C1") // Light Pink
    private let roseGold = Color(hex: "E1B1B1")
    private let brand = Color.glowzaPrimary
    
    var body: some View {
        ZStack {
            // Soft Gradient Background
            bgGradient.ignoresSafeArea()
            
            // Subtle texture / decorative elements
            Circle()
                .fill(softPink.opacity(0.15))
                .frame(width: 400, height: 400)
                .offset(x: -150, y: -250)
                .blur(radius: 60)
            
            Circle()
                .fill(brand.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 300)
                .blur(radius: 50)
            
            VStack(spacing: 50) {
                Spacer()
                
                // Immersive Scanning Animation
                ZStack {
                    // Soft pulsing rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(brand.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                            .frame(width: 180 + CGFloat(i * 40), height: 180 + CGFloat(i * 40))
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                            .animation(
                                .easeOut(duration: 2.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.6),
                                value: ringScale
                            )
                    }

                    // Main Container
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.5))
                            .frame(width: 140, height: 140)
                            .blur(radius: 10)
                        
                        Image(systemName: "faceid")
                            .font(.system(size: 70, weight: .thin))
                            .foregroundStyle(
                                LinearGradient(colors: [brand, softPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .scaleEffect(iconScale)
                    }
                    
                    // Soft Scanning Line
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, brand.opacity(0.5), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 120, height: 4)
                        .blur(radius: 1)
                        .offset(y: scanOffset)
                }
                .onAppear {
                    ringScale = 1.3
                    ringOpacity = 1.0
                    
                    withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                        scanOffset = 120
                        iconScale = 1.05
                    }
                }
                
                VStack(spacing: 16) {
                    Text("Scanning Face...")
                        .glowzaFont(size: 26, weight: .bold)
                        .foregroundColor(brand.opacity(0.8))
                    
                    Text("Hold still while we securely verify your identity.")
                        .glowzaFont(size: 16)
                        .foregroundColor(roseGold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 50)
                }
                
                Spacer()
                
                // Elegant Cancel Button
                Button(action: onCancel) {
                    Text("Cancel")
                        .glowzaFont(size: 17, weight: .semibold)
                        .foregroundColor(brand)
                        .frame(width: 180, height: 56)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.6))
                                .shadow(color: brand.opacity(0.1), radius: 10, y: 5)
                        )
                        .overlay(
                            Capsule()
                                .stroke(brand.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    FaceIDScanningView(isPresented: .constant(true), onCancel: {})
        .environment(AppSettings.shared)
}
