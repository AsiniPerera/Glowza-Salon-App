import SwiftUI
import MapKit
import PDFKit

private let brand = Color(hex: "962043")

// MARK: - Receipt View
struct ReceiptView: View {

    let booking: Booking
    let onDone: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(AppSettings.self) private var appSettings
    @State private var showShareSheet = false
    @State private var receiptFileURL: URL? = nil


    var body: some View {
        ZStack(alignment: .bottom) {
            appSettings.themePage.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 16) {
                    confirmationHeader
                        .padding(.top, 18)

                    detailCard

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            squareActionButton(
                            title: "Download Receipt",
                            icon: "arrow.down.doc.fill",
                            action: prepareReceiptFile
                            )

                            squareActionButton(
                            title: "Get Directions",
                            icon: "map.fill",
                            action: openDirections
                            )
                        }

                        actionButton(
                            title: "Back to Home",
                            icon: "house.fill",
                            action: onDone
                        )
                    }

                    Spacer().frame(height: 36)
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

    private var confirmationHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "00A878").opacity(0.18), lineWidth: 1.5)
                    .frame(width: 88, height: 88)

                Circle()
                    .fill(Color(hex: "00A878").opacity(0.10))
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark")
                    .glowzaFont(size: 25, weight: .bold)
                    .foregroundColor(Color(hex: "00A878"))
            }

            Text("Booking Confirmed")
                .glowzaFont(size: 30, weight: .bold, design: .rounded)
                .foregroundColor(Color(hex: "1F2126"))

            Text("Your booking is confirmed")
                .glowzaFont(size: 16, weight: .regular)
                .foregroundColor(Color(hex: "8E8E93"))
        }
        .frame(maxWidth: .infinity)
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Booking Summary")
                        .glowzaFont(size: 18, weight: .semibold)
                        .foregroundColor(Color(hex: "1F2126"))
                    Text("Receipt #\(booking.receiptNumber)")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                Spacer()
            }
            .padding(.bottom, 12)

            VStack(spacing: 12) {
                detailRow(icon: "building.2.fill", label: "Salon", value: booking.salon.name)
                detailRow(icon: "sparkles", label: "Service", value: booking.service.name)
                detailRow(icon: "calendar", label: "Date", value: booking.date.formatted(.dateTime.day().month().year()))
                detailRow(icon: "clock.fill", label: "Time", value: booking.timeSlot)
                detailRow(icon: "creditcard.fill", label: "Paid", value: "LKR \(Int(booking.amountPaid))")
            }
        }
        .padding(16)
        .background(Color(hex: "F5F5F7"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "E9E9EB"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .glowzaFont(size: 14).foregroundColor(Color(hex: "8E8E93").opacity(0.7))
                .frame(width: 28)
            Text(label).glowzaFont(size: 13).foregroundColor(Color(hex: "8E8E93"))
            Spacer()
            Text(value)
                .glowzaFont(size: 13, weight: .semibold).foregroundColor(Color(hex: "1F2126"))
        }
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .glowzaFont(size: 15, weight: .semibold)
            .foregroundColor(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(brand)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private func squareActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .glowzaFont(size: 15, weight: .semibold)
                Text(title)
                    .glowzaFont(size: 15, weight: .semibold)
            }
            .foregroundColor(brand)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(hex: "F5F5F7"))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(brand, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func prepareReceiptFile() {
        let filename = "GLOWZA-\(booking.receiptNumber).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 at 72 DPI
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let brandColor = UIColor(red: 150 / 255, green: 32 / 255, blue: 67 / 255, alpha: 1)
        let textPrimary = UIColor(red: 31 / 255, green: 33 / 255, blue: 38 / 255, alpha: 1)
        let textSecondary = UIColor(red: 130 / 255, green: 132 / 255, blue: 139 / 255, alpha: 1)
        let lineColor = UIColor(red: 234 / 255, green: 235 / 255, blue: 238 / 255, alpha: 1)

        do {
            let pdfData = renderer.pdfData { context in
                context.beginPage()
                let cg = context.cgContext

                UIColor.white.setFill()
                cg.fill(pageRect)

                let margin: CGFloat = 44
                let contentWidth = pageRect.width - (margin * 2)
                var y: CGFloat = 56

                if let appLogo = UIImage(named: "logo") {
                    let logoRect = CGRect(x: (pageRect.width - 132) / 2, y: y, width: 132, height: 90)
                    appLogo.draw(in: logoRect)
                    y += 104
                }

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: brandColor
                ]
                let subtitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: textSecondary
                ]

                let title = "GLOWZA BOOKING RECEIPT" as NSString
                let titleSize = title.size(withAttributes: titleAttributes)
                title.draw(
                    at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: y),
                    withAttributes: titleAttributes
                )
                y += 36

                let receiptNo = "Receipt #\(booking.receiptNumber)" as NSString
                let receiptSize = receiptNo.size(withAttributes: subtitleAttributes)
                receiptNo.draw(
                    at: CGPoint(x: (pageRect.width - receiptSize.width) / 2, y: y),
                    withAttributes: subtitleAttributes
                )
                y += 26

                cg.setStrokeColor(lineColor.cgColor)
                cg.setLineWidth(1)
                cg.move(to: CGPoint(x: margin, y: y))
                cg.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                cg.strokePath()
                y += 30

                let sectionAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: textSecondary
                ]
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: textSecondary
                ]
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                    .foregroundColor: textPrimary
                ]

                ("BOOKING SUMMARY" as NSString).draw(
                    at: CGPoint(x: margin, y: y),
                    withAttributes: sectionAttributes
                )
                y += 24

                let dateText = booking.date.formatted(.dateTime.day().month(.wide).year())
                let rows: [(String, String)] = [
                    ("Salon", booking.salon.name),
                    ("Service", booking.service.name),
                    ("Date", dateText),
                    ("Time", booking.timeSlot),
                    ("Amount Paid", "LKR \(Int(booking.amountPaid))")
                ]

                for (label, value) in rows {
                    (label as NSString).draw(
                        at: CGPoint(x: margin, y: y),
                        withAttributes: labelAttributes
                    )

                    let valueText = value as NSString
                    let valueRect = CGRect(x: margin + 130, y: y - 1, width: contentWidth - 130, height: 40)
                    valueText.draw(in: valueRect, withAttributes: valueAttributes)

                    y += 30
                    cg.setStrokeColor(lineColor.cgColor)
                    cg.move(to: CGPoint(x: margin, y: y))
                    cg.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                    cg.strokePath()
                    y += 14
                }

                y += 20
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: textSecondary
                ]
                ("Thank you for choosing GLOWZA." as NSString).draw(
                    at: CGPoint(x: margin, y: y),
                    withAttributes: footerAttributes
                )
            }

            guard let pdfDocument = PDFDocument(data: pdfData) else {
                receiptFileURL = nil
                return
            }

            pdfDocument.write(to: url)

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

