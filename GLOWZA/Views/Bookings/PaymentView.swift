import SwiftUI

// MARK: - Payment View
// This view handles the payment process. It allows the user to select a payment method
// (Card or Cash) and shows a summary of the amount due.
struct PaymentView: View {
    @Binding var draft: BookingDraft // Bound to parent to share data.
    var isProcessing: Bool = false // NEW: To show loading state!
    let onPay: (Booking) -> Void // Callback when payment is successful.
    let onBack: () -> Void

    @State private var showCardEntry = false // Controls whether to show the card selection screen.
    @State private var selectedCardIndex: Int? = nil // Tracks the selected card.
    private var appSettings: AppSettings { AppSettings.shared }

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var total: Double { service.price }

    // Computed property to check if the user can proceed.
    private var canConfirm: Bool {
        switch draft.paymentMethod {
        case .card: return selectedCardIndex != nil // Must select a card if paying by card!
        case .cash, .online: return true
        }
    }

    var body: some View {
        // We use a conditional statement to switch between the main payment view
        // and the card entry view! This is a simple way to do navigation without a NavigationStack.
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

    // The main payment selection view.
    private var mainPaymentView: some View {
        ZStack(alignment: .bottom) {
            appSettings.themePage.ignoresSafeArea()

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

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment")
                            .glowzaFont(size: 24, weight: .semibold)
                            .foregroundColor(appSettings.themeText)
                        Text("Select payment method")
                            .glowzaFont(size: 15)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Amount summary card
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("TOTAL DUE")
                                .glowzaFont(size: 11, weight: .semibold)
                                .foregroundColor(Color(hex: "8E8E93"))
                                .tracking(0.5)
                            Text("LKR \(Int(total))")
                                .glowzaFont(size: 20, weight: .semibold)
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
                    .cornerRadius(25)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 28)

                    // Payment method selection list
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
                                showCardEntry = true // Show card selection!
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(hex: "F2F2F7"))
                                            .frame(width: 48, height: 48)
                                        Image("creditcard")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
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
                                .background(Color.white)
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(draft.paymentMethod == .card ? Color.glowzaPrimary : Color(hex: "E5E5EA"),
                                                lineWidth: draft.paymentMethod == .card ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: draft.paymentMethod)

                            // Cash button
                            methodButton(.cash)
                        }
                        .padding(.horizontal, 24)
                    }

                    // Cash info message
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

            // Confirm button pinned to bottom
            VStack(spacing: 0) {
                Divider().opacity(0.5)
                Button(action: confirmPayment) {
                    if isProcessing {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(.white)
                            Text("Processing...")
                        }
                        .glowzaFont(size: 16, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(Color.glowzaPrimary.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    } else {
                        Text(confirmButtonText)
                            .glowzaFont(size: 16, weight: .semibold)
                            .foregroundColor(.white)
                            .frame(width: 330, height: 55)
                            .background(canConfirm ? Color.glowzaPrimary : Color(hex: "D4829E"))
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }
                }
                .disabled(!canConfirm || isProcessing)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(appSettings.themeSurface)
        }
        .navigationBarHidden(true)
    }

    // Helper to create a payment method button.
    private func methodButton(_ method: PaymentMethodType) -> some View {
        let isSelected = draft.paymentMethod == method

        return Button(action: { draft.paymentMethod = method }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "F2F2F7"))
                        .frame(width: 48, height: 48)
                    if method == .online {
                        Image("onlinebanking")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    } else if method == .card {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.glowzaPrimary)
                    } else if method == .cash {
                        Image("salon pay")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .blendMode(.multiply)
                    } else {
                        Image(systemName: method.icon)
                            .glowzaFont(size: 20, weight: .semibold)
                            .foregroundColor(Color.glowzaPrimary)
                    }
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
            .background(Color.white)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(isSelected ? Color.glowzaPrimary : Color(hex: "E5E5EA"),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // Helper to create an info message box.
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

    // Computed property for confirm button text based on payment method.
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

    // Creates the final Booking object and calls the onPay callback!
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
            agreedConsent: draft.agreedConsent, // New: Link the consent text!
            status: .upcoming,
            review: nil
        )

        onPay(booking)
    }
}

// MARK: - Card Entry View
// This view allows the user to select a saved card or add a new one.
struct CardEntryView: View {
    @Binding var draft: BookingDraft
    @Binding var selectedCardIndex: Int?
    let onBack: () -> Void
    let onContinue: () -> Void

    private var appSettings: AppSettings { AppSettings.shared }
    @State private var showAddCard = false // Controls whether to show the add card form.
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
                                .glowzaFont(size: 24, weight: .semibold)
                                .foregroundColor(appSettings.themeText)
                            Text("Choose how to pay LKR \(Int(total))")
                                .glowzaFont(size: 15)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 24)
                        
                        // Apple Pay button (mock)
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
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
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
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
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
                            .frame(width: 330, height: 55)
                            .background(selectedCardIndex != nil ? Color.glowzaPrimary : Color(hex: "D4829E"))
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }
                    .disabled(selectedCardIndex == nil)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .background(appSettings.themeSurface)
            }
        }
        .navigationBarHidden(true)
    }
    
    // Helper to create a card selection button.
    private func cardSelectionButton(index: Int, card: (last4: String, brand: String)) -> some View {
        let isSelected = selectedCardIndex == index
        
        return Button(action: { selectedCardIndex = index }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "F2F2F7"))
                        .frame(width: 48, height: 48)
                    if card.brand.lowercased() == "visa" {
                        Image("visa")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    } else if card.brand.lowercased() == "mastercard" {
                        Image("mastercard")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    } else {
                        Image("creditcard")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
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
            .background(Color.white)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(isSelected ? Color.glowzaPrimary : Color(hex: "E5E5EA"),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Add Card Form View
// This view allows the user to enter new card details.
struct AddCardFormView: View {
    @Binding var draft: BookingDraft
    @Binding var isShowing: Bool
    let onCardAdded: (String) -> Void

    private var appSettings: AppSettings { AppSettings.shared }
    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var isSaving = false
    @FocusState private var focusedField: CardField? // Tracks which field has keyboard focus!
    
    enum CardField { case name, number, expiry, cvv }
    
    // Simple validation to check if fields are filled correctly!
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
                            .glowzaFont(size: 24, weight: .semibold)
                            .foregroundColor(appSettings.themeText)
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
                        
                        // Cardholder Name Field
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
                        
                        // Card Number Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Card Number")
                                .glowzaFont(size: 13, weight: .medium)
                                .foregroundColor(Color(hex: "8E8E93"))
                            HStack {
                                TextField("0000  0000  0000  0000", text: $cardNumber)
                                    .keyboardType(.numberPad)
                                    .glowzaFont(size: 16, design: .monospaced)
                                    .focused($focusedField, equals: .number)
                                    // Formats the input to only allow numbers and max 16 digits!
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
                        
                        // Expiry + CVV Fields in a HStack!
                        HStack(spacing: 14) {
                            // Expiry Date Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Expiry Date")
                                    .glowzaFont(size: 13, weight: .medium)
                                    .foregroundColor(Color(hex: "8E8E93"))
                                TextField("MM / YY", text: $expiryDate)
                                    .keyboardType(.numberPad)
                                    .glowzaFont(size: 16, design: .monospaced)
                                    .focused($focusedField, equals: .expiry)
                                    // Formats the input to add a slash!
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
                            
                            // CVV Field
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
                        
                        // Security notice
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
            
            // Save button pinned to bottom
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
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                .disabled(!isFormValid || isSaving)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(appSettings.themeSurface)
        }
        .navigationBarHidden(true)
    }
    
    // Simulates saving the card to a backend.
    private func saveCard() {
        isSaving = true
        // We use DispatchQueue.main.asyncAfter to simulate a network delay!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onCardAdded(String(cardNumber.suffix(4))) // Pass only the last 4 digits!
            isSaving = false
            isShowing = false
        }
    }
}
