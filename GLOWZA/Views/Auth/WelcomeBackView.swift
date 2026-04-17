import SwiftUI

struct GlowzaLandingPage: View {
    var body: some View {
        ZStack {
            // 1. Background Image
            Image("salon_background") // Replace with your image name
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            // 2. Content Overlay
            VStack(alignment: .leading, spacing: 0) {
                // Brand Header
                Text("GLOWZA")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "#8C733E"))
                    .padding(.top, 60)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Middle Text Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("EST. 2024  •  BESPOKE BEAUTY")
                        .font(.system(size: 12, weight: .medium))
                        .kerning(2)
                        .foregroundColor(Color(hex: "#D4AF37"))
                    
                    VStack(alignment: .leading, spacing: -5) {
                        Text("Book Your")
                        Text("Perfect Look")
                            .foregroundColor(Color(hex: "#D4AF37"))
                    }
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.black)
                    
                    Text("Experience a new standard of luxury where every detail is tailored to your unique elegance.")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(3)
                        .lineSpacing(4)
                        .padding(.trailing, 40)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                // 3. Bottom Action Card
                VStack(spacing: 16) {
                    // Continue with Email
                    Button(action: {}) {
                        HStack {
                            Text("Continue with Email")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "#DBB668"))
                        .cornerRadius(12)
                    }
                    
                    // Navigation to Face ID Auth View
                    NavigationLink(destination: FaceIDAuthView()) {
                        HStack(spacing: 10) {
                            Image(systemName: "faceid")
                            Text("Continue with Face ID")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                // Manual RGB for #DBB668 to avoid hex errors
                                .stroke(Color(red: 0.86, green: 0.71, blue: 0.41).opacity(0.3), lineWidth: 1)
                        )
                    }                }
                .padding(30)
                .padding(.bottom, 20)
                .background(
                    Color(hex: "#F5F2EA") // Off-white/Cream background
                        .clipShape(CustomCorner(corners: [.topLeft, .topRight], radius: 40))
                )
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// Helper for specific corner rounding
struct CustomCorner: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
