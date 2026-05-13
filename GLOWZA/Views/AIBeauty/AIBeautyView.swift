import SwiftUI
import Combine

// MARK: - Chat Message
// A simple model to represent a message in the chat.
// It has an ID, text, and a boolean to check if it's from the user or the AI.
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// MARK: - AI Beauty View (Chatbot)
// This view is a chatbot interface where users can ask the AI about skin concerns.
// The AI will recommend treatments based on the user's input.
struct AIBeautyView: View {

    // Array of messages to display in the chat.
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            text: "Hi! I'm your AI Beauty Agent. Describe your skin concerns and I'll recommend personalised treatments and tips for you.",
            isUser: false
        )
    ]
    @State private var inputText = ""
    @State private var isTyping = false // Shows the typing indicator.
    @State private var dotPhase = 0 // For animating the typing dots.
    @FocusState private var inputFocused: Bool // Controls keyboard focus.
    @Environment(AppSettings.self) private var appSettings

    private var pageBackground:    Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var bubbleBackground:  Color { appSettings.themeRaised }
    private var dividerColor:      Color { appSettings.themeDivider }
    private var primaryText:       Color { appSettings.themeText }
    private var inputBackground:   Color { appSettings.themeRaised }
    private var brand:             Color { appSettings.themeBrand }
    private var secondaryText:     Color { appSettings.themeTextSecondary }

    private let bottomID = "chatBottom" // Used to scroll to the bottom.

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Chat Messages List
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Title at top of scroll content
                        Text("AI Beauty Agent")
                            .glowzaFont(size: 28, weight: .bold)
                            .foregroundColor(appSettings.isHighContrast ? .white : primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                            .padding(.bottom, 8)

                        ForEach(messages) { msg in
                            messageBubble(msg)
                        }
                        
                        // Show typing bubble if AI is thinking!
                        if isTyping { typingBubble }
                        
                        Color.clear.frame(height: 1).id(bottomID)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(pageBackground)
                // Auto-scroll to bottom when new messages arrive!
                .onChange(of: messages.count) {
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
                .onChange(of: isTyping) {
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
            }

            // MARK: Input Bar
            inputBar
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        // Timer to animate the typing dots!
        .onReceive(
            Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
        ) { _ in if isTyping { dotPhase = (dotPhase + 1) % 3 } }
    }

    // MARK: - Message Bubble View
    // Helper to draw a chat bubble based on whether it's user or AI.
    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isHC = appSettings.isHighContrast
        let rose  = Color(hex: "FF2D55")
        HStack(alignment: .bottom, spacing: 0) {
            if msg.isUser { Spacer(minLength: 60) } // Push user bubble to the right.
            
            Text(msg.text)
                .glowzaFont(size: 15, weight: isHC ? .medium : .regular)
                .foregroundColor(isHC ? .black : (msg.isUser ? .white : primaryText))
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        isHC ? (msg.isUser ? brand : .white) : (msg.isUser ? brand : bubbleBackground)
                        // Rose tint on AI bubbles in High Contrast mode.
                        if isHC && !msg.isUser { rose.opacity(0.12) }
                    }
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: msg.isUser ? 20 : 4,
                        bottomTrailingRadius: msg.isUser ? 4 : 20,
                        topTrailingRadius: 20
                    )
                )
                // Neon border on AI bubbles in High Contrast mode.
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: msg.isUser ? 20 : 4,
                        bottomTrailingRadius: msg.isUser ? 4 : 20,
                        topTrailingRadius: 20
                    )
                    .stroke(isHC && !msg.isUser ? rose.opacity(0.80) : Color.clear, lineWidth: 3)
                )
                .shadow(color: isHC && msg.isUser ? rose.opacity(0.35) : .clear, radius: 10)
            
            if !msg.isUser { Spacer(minLength: 60) } // Push AI bubble to the left.
        }
    }

    // MARK: - Typing Indicator
    // Helper to draw the animated typing dots.
    private var typingBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(appSettings.isHighContrast ? Color(hex: "FF2D55") : appSettings.themeTextSecondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(dotPhase == i ? 1.3 : 0.8)
                        .opacity(dotPhase == i ? 1 : 0.4)
                        .animation(.spring(response: 0.3), value: dotPhase)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .background(bubbleBackground)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 4,
                                              bottomTrailingRadius: 20, topTrailingRadius: 20))
            Spacer()
        }
    }

    // MARK: - Input Bar View
    private var inputBar: some View {
        let isHC     = appSettings.isHighContrast
        let rose     = Color(hex: "FF2D55")
        let isEmpty  = inputText.trimmingCharacters(in: .whitespaces).isEmpty
        return HStack(spacing: 12) {
            TextField("Ask me anything...", text: $inputText, prompt: Text("Ask me anything...").foregroundColor(isHC ? .black : secondaryText), axis: .vertical)
                .glowzaFont(size: 15)
                .foregroundColor(isHC ? .black : primaryText)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isHC ? .white : inputBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isHC ? rose.opacity(inputFocused ? 1.0 : 0.70) : Color.clear,
                                lineWidth: 3)
                )

            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(isEmpty ? appSettings.themeBrandMuted : brand)
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.up")
                        .glowzaFont(size: 17, weight: .semibold)
                        .foregroundColor(.white)
                }
            }
            .disabled(isEmpty || isTyping)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(surfaceBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(isHC ? rose.opacity(0.45) : dividerColor)
                .frame(height: isHC ? 1 : 0.5)
                .opacity(isHC ? 1 : (appSettings.isDarkMode ? 0.15 : 1))
        }
        .shadow(color: .black.opacity((appSettings.isDarkMode || isHC) ? 0.0 : 0.06),
                radius: 8, x: 0, y: -2)
    }

    // MARK: - Send Message Logic
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        inputFocused = false
        
        messages.append(ChatMessage(text: text, isUser: true))
        isTyping = true
        
        Task {
            // Call the AI Beauty Engine to analyse the input!
            let r = await AIBeautyEngine.shared.analyse(input: text)
            let reply = buildReply(from: r, input: text)
            
            // Simulate network delay for realism!
            try? await Task.sleep(nanoseconds: 900_000_000)
            
            await MainActor.run {
                isTyping = false
                messages.append(ChatMessage(text: reply, isUser: false))
            }
        }
    }

    // MARK: - Reply Builder Helper
    // This function takes the AI result and builds a friendly response string.
    private func buildReply(from result: AIBeautyResult, input: String) -> String {
        guard !result.isEmpty else {
            return "I appreciate you sharing that! Could you give me a bit more detail? For example, mention things like oily skin, acne, dark spots, dryness, or sensitivity and I'll personalise my advice for you."
        }
        var parts: [String] = []
        let concerns = result.detectedConcerns.prefix(3).map(\.name).joined(separator: ", ")
        parts.append("Got it! Based on what you've shared, I can see concerns around \(concerns).")
        if let first = result.treatments.first {
            parts.append("\nFirst, I recommend: \(first.name) — \(first.tagline.lowercased()).")
        }
        if result.treatments.count > 1 {
            let extras = result.treatments.dropFirst().prefix(2).map(\.name).joined(separator: " and ")
            parts.append("You might also benefit from \(extras).")
        }
        if let product = result.products.first {
            parts.append("\nFor home care, try \(product.name) by \(product.brand) — great for \(product.benefit.lowercased()).")
        }
        parts.append("\nWould you like me to suggest salons near you that offer these treatments?")
        return parts.joined(separator: " ")
    }
}

#Preview {
    AIBeautyView()
        .environment(AppSettings.shared)
}
