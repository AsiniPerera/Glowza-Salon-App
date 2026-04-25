import SwiftUI
import MapKit

private let brand = Color(hex: "FF006E")

// MARK: - Receipt View
struct ReceiptView: View {

    let booking: Booking
    let onDone: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var showShareSheet = false
    @State private var receiptFileURL: URL? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "F1F1F1").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thank You")
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "1F2126"))
                        .padding(.top, 18)

                    Text("Your booking is confirmed.")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "62656C"))

                    detailCard

                    VStack(spacing: 12) {
                        actionButton(
                            title: "Download Receipt",
                            icon: "arrow.down.doc.fill",
                            style: .secondary,
                            action: prepareReceiptFile
                        )
                        actionButton(
                            title: "Get Directions",
                            icon: "map.fill",
                            style: .secondary,
                            action: openDirections
                        )
                        actionButton(
                            title: "Back to Home",
                            icon: "house.fill",
                            style: .primary,
                            action: onDone
                        )
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let receiptFileURL {
                ShareSheet(activityItems: [receiptFileURL])
            }
        }
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            Text("Booking Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1F2126"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            VStack(spacing: 12) {
                detailRow(icon: "building.2.fill", label: "Salon", value: booking.salon.name)
                detailRow(icon: "sparkles", label: "Service", value: booking.service.name)
                detailRow(icon: "calendar", label: "Date", value: booking.date.formatted(.dateTime.day().month().year()))
                detailRow(icon: "clock.fill", label: "Time", value: booking.timeSlot)
                detailRow(icon: "creditcard.fill", label: "Paid", value: "LKR \(Int(booking.amountPaid))")
                detailRow(icon: "doc.text.fill", label: "Receipt", value: booking.receiptNumber)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14)).foregroundColor(Color(hex: "6D7077"))
                .frame(width: 28)
            Text(label).font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "1F2126"))
        }
    }

    private enum ActionStyle {
        case primary
        case secondary
    }

    private func actionButton(title: String, icon: String, style: ActionStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(style == .primary ? .white : Color(hex: "2A2C32"))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(style == .primary ? brand : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style == .primary ? Color.clear : Color(hex: "E2E3E7"), lineWidth: 1)
            )
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
}
