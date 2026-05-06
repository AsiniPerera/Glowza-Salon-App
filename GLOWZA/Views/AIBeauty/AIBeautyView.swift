import SwiftUI
import Combine

private let brand = Color(hex: "962043")

// MARK: - Chat Message
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// MARK: - AI Beauty View  (Chatbot)
struct AIBeautyView: View {

    @State private var messages: [ChatMessage] = [
        ChatMessage(
            text: "Hi! I'm your AI Beauty Agent. Describe your skin concerns and I'll recommend personalised treatments and tips for you.",
            isUser: false
        )
    ]
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var dotPhase = 0
    @FocusState private var inputFocused: Bool
    @Environment(AppSettings.self) private var appSettings

    private let bottomID = "chatBottom"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider().overlay(appSettings.isDarkMode ? Color.white.opacity(0.1) : Color(hex: "E8E8E8"))

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(messages) { msg in
                            messageBubble(msg)
                        }
                        if isTyping { typingBubble }
                        Color.clear.frame(height: 1).id(bottomID)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white)
                .onChange(of: messages.count) { _ in
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
                .onChange(of: isTyping) { _ in
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
            }

            // Input bar
            inputBar
        }
        .background((appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white).ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(
            Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
        ) { _ in if isTyping { dotPhase = (dotPhase + 1) % 3 } }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("AI Beauty Agent")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1A1A1A"))
          
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 14)
        .background(appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white)
    }

    // MARK: - Message Bubble
    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            if msg.isUser { Spacer(minLength: 60) }
            Text(msg.text)
                .font(.system(size: 15))
                .foregroundColor(msg.isUser ? .white : (appSettings.isDarkMode ? .white : Color(hex: "1A1A1A")))
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(msg.isUser ? brand : (appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color.white))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: msg.isUser ? 20 : 4,
                        bottomTrailingRadius: msg.isUser ? 4 : 20,
                        topTrailingRadius: 20
                    )
                )
            if !msg.isUser { Spacer(minLength: 60) }
        }
    }

    // MARK: - Typing Indicator
    private var typingBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "8A8A8A"))
                        .frame(width: 7, height: 7)
                        .scaleEffect(dotPhase == i ? 1.3 : 0.8)
                        .opacity(dotPhase == i ? 1 : 0.4)
                        .animation(.spring(response: 0.3), value: dotPhase)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .background(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color.white)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 4,
                                              bottomTrailingRadius: 20, topTrailingRadius: 20))
            Spacer()
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask me anything...", text: $inputText, axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1A1A1A"))
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                .clipShape(Capsule())

            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                              ? Color(hex: "D4829E") : brand)
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
    }

    // MARK: - Send
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        inputFocused = false
        messages.append(ChatMessage(text: text, isUser: true))
        isTyping = true
        Task {
            let r = await AIBeautyEngine.shared.analyse(input: text)
            let reply = buildReply(from: r, input: text)
            try? await Task.sleep(nanoseconds: 900_000_000)
            await MainActor.run {
                isTyping = false
                messages.append(ChatMessage(text: reply, isUser: false))
            }
        }
    }

    // MARK: - Reply Builder
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

#Preview { AIBeautyView() }
