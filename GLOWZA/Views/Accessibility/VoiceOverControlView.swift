import SwiftUI

// MARK: - VoiceOver Control View
// A premium floating controller that allows users to play, pause, and stop screen summaries.
struct VoiceOverControlView: View {
    @Environment(AppSettings.self) private var appSettings
    @ObservedObject private var speechManager = SpeechManager.shared
    
    @State private var dragOffset: CGSize = .zero
    @State private var position: CGSize = CGSize(width: -20, height: -100) // Initial position (bottom right)
    @State private var isExpanded = false
    
    private var brand: Color { appSettings.themeBrand }
    
    var body: some View {
        if appSettings.isVoiceOverEnabled {
            ZStack(alignment: .bottomTrailing) {
                // Invisible layer to catch drag when expanded
                Color.clear.ignoresSafeArea()
                
                VStack(alignment: .trailing, spacing: 12) {
                    if isExpanded {
                        // Expanded Controls
                        HStack(spacing: 15) {
                            // Stop Button
                            controlButton(icon: "stop.fill", color: .red) {
                                speechManager.stop()
                                withAnimation(.spring()) { isExpanded = false }
                            }
                            
                            // Play/Pause Button
                            controlButton(
                                icon: speechManager.state == .speaking ? "pause.fill" : "play.fill",
                                color: brand
                            ) {
                                if speechManager.state == .speaking {
                                    speechManager.pause()
                                } else if speechManager.state == .paused {
                                    speechManager.resume()
                                } else {
                                    speechManager.speak(appSettings.currentScreenSummary)
                                }
                            }
                        }
                        .padding(.trailing, 8)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    // Main Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(brand)
                                .frame(width: 60, height: 60)
                                .shadow(color: brand.opacity(0.4), radius: 10, y: 5)
                            
                            // Animated Sound Waves when speaking
                            if speechManager.state == .speaking {
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                        .scaleEffect(isExpanded ? 1.0 : 1.4)
                                        .opacity(isExpanded ? 0 : 1)
                                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: speechManager.state)
                                }
                            }
                            
                            Image(systemName: isExpanded ? "xmark" : "speaker.wave.2.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .offset(x: position.width + dragOffset.width, y: position.height + dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                position.width += value.translation.width
                                position.height += value.translation.height
                                dragOffset = .zero
                            }
                        }
                )
            }
            .padding(20)
        }
    }
    
    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VoiceOverControlView()
            .environment(AppSettings.shared)
    }
}
