import SwiftUI

// MARK: - Constants
private let brand    = Color(hex: "962043")
private let teal     = Color(hex: "00A878")
private let featureW: CGFloat = 110
private let treatW:   CGFloat = 105

// MARK: - Helpers

private struct CatalogEntry: Identifiable {
    let id: UUID
    let service: SalonService
    let salonName: String
}

private func durationMins(_ s: SalonService) -> Int {
    Int(s.duration.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
}

private func categoryIcon(_ cat: String) -> String {
    switch cat {
    case "Skin":      return "face.smiling"
    case "Hair":      return "scissors"
    case "Nails":     return "hand.raised.fill"
    case "Aesthetic": return "sparkles"
    default:          return "tag"
    }
}

// MARK: - CompareView

struct CompareView: View {

    @Environment(TreatmentComparisonStore.self) private var store
    @State private var selectedCategory = "All"

    private let slotColors: [Color] = [
        Color(hex: "962043"), Color(hex: "4A7C9A"),
        Color(hex: "7A4A9A"), Color(hex: "C8860A"),
        Color(hex: "2E8B57"), Color(hex: "B5451B"),
        Color(hex: "1B6BB5"), Color(hex: "8B2E7A"),
        Color(hex: "4A7A2E"), Color(hex: "7A6B1B")
    ]

    // MARK: Data

    private var allEntries: [CatalogEntry] {
        SalonCatalog.shared.salons.flatMap { salon in
            salon.services.map { CatalogEntry(id: $0.id, service: $0, salonName: salon.name) }
        }
    }

    private var categories: [String] {
        ["All"] + Array(Set(allEntries.map { $0.service.category })).sorted()
    }

    private var filtered: [CatalogEntry] {
        selectedCategory == "All"
            ? allEntries
            : allEntries.filter { $0.service.category == selectedCategory }
    }

    private func slotColor(_ idx: Int) -> Color { slotColors[idx % slotColors.count] }

    private var shortestDurationIndices: Set<Int> {
        let mins = store.items.map { durationMins($0.service) }
        guard let best = mins.filter({ $0 > 0 }).min() else { return [] }
        return Set(mins.indices.filter { mins[$0] == best })
    }

    private var lowestPriceIndices: Set<Int> {
        guard let minP = store.items.map(\.service.price).min() else { return [] }
        return Set(store.items.indices.filter { store.items[$0].service.price == minP })
    }

    private func priceRange(_ service: SalonService) -> String {
        let lo = Int(service.price * 0.80)
        let hi = Int(service.price)
        return "LKR \(lo)\nu2013\(hi)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    selectSection

                    if store.items.count >= 2 {
                        comparisonTable
                        recommendationCard
                        clearBtn
                    } else if store.items.count == 1 {
                        addMoreBanner
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Treatment Comparison")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Select Section

    private var selectSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Treatments")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(brand)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { chipBtn($0) }
                }
            }

            let cols = [GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(filtered) { entry in treatmentTile(entry) }
            }
        }
    }

    private func chipBtn(_ cat: String) -> some View {
        let sel = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = cat }
        } label: {
            HStack(spacing: 4) {
                if cat != "All" {
                    Image(systemName: categoryIcon(cat)).font(.system(size: 11))
                }
                Text(cat).font(.system(size: 13, weight: sel ? .semibold : .regular))
            }
            .foregroundColor(sel ? .white : Color(hex: "1A1A1A"))
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(sel ? brand : Color(hex: "F2F2F2"))
            .clipShape(Capsule())
        }
    }

    private func treatmentTile(_ entry: CatalogEntry) -> some View {
        let added  = store.isAdded(entry.service, from: entry.salonName)
        let canAdd = store.canAddMore || added

        return Button {
            withAnimation(.spring(response: 0.25)) {
                if added {
                    if let item = store.items.first(where: {
                        $0.service.id == entry.service.id && $0.salonName == entry.salonName
                    }) { store.remove(item) }
                } else {
                    store.add(service: entry.service, salonName: entry.salonName)
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.service.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(entry.salonName)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)

                if added {
                    ZStack {
                        Circle().fill(brand).frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(10)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(added ? brand : Color(hex: "E0E0E0"),
                                  lineWidth: added ? 2 : 1)
            )
            .shadow(color: added ? brand.opacity(0.10) : Color.black.opacity(0.03),
                    radius: 5, x: 0, y: 2)
        }
        .disabled(!canAdd)
        .opacity(!canAdd ? 0.45 : 1)
    }

    // MARK: - Comparison Table

    private var tableWidth: CGFloat {
        featureW + CGFloat(store.items.count) * treatW
    }

    private var comparisonTable: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                tableHeader
                Divider()
                durationRow
                Divider().padding(.leading, featureW)
                benefitsRow
                Divider().padding(.leading, featureW)
                priceRow
                Divider().padding(.leading, featureW)
                focusRow
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(brand.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Feature")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "8A8A8A"))
                .frame(width: featureW, alignment: .leading)
                .padding(.vertical, 12).padding(.leading, 14)
            ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, _ in
                Text(String(format: "%02d", idx + 1))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "4A90D9"))
                    .frame(width: treatW)
                    .padding(.vertical, 12)
            }
        }
        .frame(minWidth: tableWidth)
        .background(Color(hex: "F9F9F9"))
    }

    private var durationRow: some View {
        HStack(alignment: .top, spacing: 0) {
            featureCell(icon: "clock", label: "Duration", sublabel: "Session total")
            ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                let best = shortestDurationIndices.contains(idx)
                VStack(spacing: 5) {
                    Text(item.service.duration)
                        .font(.system(size: 12, weight: best ? .semibold : .regular))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .multilineTextAlignment(.center)
                    if best {
                        Text("Recommended")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(teal)
                            .clipShape(Capsule())
                    }
                }
                .frame(width: treatW)
                .padding(.vertical, 14)
            }
        }
        .frame(minWidth: tableWidth)
    }

    private var benefitsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            featureCell(icon: "sparkles", label: "Benefits", sublabel: nil)
            ForEach(Array(store.items.enumerated()), id: \.element.id) { _, item in
                VStack(spacing: 4) {
                    if item.service.benefits.isEmpty {
                        Text("—").font(.system(size: 11)).foregroundColor(Color(hex: "CCCCCC"))
                    } else {
                        ForEach(item.service.benefits.prefix(3), id: \.self) { b in
                            Text(b)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(teal)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(teal.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(width: treatW)
                .padding(.vertical, 12)
            }
        }
        .frame(minWidth: tableWidth)
    }

    private var priceRow: some View {
        HStack(alignment: .top, spacing: 0) {
            featureCell(icon: "banknote", label: "Price", sublabel: nil)
            ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                let isLowest = lowestPriceIndices.contains(idx)
                Text(priceRange(item.service))
                    .font(.system(size: 11, weight: isLowest ? .semibold : .regular))
                    .foregroundColor(isLowest ? teal : Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
                    .frame(width: treatW)
                    .padding(.vertical, 14)
            }
        }
        .frame(minWidth: tableWidth)
    }

    private var focusRow: some View {
        HStack(alignment: .top, spacing: 0) {
            featureCell(icon: "tag", label: "Focus", sublabel: nil)
            ForEach(store.items, id: \.id) { item in
                Text(item.service.category)
                    .font(.system(size: 12).italic())
                    .foregroundColor(Color(hex: "8A8A8A"))
                    .multilineTextAlignment(.center)
                    .frame(width: treatW)
                    .padding(.vertical, 14)
            }
        }
        .frame(minWidth: tableWidth)
    }

    private func featureCell(icon: String, label: String, sublabel: String?) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8A8A8A"))
                .frame(width: 16).padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                if let sub = sublabel {
                    Text(sub).font(.system(size: 10))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
            }
        }
        .frame(width: featureW, alignment: .leading)
        .padding(.vertical, 14).padding(.leading, 14)
    }

    // MARK: - Recommendation Card

    private var recommendationCard: some View {
        Group {
            if let best = store.items.min(by: { $0.service.price < $1.service.price }) {
                let maxP   = store.items.map(\.service.price).max() ?? 0
                let saving = maxP - best.service.price

                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(teal.opacity(0.12)).frame(width: 44, height: 44)
                        Image(systemName: best.service.icon)
                            .font(.system(size: 20)).foregroundColor(teal)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11)).foregroundColor(teal)
                            Text("Best Value")
                                .font(.system(size: 11, weight: .bold)).foregroundColor(teal)
                        }
                        Text(best.service.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Text("at \(best.salonName)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("LKR \(Int(best.service.price))")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(teal)
                        if saving > 0 {
                            Text("Save LKR \(Int(saving))")
                                .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(teal).clipShape(Capsule())
                        }
                    }
                }
                .padding(14)
                .background(Color(hex: "F0FBF7"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(teal.opacity(0.25), lineWidth: 1.5)
                )
            }
        }
    }

    // MARK: - Bottom Controls

    private var clearBtn: some View {
        Button { withAnimation { store.clear() } } label: {
            Label("Clear All", systemImage: "trash")
                .font(.system(size: 14, weight: .semibold)).foregroundColor(brand)
                .frame(maxWidth: .infinity).frame(height: 46)
                .background(brand.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(brand.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var addMoreBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(brand)
            Text("Select 1 more treatment to start comparing")
                .font(.system(size: 13, weight: .medium))
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
