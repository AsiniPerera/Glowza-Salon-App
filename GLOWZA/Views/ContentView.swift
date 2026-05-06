import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 0.992, green: 0.969, blue: 0.949)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.898, green: 0.651, blue: 0.122))

                Text("Glowza")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)

                Text("Premium Salon Experience")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ContentView()
}
