import SwiftUI

struct PaymentView: View {
    @Binding var draft: BookingDraft
    let onPay: (Booking) -> Void
    let onBack: () -> Void

    @State private var showCardEntry = false
    @State private var selectedCardIndex: Int? = nil
    @Environment(AppSettings.self) private var appSettings

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var total: Double { service.price }

    private var canConfirm: Bool {
        switch draft.paymentMethod {
        case .card: return selectedCardIndex != nil
        case .cash, .online: return true
        }
    }

    var body: some View {
        if showCardEntry {
            CardEntryView(
                draft: $draft,
                selectedCardIndex: $selectedCardIndex,
                onBack: { showCardEntry = false },
                onContinue: {
                    showCardEntry = false
                    confirmPayment()
                }
            )
        } else {
            mainPaymentView
        }
    }

    private var mainPaymentView: some View {
        ZStack(alignment: .bottom) {
            appSettings.themePage.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Back button
                    Button(action: onBack) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F2F2F7"))
                                .frame(width: 36, height: 36)
                            Image(systemName: "chevron.left")
                                .glowzaFont(size: 14, weight: .semibold)
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment")
                            .glowzaFont(size: 16, weight: .semibold)
                            .foregroundColor(Color(hex: "1C1C1E"))
                        Text("Select payment method")
                            .glowzaFont(size: 15)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // MARK: Amount summary
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("TOTAL DUE")
                                .glowzaFont(size: 11, weight: .semibold)
                                .foregroundColor(Color(hex: "8E8E93"))
                                .tracking(0.5)
                            Text("LKR \(Int(total))")
                                .glowzaFont(size: 26, weight: .bold)
                                .foregroundColor(.glowzaPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(service.name)
                                .glowzaFont(size: 14, weight: .semibold)
                                .foregroundColor(Color(hex: "1C1C1E"))
                            Text(service.duration)
                                .glowzaFont(size: 13)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 28)

                    // MARK: Payment method selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .glowzaFont(size: 11, weight: .semibold)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)
                            .padding(.horizontal, 24)

                        VStack(spacing: 10) {
                            // Card button
                            Button(action: {
                                draft.paymentMethod = .card
                                showCardEntry = true
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(draft.paymentMethod == .card ? Color.glowzaPrimary : Color(hex: "F2F2F7"))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "creditcard.fill")
                                            .glowzaFont(size: 20, weight: .semibold)
                                            .foregroundColor(draft.paymentMethod == .card ? .white : Color.glowzaPrimary)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Credit / Debit Card")
                                            .glowzaFont(size: 15, weight: .semibold)
                                            .foregroundColor(Color(hex: "1C1C1E"))
                                        Text("Visa, Mastercard, AMEX")
                                            .glowzaFont(size: 12)
                                            .foregroundColor(Color(hex: "8E8E93"))
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .strokeBorder(draft.paymentMethod == .card ? Color.glowzaPrimary : Color(hex: "D1D1D6"), lineWidth: 2)
                                            .frame(width: 22, height: 22)
                                        if draft.paymentMethod == .card {
                                            Circle()
                                                .fill(Color.glowzaPrimary)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(draft.paymentMethod == .card ? Color.glowzaPrimary.opacity(0.06) : appSettings.themeSurface)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(draft.paymentMethod == .card ? Color.glowzaPrimary : Color(hex: "E5E5EA"),
                                                lineWidth: draft.paymentMethod == .card ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: draft.paymentMethod)

                            // Cash button
                            methodButton(.cash)

                            // Online banking button
                            methodButton(.online)
                        }
                        .padding(.horizontal, 24)
                    }

                    // MARK: Online banking info
                    if draft.paymentMethod == .online {
                        Spacer().frame(height: 24)
                        infoMessage(
                            icon: "building.columns.fill",
                            title: "Online Banking Redirect",
                            text: "You'll be securely redirected to your bank's payment gateway to complete the transaction.",
                            color: Color(hex: "007AFF")
                        )
                        .padding(.horizontal, 24)
                    }

                    // MARK: Cash info
                    if draft.paymentMethod == .cash {
                        Spacer().frame(height: 24)
                        infoMessage(
                            icon: "banknote.fill",
                            title: "Pay at Salon",
                            text: "Please bring the exact amount (LKR \(Int(total))). Payment is due before your treatment begins.",
                            color: Color(hex: "34C759")
                        )
                        .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 120)
                }
            }

            // MARK: Confirm button pinned to bottom
            VStack(spacing: 0) {
                Divider().opacity(0.5)
                Button(action: confirmPayment) {
                    Text(confirmButtonText)
                        .glowzaFont(size: 16, weight: .semibold)
                        .foregroundColor(.white)
                }
                .frame(width: 330, height: 55)
                .background(canConfirm ? Color.glowzaPrimary : Color(hex: "D4829E"))
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                .disabled(!canConfirm)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(appSettings.themeSurface)
        }
        .navigationBarHidden(true)
    }

    private func methodButton(_ method: PaymentMethodType) -> some View {
        let isSelected = draft.paymentMethod == method

        return Button(action: { draft.paymentMethod = method }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.glowzaPrimary : Color(hex: "F2F2F7"))
                        .frame(width: 48, height: 48)
                    Image(systemName: method.icon)
                        .glowzaFont(size: 20, weight: .semibold)
                        .foregroundColor(isSelected ? .white : Color.glowzaPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(method.rawValue)
                        .glowzaFont(size: 15, weight: .semibold)
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Text(methodSubtitle(method))
                        .glowzaFont(size: 12)
                        .foregroundColor(Color(hex: "8E8E93"))
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.glowzaPrimary : Color(hex: "D1D1D6"), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.glowzaPrimary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.glowzaPrimary.opacity(0.06) : Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.glowzaPrimary : Color(hex: "E5E5EA"),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func infoMessage(icon: String, title: String, text: String, color: Color = .glowzaPrimary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .glowzaFont(size: 16, weight: .semibold)
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .glowzaFont(size: 14, weight: .semibold)
                    .foregroundColor(Color(hex: "1C1C1E"))
                Text(text)
                    .glowzaFont(size: 13)
                    .foregroundColor(Color(hex: "8E8E93"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(color.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private var confirmButtonText: String {
        switch draft.paymentMethod {
        case .card:   return "Pay LKR \(Int(total))"
        case .cash:   return "Confirm Booking"
        case .online: return "Continue to Bank"
        }
    }

    private func methodSubtitle(_ method: PaymentMethodType) -> String {
        switch method {
        case .card:   return "Visa, Mastercard, AMEX"
        case .cash:   return "Pay at salon"
        case .online: return "All major banks"
        }
    }

    private func confirmPayment() {
        let booking = Booking(
            id: UUID(),
            salon: draft.salon,
            service: service,
            date: draft.date,
            timeSlot: draft.timeSlot,
            receiptNumber: Booking.generateReceiptNumber(),
            paymentMethod: draft.paymentMethod,
            amountPaid: total,
            signatureImage: draft.signatureImage,
            status: .upcoming,
            review: nil
        )

        onPay(booking)
    }
}

// MARK: - Card Entry View
struct CardEntryView: View {
    @Binding var draft: BookingDraft
    @Binding var selectedCardIndex: Int?
    let onBack: () -> Void
    let onContinue: () -> Void

    @Environment(AppSettings.self) private var appSettings
    @State private var showAddCard = false
    @State private var savedCards: [(last4: String, brand: String)] = [
        (last4: "4242", brand: "Visa"),
        (last4: "5555", brand: "Mastercard")
    ]
    
    private var total: Double { (draft.service ?? draft.salon.services[0]).price }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            appSettings.themePage.ignoresSafeArea()
            
            if showAddCard {
                AddCardFormView(
                    draft: $draft,
                    isShowing: $showAddCard,
                    onCardAdded: { newCard in
                        savedCards.append((last4: newCard, brand: "Card"))
                        selectedCardIndex = savedCards.count - 1
                    }
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Back button
                        Button(action: onBack) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "F2F2F7"))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "chevron.left")
                                    .glowzaFont(size: 14, weight: .semibold)
                                    .foregroundColor(Color(hex: "1C1C1E"))
                            }
                        }
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Card")
                                .glowzaFont(size: 34, weight: .bold)
                                .foregroundColor(Color(hex: "1C1C1E"))
                            Text("Choose how to pay LKR \(Int(total))")
                                .glowzaFont(size: 15)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 24)
                        
                        // Apple Pay
                        Button(action: {}) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.black)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "apple.logo")
                                        .glowzaFont(size: 20, weight: .semibold)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Apple Pay")
                                        .glowzaFont(size: 15, weight: .semibold)
                                        .foregroundColor(Color(hex: "1C1C1E"))
                                    Text("Fast and secure")
                                        .glowzaFont(size: 12)
                                        .foregroundColor(Color(hex: "8E8E93"))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .glowzaFont(size: 14, weight: .semibold)
                                    .foregroundColor(Color(hex: "C7C7CC"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(appSettings.themeSurface)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "E5E5EA"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 20)
                        
                        // Saved cards section
                        if !savedCards.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SAVED CARDS")
                                    .glowzaFont(size: 11, weight: .semibold)
                                    .foregroundColor(Color(hex: "8E8E93"))
                                    .tracking(0.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 10) {
                                    ForEach(savedCards.indices, id: \.self) { index in
                                        cardSelectionButton(index: index, card: savedCards[index])
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            Spacer().frame(height: 20)
                        }
                        
                        // Add new card button
                        Button(action: { showAddCard = true }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(hex: "F2F2F7"))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "plus.circle.fill")
                                        .glowzaFont(size: 20, weight: .semibold)
                                        .foregroundColor(.glowzaPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Add New Card")
                                        .glowzaFont(size: 15, weight: .semibold)
                                        .foregroundColor(Color(hex: "1C1C1E"))
                                    Text("Visa, Mastercard, AMEX")
                                        .glowzaFont(size: 12)
                                        .foregroundColor(Color(hex: "8E8E93"))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .glowzaFont(size: 14, weight: .semibold)
                                    .foregroundColor(Color(hex: "C7C7CC"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(hex: "F9F9F9"))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "E5E5EA"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
            
            // Confirm button
            if !showAddCard {
                VStack(spacing: 0) {
                    Divider().opacity(0.5)
                    Button(action: onContinue) {
                        Text(selectedCardIndex != nil ? "Continue" : "Select a Card")
                            .glowzaFont(size: 16, weight: .semibold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 330, height: 55)
                    .background(selectedCardIndex != nil ? Color.glowzaPrimary : Color(hex: "D4829E"))
                    .cornerRadius(14)
                    .disabled(selectedCardIndex == nil)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .background(appSettings.themeSurface)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func cardSelectionButton(index: Int, card: (last4: String, brand: String)) -> some View {
        let isSelected = selectedCardIndex == index
        
        return Button(action: { selectedCardIndex = index }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.glowzaPrimary : Color(hex: "F2F2F7"))
                        .frame(width: 48, height: 48)
                    Image(systemName: "creditcard.fill")
                        .glowzaFont(size: 20, weight: .semibold)
                        .foregroundColor(isSelected ? .white : Color.glowzaPrimary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.brand)
                        .glowzaFont(size: 15, weight: .semibold)
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Text("•••• •••• •••• \(card.last4)")
                        .glowzaFont(size: 13, design: .monospaced)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.glowzaPrimary : Color(hex: "D1D1D6"), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.glowzaPrimary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.glowzaPrimary.opacity(0.06) : Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.glowzaPrimary : Color(hex: "E5E5EA"),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Add Card Form View
struct AddCardFormView: View {
    @Binding var draft: BookingDraft
    @Binding var isShowing: Bool
    let onCardAdded: (String) -> Void

    @Environment(AppSettings.self) private var appSettings
    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var isSaving = false
    @FocusState private var focusedField: CardField?
    
    enum CardField { case name, number, expiry, cvv }
    
    private var isFormValid: Bool {
        cardNumber.count == 16
            && !cardHolder.trimmingCharacters(in: .whitespaces).isEmpty
            && expiryDate.count == 5
            && cvv.count == 3
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            appSettings.themePage.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Back button
                    Button(action: { isShowing = false }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F2F2F7"))
                                .frame(width: 36, height: 36)
                            Image(systemName: "chevron.left")
                                .glowzaFont(size: 14, weight: .semibold)
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Card")
                            .glowzaFont(size: 34, weight: .bold)
                            .foregroundColor(Color(hex: "1C1C1E"))
                        Text("Enter your card details")
                            .glowzaFont(size: 15)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 28)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CARD INFORMATION")
                            .glowzaFont(size: 11, weight: .semibold)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)
                        
                        // Cardholder
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cardholder Name")
                                .glowzaFont(size: 13, weight: .medium)
                                .foregroundColor(Color(hex: "8E8E93"))
                            TextField("As it appears on card", text: $cardHolder)
                                .glowzaFont(size: 16)
                                .focused($focusedField, equals: .name)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color(hex: "F2F2F7"))
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(focusedField == .name ? Color.glowzaPrimary : Color.clear, lineWidth: 1.5)
                                )
                        }
                        
                        // Card number
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Card Number")
                                .glowzaFont(size: 13, weight: .medium)
                                .foregroundColor(Color(hex: "8E8E93"))
                            HStack {
                                TextField("0000  0000  0000  0000", text: $cardNumber)
                                    .keyboardType(.numberPad)
                                    .glowzaFont(size: 16, design: .monospaced)
                                    .focused($focusedField, equals: .number)
                                    .onChange(of: cardNumber) { val in
                                        cardNumber = String(val.filter { $0.isNumber }.prefix(16))
                                    }
                                Spacer()
                                Image(systemName: "creditcard")
                                    .glowzaFont(size: 18)
                                    .foregroundColor(cardNumber.isEmpty ? Color(hex: "C7C7CC") : .glowzaPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Color(hex: "F2F2F7"))
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(focusedField == .number ? Color.glowzaPrimary : Color.clear, lineWidth: 1.5)
                            )
                        }
                        
                        // Expiry + CVV
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Expiry Date")
                                    .glowzaFont(size: 13, weight: .medium)
                                    .foregroundColor(Color(hex: "8E8E93"))
                                TextField("MM / YY", text: $expiryDate)
                                    .keyboardType(.numberPad)
                                    .glowzaFont(size: 16, design: .monospaced)
                                    .focused($focusedField, equals: .expiry)
                                    .onChange(of: expiryDate) { val in
                                        let d = String(val.filter { $0.isNumber }.prefix(4))
                                        if d.count <= 2 {
                                            expiryDate = d
                                        } else {
                                            expiryDate = "\(d.prefix(2)) / \(d.dropFirst(2))"
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "F2F2F7"))
                                    .cornerRadius(25)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(focusedField == .expiry ? Color.glowzaPrimary : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CVV")
                                    .glowzaFont(size: 13, weight: .medium)
                                    .foregroundColor(Color(hex: "8E8E93"))
                                HStack {
                                    TextField("CVV", text: $cvv)
                                        .keyboardType(.numberPad)
                                        .glowzaFont(size: 16, design: .monospaced)
                                        .focused($focusedField, equals: .cvv)
                                        .onChange(of: cvv) { val in
                                            cvv = String(val.filter { $0.isNumber }.prefix(3))
                                        }
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .glowzaFont(size: 14)
                                        .foregroundColor(cvv.isEmpty ? Color(hex: "C7C7CC") : .glowzaPrimary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color(hex: "F2F2F7"))
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(focusedField == .cvv ? Color.glowzaPrimary : Color.clear, lineWidth: 1.5)
                                )
                            }
                        }
                        
                        // Security
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .glowzaFont(size: 13)
                                .foregroundColor(.glowzaPrimary)
                            Text("Your card details are encrypted")
                                .glowzaFont(size: 12)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 120)
                }
            }
            
            // Save button
            VStack(spacing: 0) {
                Divider().opacity(0.5)
                Button(action: saveCard) {
                    if isSaving {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Saving…")
                                .glowzaFont(size: 16, weight: .semibold)
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("Save & Continue")
                            .glowzaFont(size: 16, weight: .semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 330, height: 55)
                .background(isFormValid ? Color.glowzaPrimary : Color(hex: "D4829E"))
                .cornerRadius(14)
                .disabled(!isFormValid || isSaving)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(appSettings.themeSurface)
        }
        .navigationBarHidden(true)
    }
    
    private func saveCard() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onCardAdded(cardNumber.suffix(4).uppercased())
            isSaving = false
            isShowing = false
        }
    }
}
