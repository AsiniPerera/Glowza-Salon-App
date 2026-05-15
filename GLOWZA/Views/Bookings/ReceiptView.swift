import SwiftUI
import MapKit
import PDFKit

// MARK: - Receipt View
// This view is shown after a successful booking. It displays a confirmation message,
// a summary of the booking, and options to download the receipt or get directions.
struct ReceiptView: View {

    let booking: Booking // The booking details passed from the previous screen.
    let onDone: () -> Void // Callback to go back home.

    @Environment(\.openURL) private var openURL
    private var appSettings: AppSettings { AppSettings.shared }
    private var brand: Color { appSettings.themeBrand }
    @State private var showShareSheet = false
    @State private var showMapInApp = false // NEW: To show map in a sheet!
    @State private var receiptFileURL: URL? = nil


    var body: some View {
        ZStack(alignment: .bottom) {
            appSettings.themePage.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 16) {
                    confirmationHeader
                        .padding(.top, 18)

                    detailCard

                    // Action buttons in a grid
                    HStack(spacing: 14) {
                        squareActionButton(
                            title: "Download Receipt",
                            icon: "arrow.down.doc.fill",
                            action: prepareReceiptFile // Generates the PDF!
                        )

                        squareActionButton(
                            title: "Get Directions",
                            icon: "map.fill",
                            action: { showMapInApp = true } // Now opens the in-app map!
                        )
                    }
                    .padding(.horizontal, 2)

                    VStack(spacing: 12) {
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
        // Shows the system share sheet when the PDF is ready!
        .sheet(isPresented: $showShareSheet) {
            if let receiptFileURL {
                ShareSheet(activityItems: [receiptFileURL])
            }
        }
        // NEW: Shows the map in a premium sheet!
        .sheet(isPresented: $showMapInApp) {
            MapDetailView(booking: booking)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // Header with checkmark animation (implied by design) and text.
    private var confirmationHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(brand.opacity(0.18), lineWidth: 1.5)
                    .frame(width: 88, height: 88)

                Circle()
                    .fill(brand.opacity(0.10))
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark")
                    .glowzaFont(size: 25, weight: .bold)
                    .foregroundColor(brand)
            }

            Text("Booking Confirmed")
                .glowzaFont(size: 30, weight: .bold, design: .rounded)
                .foregroundColor(appSettings.themeText)

            Text("Your booking is confirmed")
                .glowzaFont(size: 16, weight: .regular)
                .foregroundColor(appSettings.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // Card showing the booking details.
    private var detailCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Booking Summary")
                        .glowzaFont(size: 18, weight: .semibold)
                        .foregroundColor(appSettings.themeText)
                    Text("Receipt #\(booking.receiptNumber)")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(appSettings.themeTextSecondary)
                }
                Spacer()
            }
            .padding(.bottom, 12)

            VStack(spacing: 12) {
                detailRow(icon: "mappin.and.ellipse", label: "Salon", value: booking.salon.name)
                detailRow(icon: "bubbles.and.sparkles.fill", label: "Service", value: booking.service.name)
                detailRow(icon: "calendar.badge.clock", label: "Date", value: booking.date.formatted(.dateTime.day().month().year()))
                detailRow(icon: "clock.badge.checkmark", label: "Time", value: booking.timeSlot)
                detailRow(icon: "creditcard.fill", label: "Paid", value: "LKR \(Int(booking.amountPaid))")
                
                // NEW: Display the signature on the receipt!
                if let signature = booking.signatureImage {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.and.outline")
                                .glowzaFont(size: 14).foregroundColor(appSettings.themeTextSecondary.opacity(0.7))
                                .frame(width: 28)
                            Text("Signature").glowzaFont(size: 13).foregroundColor(appSettings.themeTextSecondary)
                            Spacer()
                        }
                        
                        Image(uiImage: signature)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.leading, 40)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(appSettings.themeBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(appSettings.isDarkMode ? 0.2 : 0.04), radius: 8, y: 3)
    }

    // Helper for key-value rows in the card.
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .glowzaFont(size: 14).foregroundColor(appSettings.themeTextSecondary.opacity(0.7))
                .frame(width: 28)
            Text(label).glowzaFont(size: 13).foregroundColor(appSettings.themeTextSecondary)
            Spacer()
            Text(value)
                .glowzaFont(size: 13, weight: .semibold).foregroundColor(appSettings.themeText)
        }
    }

    // Big solid action button.
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

    // Outlined action button.
    private func squareActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .glowzaFont(size: 14, weight: .semibold)
                Text(title)
                    .glowzaFont(size: 13, weight: .bold)
            }
            .foregroundColor(brand)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(brand, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - PDF Generation
    // This is a advanced topic! We are using UIKit's UIGraphicsPDFRenderer to programmatically
    // draw a PDF receipt. This is like painting on a canvas with code!
    private func prepareReceiptFile() {
        let filename = "GLOWZA-\(booking.receiptNumber).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 paper size at 72 DPI
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        // Define colors using UIKit (since we are using UIKit rendering APIs)
        let brandColor = UIColor(red: 150 / 255, green: 32 / 255, blue: 67 / 255, alpha: 1)
        let textPrimary = UIColor(red: 31 / 255, green: 33 / 255, blue: 38 / 255, alpha: 1)
        let textSecondary = UIColor(red: 130 / 255, green: 132 / 255, blue: 139 / 255, alpha: 1)
        let lineColor = UIColor(red: 234 / 255, green: 235 / 255, blue: 238 / 255, alpha: 1)

        do {
            let pdfData = renderer.pdfData { context in
                context.beginPage()
                let cg = context.cgContext

                // Draw background
                UIColor.white.setFill()
                cg.fill(pageRect)

                let margin: CGFloat = 44
                let contentWidth = pageRect.width - (margin * 2)
                var y: CGFloat = 56 // Keeps track of vertical cursor position!

                // Draw App Logo
                if let appLogo = UIImage(named: "logo") {
                    let logoRect = CGRect(x: (pageRect.width - 132) / 2, y: y, width: 132, height: 90)
                    appLogo.draw(in: logoRect)
                    y += 104
                }

                // Define text styles (attributes)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: brandColor
                ]
                let subtitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: textSecondary
                ]

                // Draw Title
                let title = "GLOWZA BOOKING RECEIPT" as NSString
                let titleSize = title.size(withAttributes: titleAttributes)
                title.draw(
                    at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: y),
                    withAttributes: titleAttributes
                )
                y += 36

                // Draw Receipt Number
                let receiptNo = "Receipt #\(booking.receiptNumber)" as NSString
                let receiptSize = receiptNo.size(withAttributes: subtitleAttributes)
                receiptNo.draw(
                    at: CGPoint(x: (pageRect.width - receiptSize.width) / 2, y: y),
                    withAttributes: subtitleAttributes
                )
                y += 26

                // Draw a separator line
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

                // Draw Section Header
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

                // Loop through rows and draw key-value pairs!
                for (label, value) in rows {
                    (label as NSString).draw(
                        at: CGPoint(x: margin, y: y),
                        withAttributes: labelAttributes
                    )

                    let valueText = value as NSString
                    let valueRect = CGRect(x: margin + 130, y: y - 1, width: contentWidth - 130, height: 40)
                    valueText.draw(in: valueRect, withAttributes: valueAttributes)

                    y += 30
                    
                    // Draw mini separator line
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

            // Verify the PDF was created successfully!
            guard let pdfDocument = PDFDocument(data: pdfData) else {
                receiptFileURL = nil
                return
            }

            // Write the file to disk.
            pdfDocument.write(to: url)

            // Update state to show the share sheet!
            receiptFileURL = url
            showShareSheet = true
        } catch {
            receiptFileURL = nil
        }
    }

    // Opens Apple Maps with driving directions to the salon.
    private func openDirections() {
        let coordinate = coordinateForSalon(booking.salon.name)
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = booking.salon.name
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // Helper to get coordinates for hardcoded salons (since we don't have a real DB).
    private func coordinateForSalon(_ name: String) -> CLLocationCoordinate2D {
        switch name {
        case "Golden Avenue":
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

// MARK: - Share Sheet
// Bridges UIActivityViewController to SwiftUI to show the native iOS share sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Map Detail View
// This shows the elegant map in a modal sheet.
struct MapDetailView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    private var brand: Color { Color.glowzaPrimary }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Large Interactive Map
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: booking.salon.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))) {
                    Marker(booking.salon.name, coordinate: booking.salon.coordinate)
                        .tint(brand)
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .bottom)
                .frame(maxHeight: .infinity)
                
                // 2. Info Footer
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        iconBadge(icon: "mappin.and.ellipse", color: brand)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(booking.salon.name)
                                .glowzaFont(size: 18, weight: .bold)
                                .foregroundColor(appSettings.themeText)
                            Text(booking.salon.location)
                                .glowzaFont(size: 14)
                                .foregroundColor(appSettings.themeTextSecondary)
                        }
                        Spacer()
                    }
                    
                    // Button to open external Maps for full navigation
                    Button(action: openExternalMaps) {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            Text("Open in Apple Maps")
                        }
                        .glowzaFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(brand)
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        .shadow(color: brand.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(24)
                .background(appSettings.themeSurface)
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .glowzaFont(size: 16, weight: .medium)
                        .foregroundColor(brand)
                }
            }
        }
    }
    
    private func iconBadge(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.12))
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .glowzaFont(size: 18, weight: .semibold)
                .foregroundStyle(color)
        }
    }
    
    private func openExternalMaps() {
        // Use the coordinate from the salon object!
        let lat = booking.salon.coordinate.latitude
        let lon = booking.salon.coordinate.longitude
        let url = URL(string: "maps://?q=\(booking.salon.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&ll=\(lat),\(lon)")!
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
