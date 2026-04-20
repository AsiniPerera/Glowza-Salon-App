import SwiftUI

// MARK: - Saved Card model
private struct SavedCard: Identifiable {
    let id = UUID()
    let brand: String   // "mastercard" | "visa"
    let last4: String
    let holder: String
    let expiry: String
}

// MARK: - Top-level payment method choice
private enum TopPaymentChoice: Hashable {
    case card, applePay, googlePay
}

// MARK: - PaymentView

struct PaymentView: View {

    @Binding var draft: BookingDraft
    let onPay: (Booking) -> Void
    let onBack: () -> Void

    // Card state
    @State private var topChoice: TopPaymentChoice = .card
    @State private var savedCards: [SavedCard] = [
        SavedCard(brand: "mastercard", last4: "2345", holder: "Asini Perera", expiry: "09/27"),
        SavedCard(brand: "visa",       last4: "3456", holder: "Asini Perera", expiry: "12/26"),
    ]
    @State private var selectedCardID: UUID? = nil

    // Sheets & overlays
    @State private var showAddCard   = false
    @State private var isPaying      = false
    @State private var paySuccess    = false

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var total: Double { service.price }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                flowHeader(title: "Select Payment Method", subtitle: "", onBack: onBack)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        bookingSummaryCard
                        cardSection
                        applePaySection
                        googlePaySection
                        priceBreakdownCard
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }

                // Pay Now
                Button(action: processPayment) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill").font(.system(size: 14))
                        Text("Pay LKR \(Int(total))")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(
                        LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(hex: "E5A820").opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .disabled(isPaying)
                .padding(.horizontal, 20).padding(.vertical, 16)
                .background(Color.glowzaBackground)
            }
            .background(Color.glowzaBackground.ignoresSafeArea())
            .blur(radius: isPaying ? 4 : 0)
            .allowsHitTesting(!isPaying)

            // Processing overlay
            if isPaying {
                processingOverlay
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardSheet { newCard in
                savedCards.append(newCard)
                selectedCardID = newCard.id
                showAddCard = false
            }
        }
        .onAppear { selectedCardID = savedCards.first?.id }
    }

    // MARK: - Booking Summary Card

    private var bookingSummaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "E5A820").opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: service.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "C8860A"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(service.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.glowzaDark)
                Text(draft.salon.name)
                    .font(.system(size: 12))
                    .foregroundColor(Color.glowzaSubtext)
                HStack(spacing: 6) {
                    Label(draft.date.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                    Text("·")
                    Text(draft.timeSlot)
                }
                .font(.system(size: 11))
                .foregroundColor(Color.glowzaSubtext)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("LKR")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "C8860A"))
                Text("\(Int(total))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "C8860A"))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(hex: "E5A820").opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Credit / Debit Card Section

    private var cardSection: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { topChoice = .card } }) {
                HStack(spacing: 12) {
                    radioCircle(selected: topChoice == .card)
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 15))
                        .foregroundColor(topChoice == .card ? Color(hex: "C8860A") : Color.glowzaSubtext)
                    Text("Credit / Debit Card")
                        .font(.system(size: 15, weight: topChoice == .card ? .semibold : .regular))
                        .foregroundColor(Color.glowzaDark)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())

            if topChoice == .card {
                Divider().padding(.horizontal, 16)

                ForEach(savedCards) { card in
                    savedCardRow(card)
                    if card.id != savedCards.last?.id {
                        Divider().padding(.leading, 72)
                    }
                }

                Divider().padding(.horizontal, 16)

                // Add Card
                Button(action: { showAddCard = true }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E5A820").opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "C8860A"))
                        }
                        Text("Add New Card")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "C8860A"))
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(topChoice == .card ? Color(hex: "C8860A").opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func savedCardRow(_ card: SavedCard) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedCardID = card.id } }) {
            HStack(spacing: 12) {
                cardBrandBadge(brand: card.brand)

                VStack(alignment: .leading, spacing: 2) {
                    Text("•••• •••• •••• \(card.last4)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.glowzaDark)
                    Text("\(card.holder)  ·  \(card.expiry)")
                        .font(.system(size: 11))
                        .foregroundColor(Color.glowzaSubtext)
                }

                Spacer()

                radioCircle(selected: selectedCardID == card.id && topChoice == .card)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func cardBrandBadge(brand: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(brand == "visa" ? Color(hex: "1A1F71") : Color.white)
                .frame(width: 46, height: 30)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
            if brand == "mastercard" {
                HStack(spacing: -8) {
                    Circle().fill(Color(hex: "EB001B")).frame(width: 18, height: 18)
                    Circle().fill(Color(hex: "F79E1B")).frame(width: 18, height: 18)
                }
            } else {
                Text("VISA")
                    .font(.system(size: 11, weight: .black, design: .serif))
                    .foregroundColor(.white)
                    .italic()
            }
        }
    }

    // MARK: - Apple Pay

    private var applePaySection: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { topChoice = .applePay } }) {
            HStack(spacing: 12) {
                radioCircle(selected: topChoice == .applePay)
                Text("Apple Pay")
                    .font(.system(size: 15, weight: topChoice == .applePay ? .semibold : .regular))
                    .foregroundColor(Color.glowzaDark)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black).frame(width: 54, height: 30)
                    HStack(spacing: 2) {
                        Image(systemName: "applelogo").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                        Text("Pay").font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(topChoice == .applePay ? Color(hex: "C8860A").opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Google Pay

    private var googlePaySection: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { topChoice = .googlePay } }) {
            HStack(spacing: 12) {
                radioCircle(selected: topChoice == .googlePay)
                Text("Google Pay")
                    .font(.system(size: 15, weight: topChoice == .googlePay ? .semibold : .regular))
                    .foregroundColor(Color.glowzaDark)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white).frame(width: 54, height: 30)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(hex: "DADCE0"), lineWidth: 1))
                    HStack(spacing: 2) {
                        Text("G")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "4285F4"), Color(hex: "34A853"),
                                             Color(hex: "FBBC04"), Color(hex: "EA4335")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        Text("Pay").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "3C4043"))
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(topChoice == .googlePay ? Color(hex: "C8860A").opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Price Breakdown

    private var priceBreakdownCard: some View {
        VStack(spacing: 0) {
            priceRow(icon: "tag",              label: "Service Fee",  value: "LKR \(Int(service.price))", highlight: false)
            Divider().padding(.horizontal, 16)
            priceRow(icon: "calendar.badge.plus", label: "Booking Fee", value: "Free",                   highlight: false)
            Divider().padding(.horizontal, 16)
            priceRow(icon: "percent",          label: "Tax (0%)",     value: "LKR 0",                    highlight: false)
            Divider().padding(.horizontal, 16)
            HStack {
                Text("Total")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(Color.glowzaDark)
                Spacer()
                Text("LKR \(Int(total))")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "C8860A"))
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func priceRow(icon: String, label: String, value: String, highlight: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "C8860A").opacity(0.7))
                .frame(width: 18)
            Text(label)
                .font(.system(size: 13)).foregroundColor(Color.glowzaSubtext)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: highlight ? .bold : .medium))
                .foregroundColor(highlight ? Color(hex: "C8860A") : Color.glowzaDark)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "E5A820").opacity(0.2), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                           startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .modifier(SpinModifier())
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "C8860A"))
                }
                VStack(spacing: 6) {
                    Text("Processing Payment")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("Please wait…")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(36)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    // MARK: - Helpers

    private func radioCircle(selected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(selected ? Color(hex: "C8860A") : Color(hex: "C8C0B4"),
                              lineWidth: selected ? 2 : 1.5)
                .frame(width: 22, height: 22)
            if selected {
                Circle().fill(Color(hex: "C8860A")).frame(width: 11, height: 11)
            }
        }
    }

    // MARK: - Process Payment

    private func processPayment() {
        let method: PaymentMethodType
        switch topChoice {
        case .card:      method = .card
        case .applePay:  method = .online
        case .googlePay: method = .online
        }
        draft.paymentMethod = method

        withAnimation(.easeInOut(duration: 0.3)) { isPaying = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let booking = Booking(
                id: UUID(),
                salon: draft.salon,
                service: service,
                date: draft.date,
                timeSlot: draft.timeSlot,
                receiptNumber: Booking.generateReceiptNumber(),
                paymentMethod: method,
                amountPaid: total,
                signatureImage: draft.signatureImage,
                status: .upcoming,
                review: nil
            )
            withAnimation { isPaying = false }
            onPay(booking)
        }
    }
}

// MARK: - Spin animation modifier

private struct SpinModifier: ViewModifier {
    @State private var angle: Double = 0
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}



private struct AddCardSheet: View {

    let onSave: (SavedCard) -> Void

    @State private var cardNumber  = ""
    @State private var holderName  = ""
    @State private var expiry      = ""
    @State private var cvv         = ""
    @State private var isSaving    = false
    @Environment(\.dismiss) private var dismiss

    private var detectedBrand: String {
        let digits = cardNumber.filter(\.isNumber)
        if digits.hasPrefix("4") { return "visa" }
        if digits.hasPrefix("5") || digits.hasPrefix("2") { return "mastercard" }
        return "unknown"
    }

    private var last4: String {
        let digits = cardNumber.filter(\.isNumber)
        return digits.count >= 4 ? String(digits.suffix(4)) : "----"
    }

    private var isValid: Bool {
        cardNumber.filter(\.isNumber).count == 16 &&
        !holderName.trimmingCharacters(in: .whitespaces).isEmpty &&
        expiry.count == 5 &&
        (cvv.count == 3 || cvv.count == 4)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FAF7F2").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Live card preview
                        cardPreview

                        // Form fields
                        VStack(spacing: 14) {
                            fieldRow(icon: "creditcard",  label: "Card Number",   placeholder: "0000 0000 0000 0000") {
                                TextField("", text: $cardNumber)
                                    .keyboardType(.numberPad)
                                    .onChange(of: cardNumber) { _, v in cardNumber = formatCardNumber(v) }
                            }
                            fieldRow(icon: "person",      label: "Name on Card",  placeholder: "Full name as on card") {
                                TextField("", text: $holderName)
                                    .textContentType(.name)
                                    .autocorrectionDisabled()
                            }
                            HStack(spacing: 12) {
                                fieldRow(icon: "calendar", label: "Expiry",        placeholder: "MM/YY") {
                                    TextField("", text: $expiry)
                                        .keyboardType(.numberPad)
                                        .onChange(of: expiry) { _, v in expiry = formatExpiry(v) }
                                }
                                fieldRow(icon: "lock",     label: "CVV",           placeholder: "•••") {
                                    SecureField("", text: $cvv)
                                        .keyboardType(.numberPad)
                                        .onChange(of: cvv) { _, v in if v.count > 4 { cvv = String(v.prefix(4)) } }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Security note
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Color(hex: "27AE60"))
                                .font(.system(size: 13))
                            Text("Your card details are encrypted and never stored on our servers.")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "8A8A8A"))
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .background(Color(hex: "27AE60").opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 20)

                        // Save button
                        Button(action: saveCard) {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Save Card")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(
                                LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                               startPoint: .leading, endPoint: .trailing)
                                    .opacity(isValid ? 1 : 0.45)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(!isValid || isSaving)
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "C8860A"))
                }
            }
        }
    }

    // Live card preview
    private var cardPreview: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: detectedBrand == "visa"
                            ? [Color(hex: "1A1F71"), Color(hex: "2E3AA8")]
                            : detectedBrand == "mastercard"
                            ? [Color(hex: "3D2E18"), Color(hex: "7A5A2E")]
                            : [Color(hex: "2C2C2C"), Color(hex: "555555")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(height: 175)

            // Decorative circles
            Circle().fill(Color.white.opacity(0.06)).frame(width: 150).offset(x: 220, y: -50)
            Circle().fill(Color.white.opacity(0.06)).frame(width: 120).offset(x: 270, y: 60)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("GLOWZA").font(.system(size: 13, weight: .bold)).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if detectedBrand == "mastercard" {
                        HStack(spacing: -8) {
                            Circle().fill(Color(hex: "EB001B")).frame(width: 28, height: 28)
                            Circle().fill(Color(hex: "F79E1B").opacity(0.9)).frame(width: 28, height: 28)
                        }
                    } else if detectedBrand == "visa" {
                        Text("VISA").font(.system(size: 18, weight: .black, design: .serif))
                            .foregroundColor(.white).italic()
                    } else {
                        Image(systemName: "creditcard.fill").foregroundColor(.white.opacity(0.5))
                    }
                }

                Text(cardNumber.isEmpty ? "0000 0000 0000 0000" : cardNumber)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .kerning(2)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARD HOLDER").font(.system(size: 8)).foregroundColor(.white.opacity(0.6)).kerning(1)
                        Text(holderName.isEmpty ? "Full Name" : holderName.uppercased())
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("EXPIRES").font(.system(size: 8)).foregroundColor(.white.opacity(0.6)).kerning(1)
                        Text(expiry.isEmpty ? "MM/YY" : expiry)
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    }
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private func fieldRow<F: View>(icon: String, label: String, placeholder: String, @ViewBuilder field: () -> F) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "8A8A8A"))
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "C8860A"))
                    .frame(width: 18)
                field()
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "1A1A1A"))
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(hex: "E5A820").opacity(0.3), lineWidth: 1)
            )
        }
    }

    // Formatters
    private func formatCardNumber(_ input: String) -> String {
        let digits = input.filter(\.isNumber).prefix(16)
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && i % 4 == 0 { result += " " }
            result.append(ch)
        }
        return result
    }

    private func formatExpiry(_ input: String) -> String {
        let digits = input.filter(\.isNumber).prefix(4)
        if digits.count <= 2 { return String(digits) }
        return String(digits.prefix(2)) + "/" + String(digits.dropFirst(2))
    }

    private func saveCard() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let card = SavedCard(
                brand: detectedBrand == "unknown" ? "visa" : detectedBrand,
                last4: last4,
                holder: holderName.trimmingCharacters(in: .whitespaces),
                expiry: expiry
            )
            isSaving = false
            onSave(card)
        }
    }
}
