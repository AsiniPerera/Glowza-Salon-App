import SwiftUI
import Combine

private let brand = Color(hex: "AF1C47")

// MARK: - AI Beauty View
struct AIBeautyView: View {

    @State private var selectedConcerns: Set<String> = []
    @State private var result: AIBeautyResult? = nil
    @State private var isAnalysing: Bool = false
    @State private var dotPhase: Int = 0
    @State private var showResults: Bool = false

    private var concernOptions: [String] { AIBeautyEngine.shared.concernOptions }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    greetingBubble
                    concernsCard
                    if showResults {
                        if isAnalysing {
                            analysingBubble
                        } else if let r = result {
                            userMessageBubble
                            thanksHeader
                            if !r.isEmpty {
                                skinSnapshotCard(r)
                                treatmentsSection(r.treatments)
                                if !r.products.isEmpty { productsHeader(r.products) }
                            } else {
                                noMatchView
                            }
                            disclaimerView
                        }
                    }
                    if !showResults || isAnalysing { analyseButton }
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16).padding(.top, 12)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("AI Beauty Consultation")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A"))
                        HStack(spacing: 4) {
                            Text("Powered by Core ML")
                                .font(.system(size: 11)).foregroundColor(Color(hex: "8A8A8A"))
                            Text("✦")
                                .font(.system(size: 9)).foregroundColor(brand)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 16, weight: .medium)).foregroundColor(brand.opacity(0.7))
                }
            }
        }
        .onReceive(
            Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
        ) { _ in if isAnalysing { dotPhase = (dotPhase + 1) % 4 } }
    }

    // MARK: - Greeting Bubble
    private var greetingBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(brand.opacity(0.10)).frame(width: 44, height: 44)
                Text("G.").font(.system(size: 17, weight: .bold, design: .serif)).foregroundColor(brand)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi, I'm Glowza AI.")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Text("Tell me about your skin so I can personalise our recommendations.")
                    .font(.system(size: 14)).foregroundColor(Color(hex: "4A4A4A")).lineSpacing(3)
            }
            .padding(16)
            .background(Color(hex: "F9F9F9"))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 16,
                                              bottomTrailingRadius: 16, topTrailingRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            Spacer()
        }
    }

    // MARK: - Concerns Card
    private var concernsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What are your main skin concerns?")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Text("Select one or more")
                    .font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(concernOptions, id: \.self) { concern in
                    let selected = selectedConcerns.contains(concern)
                    Button(action: {
                        if selected { selectedConcerns.remove(concern) }
                        else { selectedConcerns.insert(concern) }
                        if showResults { showResults = false; result = nil }
                    }) {
                        HStack {
                            Text(concern
                                .replacingOccurrences(of: " & ", with: " / "))
                                .font(.system(size: 13, weight: selected ? .semibold : .regular))
                                .foregroundColor(selected ? brand : Color(hex: "1A1A1A"))
                                .lineLimit(2).multilineTextAlignment(.leading)
                            Spacer()
                            if selected {
                                ZStack {
                                    Circle().fill(brand).frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(selected ? Color(hex: "FFF0F4") : Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(selected ? brand.opacity(0.4) : Color(hex: "EBEBEB"), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - User Message Bubble
    private var userMessageBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer()
            let concernText = selectedConcerns.isEmpty
                ? "I have multiple skin concerns I'd like help with."
                : "I'm concerned about \(selectedConcerns.prefix(3).joined(separator: ", "))\(selectedConcerns.count > 3 ? " and more." : ".")"
            Text(concernText)
                .font(.system(size: 14)).foregroundColor(Color(hex: "1A1A1A")).lineSpacing(3)
                .padding(14)
                .background(Color(hex: "FFF0F4"))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16,
                                                  bottomTrailingRadius: 4, topTrailingRadius: 16))
            ZStack {
                Circle().fill(brand.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "person.fill").font(.system(size: 18)).foregroundColor(brand)
            }
        }
    }

    // MARK: - Analysing Bubble
    private var analysingBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(brand.opacity(0.10)).frame(width: 44, height: 44)
                Text("G.").font(.system(size: 17, weight: .bold, design: .serif)).foregroundColor(brand)
            }
            HStack(spacing: 6) {
                ForEach(0..<4) { i in
                    Circle().fill(brand).frame(width: 7, height: 7)
                        .scaleEffect(dotPhase == i ? 1.4 : 0.8)
                        .opacity(dotPhase == i ? 1 : 0.4)
                        .animation(.spring(response: 0.3), value: dotPhase)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .background(Color(hex: "F9F9F9"))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 16,
                                              bottomTrailingRadius: 16, topTrailingRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            Spacer()
        }
    }

    // MARK: - Thanks Header
    private var thanksHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Thanks! ✨")
                .font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
            Text("Based on your inputs, here's what I recommend for your skin.")
                .font(.system(size: 14)).foregroundColor(Color(hex: "4A4A4A")).lineSpacing(3)
        }
    }

    // MARK: - Skin Snapshot Card
    private func skinSnapshotCard(_ r: AIBeautyResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Skin Snapshot")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Spacer()
                HStack(spacing: 4) {
                    Text("✦").font(.system(size: 10)).foregroundColor(brand)
                    Text("AI Analysis").font(.system(size: 12, weight: .medium)).foregroundColor(brand)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(brand.opacity(0.08)).cornerRadius(20)
            }
            HStack(alignment: .center, spacing: 20) {
                SkinScoreRing(score: skinScore(r)).frame(width: 100, height: 100)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(concernLevels(r), id: \.0) { name, icon, level in
                        HStack(spacing: 8) {
                            Image(systemName: icon).font(.system(size: 12)).foregroundColor(brand).frame(width: 16)
                            Text(name).font(.system(size: 13)).foregroundColor(Color(hex: "1A1A1A"))
                            Spacer()
                            Text(level).font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white).cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func skinScore(_ r: AIBeautyResult) -> Int {
        max(45, 95 - min(r.detectedConcerns.count, 5) * 10)
    }

    private func concernLevels(_ r: AIBeautyResult) -> [(String, String, String)] {
        let levels = ["High", "Moderate", "Moderate", "Low"]
        return r.detectedConcerns.prefix(4).enumerated().map { i, c in
            (c.name, c.icon, levels[min(i, levels.count - 1)])
        }
    }

    // MARK: - Treatments
    private func treatmentsSection(_ treatments: [TreatmentRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommended Treatments")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Text("Curated for your skin goals")
                    .font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            }
            ForEach(treatments.prefix(4)) { treatment in treatmentCard(treatment) }
        }
    }

    private func treatmentCard(_ treatment: TreatmentRecommendation) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(brand.opacity(0.08)).frame(width: 80, height: 80)
                Image(systemName: treatment.icon).font(.system(size: 28)).foregroundColor(brand)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(treatment.name)
                    .font(.system(size: 14, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Text(treatment.tagline)
                    .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A")).lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 10)).foregroundColor(Color(hex: "8A8A8A"))
                    Text(treatment.duration).font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                }
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bookmark").font(.system(size: 16)).foregroundColor(brand.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Products Header
    private func productsHeader(_ products: [ProductRecommendation]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommended Products")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Text("Handpicked to complement your treatments")
                    .font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            }
            Spacer()
            Button("See All") {}
                .font(.system(size: 14, weight: .medium)).foregroundColor(brand)
        }
    }

    // MARK: - No Match
    private var noMatchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 38)).foregroundColor(Color(hex: "CCCCCC"))
            Text("Couldn't detect a specific concern.")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A"))
            Text("Try selecting different skin concerns or describe your issue.")
                .font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A")).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 32)
    }

    // MARK: - Disclaimer
    private var disclaimerView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").font(.system(size: 13)).foregroundColor(brand).padding(.top, 1)
            Text("AI recommendations are for informational purposes only. Please consult a licensed dermatologist before beginning any treatment.")
                .font(.system(size: 11)).foregroundColor(Color(hex: "8A8A8A")).lineSpacing(3)
        }
        .padding(12).background(brand.opacity(0.05)).cornerRadius(12)
    }

    // MARK: - Analyse Button
    private var analyseButton: some View {
        Button(action: runAnalysis) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles").font(.system(size: 15, weight: .semibold))
                Text("Analyse My Skin").font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(selectedConcerns.isEmpty ? Color(hex: "CCCCCC") : brand)
            .cornerRadius(14)
            .shadow(color: selectedConcerns.isEmpty ? Color.clear : brand.opacity(0.28), radius: 10, y: 4)
        }
        .disabled(selectedConcerns.isEmpty || isAnalysing)
        .buttonStyle(.plain)
    }

    // MARK: - Action
    private func runAnalysis() {
        let input = selectedConcerns.joined(separator: ", ")
        withAnimation(.easeInOut(duration: 0.3)) {
            result = nil; isAnalysing = true; showResults = true
        }
        Task {
            let r = await AIBeautyEngine.shared.analyse(input: input)
            await MainActor.run {
                withAnimation(.spring(response: 0.5)) { isAnalysing = false; result = r }
            }
        }
    }
}

// MARK: - Skin Score Ring
struct SkinScoreRing: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: "F0F0F0"), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(brand, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: score)
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Text("Skin Score")
                    .font(.system(size: 10)).foregroundColor(Color(hex: "8A8A8A"))
            }
        }
    }
}

#Preview { AIBeautyView() }
