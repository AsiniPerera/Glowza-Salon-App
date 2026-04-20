import SwiftUI

// MARK: - Flow Step Enum
enum BookingFlowStep { case service, dateTime, consent, payment, receipt }

// MARK: - BookingFlowView (container)
struct BookingFlowView: View {

    @State private var draft: BookingDraft
    @State private var step: BookingFlowStep
    @State private var completedBooking: Booking? = nil
    @Environment(\.dismiss) private var dismiss

    init(draft: BookingDraft) {
        _draft = State(initialValue: draft)
        _step  = State(initialValue: draft.service != nil ? .dateTime : .service)
    }

    var body: some View {
        ZStack {
            Color.glowzaBackground.ignoresSafeArea()
            switch step {
            case .service:
                ServiceSelectionView(draft: $draft) { step = .dateTime }
                    onBack: { dismiss() }
            case .dateTime:
                DateTimeSelectionView(draft: $draft) { step = .consent }
                    onBack: { step = draft.service != nil ? .service : .service }
            case .consent:
                ConsentFormView(draft: $draft) { step = .payment }
                    onBack: { step = .dateTime }
            case .payment:
                PaymentView(draft: $draft) { booking in
                    BookingStore.shared.add(booking)
                    completedBooking = booking
                    step = .receipt
                }
                onBack: { step = .consent }
            case .receipt:
                if let booking = completedBooking {
                    ReceiptView(booking: booking) { dismiss() }
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: step == .service)
    }
}

// MARK: - Service Selection View
struct ServiceSelectionView: View {
    @Binding var draft: BookingDraft
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "Select Service", subtitle: draft.salon.name, onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(draft.salon.services) { service in
                        serviceCard(service)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }

            flowButton(
                label: "Continue",
                enabled: draft.service != nil
            ) { onNext() }
        }
        .background(Color.glowzaBackground.ignoresSafeArea())
    }

    private func serviceCard(_ service: SalonService) -> some View {
        let selected = draft.service?.id == service.id
        return Button(action: { draft.service = service }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? Color.glowzaGoldDark : Color.glowzaGold.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: service.icon)
                        .font(.system(size: 20))
                        .foregroundColor(selected ? .white : Color.glowzaGoldDark)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.glowzaDark)
                    HStack(spacing: 8) {
                        Label(service.duration, systemImage: "clock")
                        Text(service.category)
                    }
                    .font(.system(size: 11)).foregroundColor(Color.glowzaSubtext)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("LKR \(Int(service.price))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.glowzaGoldDark)
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.glowzaGoldDark)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Color.glowzaGoldDark : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(selected ? 0.08 : 0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date & Time Selection View
struct DateTimeSelectionView: View {
    @Binding var draft: BookingDraft
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "Pick Date & Time", subtitle: draft.service?.name ?? "", onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Date")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(Color.glowzaDark)
                            .padding(.horizontal, 20)
                        DatePicker("", selection: $draft.date, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Color.glowzaGoldDark)
                            .padding(.horizontal, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 20)
                    }

                    // Time slots
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Time")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(Color.glowzaDark)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(BookingDraft.timeSlots, id: \.time) { slot in
                                timeChip(slot)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20).padding(.bottom, 40)
            }

            flowButton(label: "Continue", enabled: !draft.timeSlot.isEmpty) { onNext() }
        }
        .background(Color.glowzaBackground.ignoresSafeArea())
    }

    private func timeChip(_ slot: (time: String, available: Bool)) -> some View {
        let selected = draft.timeSlot == slot.time
        return Button(action: {
            if slot.available { draft.timeSlot = slot.time }
        }) {
            Text(slot.time)
                .font(.system(size: 12, weight: selected ? .bold : .medium))
                .foregroundColor(
                    !slot.available ? Color.glowzaSubtext.opacity(0.4) :
                    selected ? .white : Color.glowzaGoldDark
                )
                .frame(maxWidth: .infinity).frame(height: 38)
                .background(
                    selected ? Color.glowzaGoldDark :
                    !slot.available ? Color(hex: "F0EAE0") : Color.white
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? Color.glowzaGoldDark : Color.glowzaGold.opacity(0.3), lineWidth: 1)
                )
        }
        .disabled(!slot.available)
    }
}

// MARK: - Shared helpers for flow screens

func flowHeader(title: String, subtitle: String, onBack: @escaping () -> Void) -> some View {
    VStack(spacing: 4) {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.glowzaDark)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            Spacer()
        }
        .padding(.horizontal, 20)

        VStack(spacing: 4) {
            Text(title).font(.system(size: 22, weight: .bold)).foregroundColor(Color.glowzaDark)
            if !subtitle.isEmpty {
                Text(subtitle).font(.system(size: 13)).foregroundColor(Color.glowzaSubtext)
            }
        }
        .padding(.vertical, 8)
    }
    .padding(.top, 56)
    .background(Color.glowzaBackground)
}

func flowButton(label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(
                LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                               startPoint: .leading, endPoint: .trailing)
                    .opacity(enabled ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .disabled(!enabled)
    .padding(.horizontal, 20).padding(.vertical, 16)
    .background(Color.glowzaBackground)
}
