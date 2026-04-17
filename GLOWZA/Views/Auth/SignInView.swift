import SwiftUI

struct LandingPageView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 1. Top Image with Diagonal Cut
            ZStack(alignment: .bottom) {
                Image("stylist_image") // Ensure this matches your Assets.xcassets name
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .clipped()
                    .clipShape(DiagonalEdgeShape())
            }
            
            // 2. Content Area
            VStack(alignment: .leading, spacing: 20) {
                // Title Group
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meet Your")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    Text("Expert Stylist")
                        .font(.system(size: 48, weight: .regular, design: .rounded))
                        // Manual RGB for #D4AF37
                        .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                }
                .padding(.top, 20)
                
                // Description
                Text("Our curated team of professionals is dedicated to bringing your unique vision to life with precision and luxury.")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.gray)
                    .lineSpacing(6)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                NavigationLink(destination: GlowzaLandingPage()) {
                                  Text("Continue")
                                      .font(.headline)
                                      .foregroundColor(.white)
                                      .frame(maxWidth: .infinity)
                                      .frame(height: 56)
                                      .background(Color(red: 0.86, green: 0.71, blue: 0.41))
                                      .cornerRadius(12)
                              }
                              .padding(.bottom, 40)
                          }
                          .padding(.horizontal, 30)
                          .background(Color.white)
                      }
                  }
              }

// MARK: - Custom Diagonal Shape
struct DiagonalEdgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.85))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
struct LandingPageView_Previews: PreviewProvider {
    static var previews: some View {
        // Wrapped in NavigationView so the NavigationLink works in Preview
        NavigationView {
            LandingPageView()
        }
    }
}
