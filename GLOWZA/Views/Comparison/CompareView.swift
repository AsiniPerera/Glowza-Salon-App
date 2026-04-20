import SwiftUI



private struct CatalogEntry: Identifiable {
    let id: UUID  // same as service.id — stable for app lifetime
    let service: SalonService
    let salonName: String
}



struct CompareView: View {

    @Environment(TreatmentComparisonStore.self) private var store
    @State private var selectedCategory = "All"

    private let slotColors: [Color] = [
        Color(hex: "C8860A"), Color(hex: "9A6E4A"),
        Color(hex: "4A7C9A"), Color(hex: "7A4A9A")
    ]

    // All services from all salons as a flat list
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    selectionSection

                    if !store.items.isEmpty {
                        sectionDivider
                        comparisonSection
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "FAF7F2").ignoresSafeArea())
            .navigationTitle("Treatment Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "FAF7F2"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color(hex: "E0D4C4")).frame(height: 1)
            Image(systemName: "arrow.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "C8860A"))
            Rectangle().fill(Color(hex: "E0D4C4")).frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: ── STEP 1: Select Treatments ──────────────────────────────────

    private var selectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color(hex: "C8860A").opacity(0.12)).frame(width: 30, height: 30)
                            Text("1").font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: "C8860A"))
                        }
                        Text("Select Treatments")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                    }
                    Text("Tap + to add up to 4 treatments")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A8A8A"))
                        .padding(.leading, 38)
                }
                Spacer()
                if !store.items.isEmpty {
                    ZStack {
                        Circle().fill(Color(hex: "C8860A")).frame(width: 34, height: 34)
                        Text("\(store.items.count)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)

            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.self) { cat in
                        categoryChip(cat)
                    }
                }
                .padding(.horizontal, 20)
            }

            // Treatment rows
            VStack(spacing: 10) {
                ForEach(filtered) { entry in
                    selectionRow(entry)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func categoryChip(_ cat: String) -> some View {
        let selected = selectedCategory == cat
        return Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = cat } }) {
            HStack(spacing: 5) {
                if cat != "All" {
                    Image(systemName: categoryIcon(cat))
                        .font(.system(size: 11))
                }
                Text(cat)
                    .font(.system(size: 13, weight: selected ? .bold : .regular))
            }
            .foregroundColor(selected ? .white : Color(hex: "4A3828"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Color(hex: "C8860A") : Color(hex: "F0E9DF"))
            .clipShape(Capsule())
        }
    }

    private func selectionRow(_ entry: CatalogEntry) -> some View {
        let added   = store.isAdded(entry.service, from: entry.salonName)
        let canAdd  = store.canAddMore || added

        return HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(added ? Color(hex: "C8860A").opacity(0.12) : Color(hex: "F0E9DF"))
                    .frame(width: 46, height: 46)
                Image(systemName: entry.service.icon)
                    .font(.system(size: 19))
                    .foregroundColor(added ? Color(hex: "C8860A") : Color(hex: "9A8A7A"))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.service.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                HStack(spacing: 6) {
                    Text(entry.salonName)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Text("·").foregroundColor(Color(hex: "D0C4B0"))
                    Label(entry.service.duration, systemImage: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                Text(entry.service.category)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(hex: "C8860A"))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color(hex: "E5A820").opacity(0.10))
                    .clipShape(Capsule())
            }

            Spacer()

            // Price + toggle
            VStack(alignment: .trailing, spacing: 6) {
                Text("LKR \(Int(entry.service.price))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(added ? Color(hex: "C8860A") : Color(hex: "1A1A1A"))

                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        if added {
                            if let item = store.items.first(where: {
                                $0.service.id == entry.service.id && $0.salonName == entry.salonName
                            }) { store.remove(item) }
                        } else {
                            store.add(service: entry.service, salonName: entry.salonName)
                        }
                    }
                }) {
                    Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 28))
                        .foregroundColor(
                            added   ? Color(hex: "C8860A") :
                            canAdd  ? Color(hex: "C8C0B4") :
                                      Color(hex: "E0DCDA")
                        )
                }
                .disabled(!canAdd)
            }
        }
        .padding(12)
        .background(added ? Color(hex: "FFF8EE") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(added ? Color(hex: "C8860A").opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(added ? 0.06 : 0.03), radius: 6, x: 0, y: 2)
    }

    // MARK: ── STEP 2: Comparison Results ─────────────────────────────────

    private var comparisonSection: some View {
        VStack(spacing: 24) {
            // Step 2 header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color(hex: "C8860A").opacity(0.12)).frame(width: 30, height: 30)
                            Text("2").font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: "C8860A"))
                        }
                        Text("Comparison")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                    }
                    Text("Side-by-side results for selected treatments")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A8A8A"))
                        .padding(.leading, 38)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            if store.items.count < 2 {
                addMoreBanner
            } else {
                selectedStrip
                priceChart
                comparisonTable
                bestValueCard
                clearButton
            }
        }
    }

    // Selected treatment pills strip
    private var selectedStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                    selectedPill(item, color: slotColors[idx % slotColors.count])
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }

    private func selectedPill(_ item: SelectedTreatment, color: Color) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 26, height: 26)
                Image(systemName: item.service.icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.service.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .lineLimit(1)
                Text(item.salonName)
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            Button(action: { withAnimation { store.remove(item) } }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(color.opacity(0.55))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.2), lineWidth: 1))
    }

    private var addMoreBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(Color(hex: "E5A820"))
            Text("Select 1 more treatment above to start comparing")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "4A3828"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "E5A820").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: - Price Bar Chart

    private var priceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Price Comparison")
            let maxPrice = store.items.map(\.service.price).max() ?? 1
            VStack(spacing: 0) {
                ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                    let best     = isBest(item)
                    let color    = slotColors[idx % slotColors.count]
                    let fraction = CGFloat(item.service.price / maxPrice)
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.service.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                                .lineLimit(1)
                            Text(item.salonName)
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "8A8A8A"))
                                .lineLimit(1)
                        }
                        .frame(width: 100, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6).fill(Color(hex: "F0E9DF")).frame(height: 22)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        best
                                        ? LinearGradient(colors: [Color(hex: "2ECC71"), Color(hex: "27AE60")],
                                                         startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [color.opacity(0.65), color],
                                                         startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(width: max(geo.size.width * fraction, 28), height: 22)
                            }
                        }
                        .frame(height: 22)
                        Text("LKR \(Int(item.service.price))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(best ? Color(hex: "1E8449") : color)
                            .frame(width: 68, alignment: .trailing)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    if idx < store.items.count - 1 { Divider().padding(.leading, 16) }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Side-by-Side Details")
            let lowestPrice = store.items.map(\.service.price).min() ?? 0
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("Detail")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "8A8A8A"))
                        .frame(width: 86, alignment: .leading)
                        .padding(.vertical, 10).padding(.leading, 14)
                    ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle().fill(slotColors[idx % slotColors.count].opacity(0.14))
                                    .frame(width: 28, height: 28)
                                Image(systemName: item.service.icon)
                                    .font(.system(size: 13))
                                    .foregroundColor(slotColors[idx % slotColors.count])
                            }
                            Text(item.service.name)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "2C2420"))
                                .multilineTextAlignment(.center).lineLimit(2)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10).padding(.horizontal, 4)
                    }
                }
                .background(Color(hex: "F8F3EC"))
                Divider()
                tRow(label: "Salon",     cols: store.items.map { $0.salonName },              highlights: [])
                Divider().padding(.leading, 86)
                tRow(label: "Category",  cols: store.items.map { $0.service.category },        highlights: [])
                Divider().padding(.leading, 86)
                tRow(label: "Duration",  cols: store.items.map { $0.service.duration },        highlights: shortestDurationIndices)
                Divider().padding(.leading, 86)
                tRow(label: "Price",     cols: store.items.map { "LKR \(Int($0.service.price))" },
                     highlights: Set(store.items.indices.filter { store.items[$0].service.price == lowestPrice }))
                Divider().padding(.leading, 86)
                tRow(label: "LKR / min", cols: store.items.map { valuePerMin($0.service) },   highlights: bestValuePerMinIndices)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)

            HStack(spacing: 5) {
                Circle().fill(Color(hex: "C8860A")).frame(width: 8, height: 8)
                Text("Gold = best price · shortest duration · best LKR per minute")
                    .font(.system(size: 10)).foregroundColor(Color(hex: "8A8A8A"))
            }
            .padding(.horizontal, 20)
        }
    }

    private func tRow(label: String, cols: [String], highlights: Set<Int>) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 11, weight: .medium)).foregroundColor(Color(hex: "8A8A8A"))
                .frame(width: 86, alignment: .leading)
                .padding(.vertical, 12).padding(.leading, 14)
            ForEach(cols.indices, id: \.self) { i in
                let hi = highlights.contains(i)
                Text(cols[i])
                    .font(.system(size: 11, weight: hi ? .bold : .regular))
                    .foregroundColor(hi ? Color(hex: "C8860A") : Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12).padding(.horizontal, 4)
                    .background(hi ? Color(hex: "E5A820").opacity(0.08) : Color.clear)
            }
        }
    }

    // MARK: - Best Value Card

    private var bestValueCard: some View {
        Group {
            if let best = store.items.min(by: { $0.service.price < $1.service.price }) {
                let maxPrice = store.items.map(\.service.price).max() ?? 0
                let saving   = maxPrice - best.service.price
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Our Recommendation")
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color(hex: "27AE60").opacity(0.12)).frame(width: 56, height: 56)
                            Image(systemName: best.service.icon)
                                .font(.system(size: 24)).foregroundColor(Color(hex: "1E8449"))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13)).foregroundColor(Color(hex: "27AE60"))
                                Text("Best Value Pick")
                                    .font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: "27AE60"))
                            }
                            Text(best.service.name)
                                .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                            Text("at \(best.salonName)")
                                .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("LKR \(Int(best.service.price))")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1E8449"))
                            if saving > 0 {
                                Text("Save LKR \(Int(saving))")
                                    .font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color(hex: "27AE60")).clipShape(Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "F0FBF4"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(hex: "27AE60").opacity(0.25), lineWidth: 1.5))
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Clear button

    private var clearButton: some View {
        Button(action: { withAnimation { store.clear() } }) {
            Label("Clear All Treatments", systemImage: "trash")
                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(Color(hex: "C8860A"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 16, weight: .bold))
            .foregroundColor(Color(hex: "1A1A1A")).padding(.horizontal, 20)
    }

    private func isBest(_ item: SelectedTreatment) -> Bool {
        guard let min = store.items.map(\.service.price).min() else { return false }
        return item.service.price == min
    }

    private func durationMins(_ service: SalonService) -> Int {
        let digits = service.duration
            .components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits) ?? 0
    }

    private func valuePerMin(_ service: SalonService) -> String {
        let mins = durationMins(service)
        guard mins > 0 else { return "—" }
        return String(format: "LKR %.0f", service.price / Double(mins))
    }

    private var shortestDurationIndices: Set<Int> {
        let mins = store.items.map { durationMins($0.service) }
        guard let best = mins.filter({ $0 > 0 }).min() else { return [] }
        return Set(mins.indices.filter { mins[$0] == best })
    }

    private var bestValuePerMinIndices: Set<Int> {
        let vpms = store.items.map { item -> Double in
            let m = durationMins(item.service)
            return m > 0 ? item.service.price / Double(m) : Double.greatestFiniteMagnitude
        }
        guard let best = vpms.min() else { return [] }
        return Set(vpms.indices.filter { vpms[$0] == best })
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Skin":      return "face.smiling"
        case "Hair":      return "scissors"
        case "Nails":     return "hand.raised.fill"
        case "Aesthetic": return "sparkles"
        default:          return "tag"
        }
    }
}

#Preview {
    CompareView()
        .environment(TreatmentComparisonStore.shared)
}
