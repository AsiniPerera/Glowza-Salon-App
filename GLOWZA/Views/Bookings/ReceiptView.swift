import SwiftUI
import MapKit

// MARK: - Receipt View
struct ReceiptView: View {

    let booking: Booking
    let onDone: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var showShareSheet = false
    @State private var receiptFileURL: URL? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "F8F9FB").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 24) {
                    // Success animation
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "962043").opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 54, weight: .bold))
                                .foregroundColor(Color(hex: "962043"))
                        }
                        .scaleEffect(1.0)

                        VStack(spacing: 8) {
                            Text("Booking Confirmed!")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(Color(hex: "1F2126"))
                            Text("Your appointment is booked and confirmed")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "7A7D85"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 32)

                    // Receipt details card
                    detailCard
                        .padding(.horizontal, 20)

                    // Next steps section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WHAT'S NEXT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "9A9DA5"))
                            .tracking(1.5)
                            .padding(.horizontal, 20)

                        VStack(spacing: 10) {
                            nextStepItem(
                                icon: "calendar",
                                title: "Save the Date",
                                subtitle: booking.date.formatted(.dateTime.day().month().year()) + " at " + booking.timeSlot
                            )
                            nextStepItem(
                                icon: "location.fill",
                                title: "Visit Our Salon",
                                subtitle: booking.salon.name
                            )
                            nextStepItem(
                                icon: "bell.fill",
                                title: "Reminders Set",
                                subtitle: "We'll notify you 24 hours before"
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        actionButton(
                            title: "Get Directions",
                            icon: "map.fill",
                            style: .secondary,
                            action: openDirections
                        )
                        actionButton(
                            title: "Download Receipt",
                            icon: "arrow.down.doc.fill",
                            style: .secondary,
                            action: prepareReceiptFile
                        )
                        actionButton(
                            title: "Back to Home",
                            icon: "house.fill",
                            style: .primary,
                            action: onDone
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 20)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let receiptFileURL {
                ShareSheet(activityItems: [receiptFileURL])
            }
        }
    }

    private func nextStepItem(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "962043"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "962043").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2126"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "9A9DA5"))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Booking Details")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "1F2126"))
                    Text("Receipt: \(booking.receiptNumber)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9A9DA5"))
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "00A878"))
            }
            .padding(16)
            .background(Color(hex: "F8F9FB"))
            .overlay(
                Divider()
                    .offset(y: 0),
                alignment: .bottom
            )

            // Details
            VStack(spacing: 12) {
                detailRow(icon: "building.2.fill", label: "Salon", value: booking.salon.name)
                detailRow(icon: "sparkles", label: "Service", value: booking.service.name)
                detailRow(icon: "calendar", label: "Date", value: booking.date.formatted(.dateTime.day().month().year()))
                detailRow(icon: "clock.fill", label: "Time", value: booking.timeSlot)
                Divider().padding(.vertical, 4)
                detailRow(icon: "creditcard.fill", label: "Amount Paid", value: "LKR \(Int(booking.amountPaid))", isHighlight: true)
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func detailRow(icon: String, label: String, value: String, isHighlight: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "962043"))
                .frame(width: 28)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8A8A8A"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: isHighlight ? .bold : .semibold))
                .foregroundColor(isHighlight ? Color(hex: "962043") : Color(hex: "1F2126"))
        }
    }

    private enum ActionStyle {
        case primary
        case secondary
    }

    private func actionButton(title: String, icon: String, style: ActionStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundColor(style == .primary ? .white : Color(hex: "962043"))
            .background(
                Group {
                    if style == .primary {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "962043"), Color(hex: "962043").opacity(0.85)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .overlay(
                Group {
                    if style == .secondary {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(hex: "962043"), lineWidth: 1.5)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func prepareReceiptFile() {
        let text = """
        GLOWZA BOOKING RECEIPT
        Receipt: \(booking.receiptNumber)
        Salon: \(booking.salon.name)
        Service: \(booking.service.name)
        Date: \(booking.date.formatted(.dateTime.day().month().year()))
        Time: \(booking.timeSlot)
        Amount Paid: LKR \(Int(booking.amountPaid))
        """
        let filename = "GLOWZA-\(booking.receiptNumber).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            receiptFileURL = url
            showShareSheet = true
        } catch {
            receiptFileURL = nil
        }
    }

    private func openDirections() {
        let coordinate = coordinateForSalon(booking.salon.name)
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = booking.salon.name
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func coordinateForSalon(_ name: String) -> CLLocationCoordinate2D {
        switch name {
        case "Haley Avenue":
            return CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820)
        case "Glow Studio":
            return CLLocationCoordinate2D(latitude: 6.7713, longitude: 79.8783)
        case "Luxe Aesthetics":
            return CLLocationCoordinate2D(latitude: 6.8490, longitude: 79.8684)
        default:
            return CLLocationCoordinate2D(latitude: 6.8920, longitude: 79.8560)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let salon = SalonCatalog.shared.salons[0]
    let booking = Booking(
        id: UUID(), salon: salon, service: salon.services[0],
        date: Date(), timeSlot: "10:00 AM",
        receiptNumber: "GLZ-12345", paymentMethod: .card,
        amountPaid: 3850, signatureImage: nil, status: .upcoming, review: nil
    )
    return ReceiptView(booking: booking, onDone: {})
    }

