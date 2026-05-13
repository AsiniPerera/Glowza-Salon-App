import SwiftUI
import Charts // We use SwiftUI's Charts framework to draw the price graph!

// MARK: - Constants
private let teal = Color(hex: "00A878")
private let treatmentScopeName = "All Treatments"

// MARK: - Helpers

// A simple wrapper model to make SalonService identifiable in lists.
private struct CatalogEntry: Identifiable {
    let id: UUID
    let service: SalonService
}

// Extracts the numbers from a string like "55 min" and returns them as an Int!
private func durationMins(_ s: SalonService) -> Int {
    Int(s.duration.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
}

// Truncates long treatment names so they fit nicely on the screen!
private func shortTreatmentName(_ name: String) -> String {
    if name.count <= 16 { return name }
    return String(name.prefix(16)) + "..."
}

// MARK: - CompareView
// This view allows users to select multiple treatments and compare them 
// side-by-side based on price, duration, and benefits.
struct CompareView: View {

    @Environment(TreatmentComparisonStore.self) private var store // Shared store to manage selected items.
    @Environment(AppSettings.self) private var appSettings
    private var brand: Color { appSettings.themeBrand }

    // MARK: Hardcoded Data
    // Mock data for treatments that can be compared.
    // In a real app, this would come from a database or API.
    private let comparisonTreatments: [SalonService] = [
        SalonService(name: "Hydra Facial", icon: "drop", duration: "55 min", price: 4500, category: "Skin", benefits: ["Hydration", "Glow", "Pore care"]),
        SalonService(name: "Oxygen Facial", icon: "wind", duration: "50 min", price: 5200, category: "Skin", benefits: ["Brightness", "Smooth texture", "Fresh look"]),
        SalonService(name: "Vitamin C Facial", icon: "sun.max", duration: "45 min", price: 4800, category: "Skin", benefits: ["Pigment care", "Radiance", "Even tone"]),
        SalonService(name: "Acne Control Facial", icon: "bandage", duration: "60 min", price: 5000, category: "Skin", benefits: ["Acne care", "Oil control", "Calming"]),
        SalonService(name: "Anti-Aging Facial", icon: "sparkles", duration: "65 min", price: 6200, category: "Skin", benefits: ["Firming", "Fine line care", "Lift effect"]),
        SalonService(name: "Detan Treatment", icon: "sun.haze", duration: "40 min", price: 3800, category: "Skin", benefits: ["Tan removal", "Brightening", "Soft skin"]),
        SalonService(name: "Keratin Hair Treatment", icon: "scissors", duration: "120 min", price: 9800, category: "Hair", benefits: ["Frizz control", "Shine", "Smoothness"]),
        SalonService(name: "Hair Spa", icon: "drop", duration: "60 min", price: 4200, category: "Hair", benefits: ["Scalp health", "Soft hair", "Repair"]),
        SalonService(name: "Protein Hair Mask", icon: "leaf", duration: "50 min", price: 3900, category: "Hair", benefits: ["Strength", "Damage repair", "Moisture"]),
        SalonService(name: "Scalp Detox", icon: "waveform.path.ecg", duration: "45 min", price: 3600, category: "Hair", benefits: ["Deep cleanse", "Oil balance", "Fresh scalp"]),
        SalonService(name: "Dandruff Care", icon: "shield", duration: "40 min", price: 3400, category: "Hair", benefits: ["Flake control", "Scalp soothe", "Healthy roots"]),
        SalonService(name: "Hair Fall Control", icon: "heart.text.square", duration: "55 min", price: 4600, category: "Hair", benefits: ["Root support", "Volume", "Stronger strands"]),
        SalonService(name: "Classic Manicure", icon: "hand.raised", duration: "35 min", price: 2200, category: "Nails", benefits: ["Clean nails", "Soft hands", "Neat finish"]),
        SalonService(name: "Classic Pedicure", icon: "figure.walk", duration: "45 min", price: 2600, category: "Nails", benefits: ["Foot care", "Dead skin removal", "Relaxation"]),
        SalonService(name: "Gel Manicure", icon: "paintbrush", duration: "50 min", price: 3200, category: "Nails", benefits: ["Long wear", "Gloss finish", "Chip resistance"]),
        SalonService(name: "Nail Art Basic", icon: "wand.and.stars", duration: "55 min", price: 3500, category: "Nails", benefits: ["Custom design", "Stylish look", "Unique finish"]),
        SalonService(name: "French Tip Nails", icon: "sparkle.magnifyingglass", duration: "45 min", price: 3000, category: "Nails", benefits: ["Classic style", "Neat edges", "Elegant look"]),
        SalonService(name: "Paraffin Hand Therapy", icon: "flame", duration: "30 min", price: 2500, category: "Nails", benefits: ["Deep moisture", "Soft skin", "Warm relaxation"]),
        SalonService(name: "Cuticle Therapy", icon: "cross.case", duration: "30 min", price: 2100, category: "Nails", benefits: ["Cuticle health", "Nail growth support", "Cleaner base"]),
        SalonService(name: "Nail Strengthening", icon: "shield.lefthalf.filled", duration: "40 min", price: 2800, category: "Nails", benefits: ["Reduced breakage", "Hardening", "Healthy nails"])
    ]

    // Converts the raw services into identifiable entries for lists.
    private var allEntries: [CatalogEntry] {
        comparisonTreatments.map { CatalogEntry(id: $0.id, service: $0) }
    }

    // Finds the indices of the selected treatments that take the least time!
    private var shortestDurationIndices: Set<Int> {
        let mins = store.items.map { lowerDurationBound(for: $0.service) }
        guard let best = mins.filter({ $0 > 0 }).min() else { return [] }
        return Set(mins.indices.filter { mins[$0] == best })
    }

    // Finds the indices of the selected treatments that cost the least!
    private var lowestPriceIndices: Set<Int> {
        let mins = store.items.map { lowerPriceBound(for: $0.service) }
        guard let minP = mins.min() else { return [] }
        return Set(mins.indices.filter { mins[$0] == minP })
    }

    private func benefitCount(_ service: SalonService) -> Int {
        service.benefits.count
    }

    // We add a random margin to simulate a range instead of a fixed number!
    private func lowerDurationBound(for service: SalonService) -> Int {
        max(durationMins(service) - 8, 10)
    }

    private func upperDurationBound(for service: SalonService) -> Int {
        durationMins(service) + 8
    }

    private func durationRange(_ service: SalonService) -> String {
        "\(lowerDurationBound(for: service)) - \(upperDurationBound(for: service)) min"
    }

    private func lowerPriceBound(for service: SalonService) -> Double {
        service.price * 0.9
    }

    private func upperPriceBound(for service: SalonService) -> Double {
        service.price * 1.1
    }

    private func priceRange(_ service: SalonService) -> String {
        let low = Int(lowerPriceBound(for: service))
        let high = Int(upperPriceBound(for: service))
        return "LKR \(low) - \(high)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Page title
                    Text("Treatment Comparison")
                        .glowzaFont(size: 28, weight: .bold)
                        .foregroundColor(appSettings.themeText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)

                    selectSection // The horizontal scroll list to pick treatments.

                    // If user selected 2 or more treatments, show the charts!
                    if store.items.count >= 2 {
                        priceChartCard
                        durationTableCard
                        benefitsTableCard
                        clearBtn
                    } else {
                        // Otherwise, show a banner asking to add more!
                        addMoreBanner
                    }

                    Spacer().frame(height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .background((appSettings.themePage).ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Select Section
    // UI to select treatments from a horizontal scrolling list.
    private var selectSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Select Treatments")
                    .glowzaFont(size: 15, weight: .semibold)
                    .foregroundColor(brand)
                Spacer()
                Text("\(store.items.count)/10") // Limit is 10!
                    .glowzaFont(size: 12, weight: .semibold)
                    .foregroundColor(Color(hex: "8A8A8A"))
            }

            selectedTabsSection // Shows pills for treatments already picked.

            // The list of all available treatments to pick from.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(allEntries) { entry in
                        treatmentTile(entry)
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -20)
        }
    }

    // Shows small removable pills for treatments you already selected.
    private var selectedTabsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.items.isEmpty {
                Text("No treatments selected")
                    .glowzaFont(size: 12, weight: .medium)
                    .foregroundColor(Color(hex: "9A9A9A"))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    store.remove(item)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("\(index + 1)")
                                        .glowzaFont(size: 11, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(width: 18, height: 18)
                                        .background(brand)
                                        .clipShape(Circle())
                                    Text(shortTreatmentName(item.service.name))
                                        .glowzaFont(size: 12, weight: .semibold)
                                        .foregroundColor(appSettings.themeText)
                                    Image(systemName: "xmark")
                                        .glowzaFont(size: 10, weight: .bold)
                                        .foregroundColor(Color(hex: "8A8A8A"))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(appSettings.isDarkMode ? Color(hex: "242424") : Color(hex: "F4F4F7"))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(brand.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // A single square card for a treatment in the selection list.
    private func treatmentTile(_ entry: CatalogEntry) -> some View {
        let added = store.isAdded(entry.service, from: treatmentScopeName)
        let canAdd = store.canAddMore || added

        return Button {
            withAnimation(.spring(response: 0.25)) {
                if added {
                    if let item = store.items.first(where: { $0.service.id == entry.service.id }) {
                        store.remove(item)
                    }
                } else {
                    store.add(service: entry.service, salonName: treatmentScopeName)
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Text(entry.service.name)
                    .glowzaFont(size: 12, weight: .semibold)
                    .foregroundColor(appSettings.themeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(10)
                    .frame(width: 110, height: 68, alignment: .center)

                if added {
                    ZStack {
                        Circle().fill(brand).frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .glowzaFont(size: 9, weight: .bold)
                            .foregroundColor(.white)
                    }
                    .padding(5)
                }
            }
            .frame(width: 110, height: 68)
            .background(added ? brand.opacity(0.06) : (appSettings.themeSurface))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .hcBorder(radius: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        appSettings.isHighContrast ? Color.clear : (added ? brand : Color(hex: "E0E0E0")),
                        lineWidth: appSettings.isHighContrast ? 0 : (added ? 1.5 : 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!canAdd)
        .opacity(!canAdd ? 0.45 : 1)
    }

    // MARK: - Price Chart Card
    // This uses the SwiftUI Charts framework to draw vertical bars comparing prices.
    private var priceChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Price Level")
                .glowzaFont(size: 15, weight: .bold)
                .foregroundColor(appSettings.themeText)

            Chart {
                ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                    BarMark(
                        x: .value("Treatment", shortTreatmentName(item.service.name)),
                        y: .value("Price (LKR)", item.service.price)
                    )
                    // Highlighting the cheapest one in teal!
                    .foregroundStyle(lowestPriceIndices.contains(idx) ? teal : brand.opacity(0.8))
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                        .foregroundStyle(Color(hex: "E0E0E0"))
                    AxisValueLabel {
                        if let d = val.as(Double.self) {
                            Text("\(Int(d / 1000))k") // Formats 5000 as "5k"
                                .glowzaFont(size: 10)
                                .foregroundStyle(Color(hex: "8A8A8A"))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .frame(height: 160)

            // Legend at the bottom of the chart.
            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3).fill(teal).frame(width: 12, height: 8)
                    Text("Best Price").glowzaFont(size: 10)
                }
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3).fill(brand.opacity(0.8)).frame(width: 12, height: 8)
                    Text("Standard").glowzaFont(size: 10)
                }
            }
            .foregroundColor(Color(hex: "8A8A8A"))
        }
        .padding(14)
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .hcBorder(radius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(appSettings.isHighContrast ? Color.clear : Color(hex: "E3E3E8"), lineWidth: appSettings.isHighContrast ? 0 : 1)
        )
    }

    // MARK: - Duration Table Card
    // Compares how long each treatment takes.
    private var durationTableCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Duration")
                .glowzaFont(size: 15, weight: .bold)
                .foregroundColor(appSettings.themeText)

            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("Treatment")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Duration Range")
                        .frame(width: 140, alignment: .trailing)
                }
                .glowzaFont(size: 11, weight: .semibold)
                .foregroundColor(Color(hex: "8A8A8A"))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(hex: "F7F7FA"))

                // Table Rows
                ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                    let isFastest = shortestDurationIndices.contains(idx)

                    HStack {
                        Text(shortTreatmentName(item.service.name))
                            .glowzaFont(size: 12, weight: .medium)
                            .foregroundColor(appSettings.themeText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 6) {
                            if isFastest {
                                Text("Fast")
                                    .glowzaFont(size: 10, weight: .bold)
                                    .foregroundColor(teal)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(teal.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            Text(durationRange(item.service))
                                .glowzaFont(size: 11, weight: isFastest ? .semibold : .regular)
                                .foregroundColor(isFastest ? teal : Color(hex: "505050"))
                        }
                        .frame(width: 140, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)

                    if idx < store.items.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(hex: "E3E3E8"), lineWidth: 1)
            )
        }
        .padding(14)
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .hcBorder(radius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(appSettings.isHighContrast ? Color.clear : Color(hex: "E3E3E8"), lineWidth: appSettings.isHighContrast ? 0 : 1)
        )
    }

    // MARK: - Benefits Table Card
    // Compares the bullet point benefits of each treatment.
    private var benefitsTableCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Benefits")
                .glowzaFont(size: 15, weight: .bold)
                .foregroundColor(appSettings.themeText)

            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("Treatment")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Benefits")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .glowzaFont(size: 11, weight: .semibold)
                .foregroundColor(Color(hex: "8A8A8A"))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(hex: "F7F7FA"))

                // Table Rows
                ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                    let maxBenefits = store.items.map { benefitCount($0.service) }.max() ?? 0
                    let isTop = benefitCount(item.service) == maxBenefits

                    HStack(alignment: .top, spacing: 8) {
                        Text(shortTreatmentName(item.service.name))
                            .glowzaFont(size: 12, weight: .medium)
                            .foregroundColor(appSettings.themeText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Joins array of strings with a dot separator!
                        Text(item.service.benefits.joined(separator: "  •  "))
                            .glowzaFont(size: 11)
                            .foregroundColor(isTop ? teal : Color(hex: "505050"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)

                    if idx < store.items.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(hex: "E3E3E8"), lineWidth: 1)
            )
        }
        .padding(14)
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .hcBorder(radius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(appSettings.isHighContrast ? Color.clear : Color(hex: "E3E3E8"), lineWidth: appSettings.isHighContrast ? 0 : 1)
        )
    }

    // MARK: - Bottom Controls
    private var clearBtn: some View {
        Button { withAnimation { store.clear() } } label: {
            Label("Clear All", systemImage: "trash")
        }
        .buttonStyle(GlowzaSecondaryButtonStyle())
    }

    private var missingSelectionCount: Int {
        max(0, 2 - store.items.count)
    }

    // Banner shown when user needs to select more items.
    private var addMoreBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(brand)
            Text("Select \(missingSelectionCount) more treatment\(missingSelectionCount == 1 ? "" : "s") to compare")
                .glowzaFont(size: 13, weight: .medium)
                .foregroundColor(Color(hex: "1A1A1A"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(brand.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Preview
#Preview {
    CompareView()
        .environment(TreatmentComparisonStore.shared)
}
