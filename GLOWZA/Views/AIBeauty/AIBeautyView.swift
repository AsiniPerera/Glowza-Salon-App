import SwiftUI
import Combine

// MARK: - AI Beauty View
struct AIBeautyView: View {

    @State private var inputText: String = ""
    @State private var result: AIBeautyResult? = nil
    @State private var isAnalysing: Bool = false
    @State private var dotPhase: Int = 0
    @State private var expandedTreatmentID: UUID? = nil

    // Concern chips sourced from the ML engine — no hardcoded list
    private var quickConcerns: [String] { AIBeautyEngine.shared.concernOptions }

    var body: some View {
        ZStack(alignment: .top) {
            Color.glowzaBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    inputSection
                    if isAnalysing { analysingView }
                    if let r = result, !isAnalysing { resultSection(r) }
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onReceive(
            Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
        ) { _ in if isAnalysing { dotPhase = (dotPhase + 1) % 4 } }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.glowzaGold.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 28))
                    .foregroundColor(Color.glowzaGoldDark)
            }
            .padding(.top, 22)

            Text("AI Beauty Advisor")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.glowzaTextPrimary)

            Text("Describe your skin concern and get\npersonalised treatment recommendations.")
                .font(.system(size: 13))
                .foregroundColor(Color.glowzaSubtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
    }

    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Quick concern chips
            Text("Quick select")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.glowzaBrown)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickConcerns, id: \.self) { concern in
                        Button(action: {
                            if inputText.isEmpty {
                                inputText = concern
                            } else if !inputText.lowercased().contains(concern.lowercased()) {
                                inputText += ", \(concern)"
                            }
                        }) {
                            Text(concern)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(
                                    inputText.lowercased().contains(concern.lowercased())
                                    ? .white : Color.glowzaGoldDark
                                )
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    inputText.lowercased().contains(concern.lowercased())
                                    ? Color.glowzaGoldDark : Color.white
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.glowzaGold.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Text input
            VStack(alignment: .leading, spacing: 8) {
                Text("Or describe your concern")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.glowzaBrown)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.glowzaGold.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    if inputText.isEmpty {
                        Text("e.g. I have acne and dark circles under my eyes...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.glowzaSubtext.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $inputText)
                        .font(.system(size: 14))
                        .foregroundColor(Color.glowzaTextPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: 90)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .frame(minHeight: 90)
            }
            .padding(.horizontal, 24)

            // Analyse button
            Button(action: runAnalysis) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Analyse My Skin")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color.glowzaGold, Color.glowzaGoldDark],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.glowzaGold.opacity(0.35), radius: 10, x: 0, y: 5)
                .opacity(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isAnalysing)
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Analysing Animation
    private var analysingView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(Color.glowzaGoldDark)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotPhase == i ? 1.4 : 0.8)
                        .opacity(dotPhase == i ? 1 : 0.4)
                        .animation(.spring(response: 0.3), value: dotPhase)
                }
            }
            Text("Analysing your skin concerns…")
                .font(.system(size: 14))
                .foregroundColor(Color.glowzaSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Results
    private func resultSection(_ r: AIBeautyResult) -> some View {
        VStack(alignment: .leading, spacing: 24) {

            // Divider header
            HStack {
                VStack { Divider() }
                Text("Your Results")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.glowzaSubtext)
                    .fixedSize()
                VStack { Divider() }
            }
            .padding(.horizontal, 24)

            if r.isEmpty {
                noMatchView
            } else {
                // Detected concerns
                detectedConcernsSection(r.detectedConcerns)
                // Treatments
                treatmentsSection(r.treatments)
                // Products
                if !r.products.isEmpty { productsSection(r.products) }
                // Disclaimer
                disclaimerView
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Detected Concerns
    private func detectedConcernsSection(_ concerns: [DetectedConcern]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detected Concerns")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.glowzaTextPrimary)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(concerns) { c in
                        Label(c.name, systemImage: c.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.glowzaGoldDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.glowzaGold.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.glowzaGold.opacity(0.4), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Treatments
    private func treatmentsSection(_ treatments: [TreatmentRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Treatments")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.glowzaTextPrimary)
                .padding(.horizontal, 24)

            ForEach(Array(treatments.enumerated()), id: \.element.id) { index, treatment in
                treatmentCard(treatment: treatment, rank: index + 1)
                    .padding(.horizontal, 24)
            }
        }
    }

    private func treatmentCard(treatment: TreatmentRecommendation, rank: Int) -> some View {
        let isExpanded = expandedTreatmentID == treatment.id

        return VStack(spacing: 0) {
            // Card header (always visible)
            Button(action: {
                withAnimation(.spring(response: 0.35)) {
                    expandedTreatmentID = isExpanded ? nil : treatment.id
                }
            }) {
                HStack(spacing: 14) {
                    // Rank + icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.glowzaGold, Color.glowzaGoldDark],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                        Image(systemName: treatment.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(treatment.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.glowzaTextPrimary)
                            if rank == 1 {
                                Text("Best Match")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.glowzaGoldDark)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(treatment.tagline)
                            .font(.system(size: 12))
                            .foregroundColor(Color.glowzaSubtext)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.glowzaSubtext)
                }
                .padding(16)
            }

            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().padding(.horizontal, 16)

                    Text(treatment.description)
                        .font(.system(size: 13))
                        .foregroundColor(Color.glowzaTextPrimary.opacity(0.8))
                        .lineSpacing(4)
                        .padding(.horizontal, 16)

                    // Stats grid
                    HStack(spacing: 0) {
                        detailStat(icon: "clock", label: "Duration", value: treatment.duration)
                        Divider().frame(height: 36)
                        detailStat(icon: "calendar.badge.clock", label: "Sessions", value: treatment.sessions)
                    }
                    .padding(.horizontal, 16)

                    // Price
                    HStack(spacing: 8) {
                        Image(systemName: "banknote")
                            .font(.system(size: 14))
                            .foregroundColor(Color.glowzaGoldDark)
                        Text(treatment.priceRange)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.glowzaTextPrimary)
                    }
                    .padding(.horizontal, 16)

                    // Book Now button
                    Button(action: {}) {
                        Text("Book a Consultation")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.glowzaGoldDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.glowzaGold.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.glowzaGold.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
        }
        .glowzaCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(rank == 1 ? Color.glowzaGold.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.35), value: isExpanded)
    }

    private func detailStat(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color.glowzaGoldDark)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.glowzaSubtext)
            }
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.glowzaTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Products
    private func productsSection(_ products: [ProductRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Products")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.glowzaTextPrimary)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(products) { p in
                        productCard(p)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
        }
    }

    private func productCard(_ p: ProductRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.glowzaGold.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: p.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.glowzaGoldDark)
            }
            Text(p.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.glowzaTextPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(p.brand)
                .font(.system(size: 11))
                .foregroundColor(Color.glowzaSubtext)
            Text(p.benefit)
                .font(.system(size: 11))
                .foregroundColor(Color.glowzaBrown.opacity(0.8))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(p.category)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.glowzaGoldDark)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.glowzaGold.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(14)
        .frame(width: 150)
        .glowzaCard()
    }

    // MARK: - No Match
    private var noMatchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 38))
                .foregroundColor(Color.glowzaSubtext.opacity(0.5))
            Text("Couldn't detect a specific concern.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.glowzaTextPrimary)
            Text("Try using keywords like \"acne\", \"dark circles\",\n\"wrinkles\" or \"unwanted hair\".")
                .font(.system(size: 13))
                .foregroundColor(Color.glowzaSubtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
    }

    // MARK: - Disclaimer
    private var disclaimerView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color.glowzaGold)
                .padding(.top, 1)
            Text("These recommendations are for informational purposes only and not a substitute for professional medical advice. Please consult a licensed dermatologist or aesthetician before beginning any treatment.")
                .font(.system(size: 11))
                .foregroundColor(Color.glowzaSubtext)
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color.glowzaGold.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 24)
    }

    // MARK: - Action
    private func runAnalysis() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation {
            result = nil
            isAnalysing = true
        }
        Task {
            let r = await AIBeautyEngine.shared.analyse(input: inputText)
            await MainActor.run {
                withAnimation(.spring(response: 0.5)) {
                    isAnalysing = false
                    result = r
                }
            }
        }
    }
}

#Preview {
    AIBeautyView()
}
