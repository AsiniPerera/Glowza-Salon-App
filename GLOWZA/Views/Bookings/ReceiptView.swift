import SwiftUI
import PDFKit

struct ReceiptView: View {

    let booking: Booking
    let onDone: () -> Void

    @State private var showShareSheet = false
    @State private var pdfURL: URL? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Success header
                    successHeader

                    // Receipt card
                    receiptCard

                    // Buttons
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .background(Color.glowzaBackground.ignoresSafeArea())
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheetView(items: [url])
            }
        }
    }

    // MARK: - Success Header
    private var successHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.glowzaGold.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.glowzaGoldDark)
            }
            Text("Booking Confirmed!")
                .font(.system(size: 24, weight: .bold)).foregroundColor(Color.glowzaTextPrimary)
            Text("Your appointment has been successfully booked.\nWe'll see you soon!")
                .font(.system(size: 14)).foregroundColor(Color.glowzaSubtext)
                .multilineTextAlignment(.center).lineSpacing(4)
        }
    }

    // MARK: - Receipt Card
    private var receiptCard: some View {
        VStack(spacing: 0) {
            // Header stripe
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RECEIPT").font(.system(size: 11, weight: .bold)).foregroundColor(.white).kerning(2)
                    Text(booking.receiptNumber).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "sparkles").font(.system(size: 28)).foregroundColor(.white.opacity(0.6))
            }
            .padding(18)
            .background(
                LinearGradient(colors: [Color(hex: "C8860A"), Color(hex: "E5A820")],
                               startPoint: .leading, endPoint: .trailing)
            )

            // Perforated divider
            perforatedDivider

            // Details
            VStack(spacing: 14) {
                receiptRow(icon: "building.2.fill",   label: "Salon",    value: booking.salon.name)
                receiptRow(icon: "mappin",            label: "Location", value: booking.salon.location)
                receiptRow(icon: booking.service.icon,label: "Service",  value: booking.service.name)
                receiptRow(icon: "calendar",          label: "Date",     value: booking.date.formatted(date: .long, time: .omitted))
                receiptRow(icon: "clock",             label: "Time",     value: booking.timeSlot)
                receiptRow(icon: "timer",             label: "Duration", value: booking.service.duration)
                receiptRow(icon: booking.paymentMethod.icon, label: "Payment", value: booking.paymentMethod.rawValue)
            }
            .padding(18)

            Divider().padding(.horizontal, 18)

            // Total
            HStack {
                Text("Total Paid")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(Color.glowzaTextPrimary)
                Spacer()
                Text("LKR \(Int(booking.amountPaid))")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(Color.glowzaGoldDark)
            }
            .padding(18)

            // Signature preview (if exists)
            if let sig = booking.signatureImage {
                Divider().padding(.horizontal, 18)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Digital Signature")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(Color.glowzaSubtext)
                    Image(uiImage: sig)
                        .resizable().scaledToFit()
                        .frame(height: 60)
                        .padding(6)
                        .background(Color(hex: "FAF7F2"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18).padding(.bottom, 14)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
    }

    private func receiptRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(Color.glowzaGoldDark).frame(width: 18)
            Text(label).font(.system(size: 13)).foregroundColor(Color.glowzaSubtext)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(Color.glowzaTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var perforatedTears: some View {
        HStack(spacing: 0) {
            ForEach(0..<25, id: \.self) { _ in
                Circle().fill(Color.glowzaBackground).frame(width: 10, height: 10)
            }
        }
    }

    private var perforatedDivider: some View {
        ZStack {
            HStack {
                Circle().fill(Color.glowzaBackground).frame(width: 20, height: 20).offset(x: -10)
                Spacer()
                Circle().fill(Color.glowzaBackground).frame(width: 20, height: 20).offset(x: 10)
            }
            Rectangle().fill(Color(hex: "EDEAE4")).frame(height: 1).padding(.horizontal, 10)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Download PDF
            Button(action: downloadPDF) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.doc.fill").font(.system(size: 16))
                    Text("Download Receipt").font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(
                    LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.glowzaGold.opacity(0.35), radius: 10, x: 0, y: 5)
            }

            // Done
            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.glowzaGoldDark)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(Color.glowzaGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - PDF Generation
    private func downloadPDF() {
        let data = buildReceiptPDF()
        let url  = FileManager.default.temporaryDirectory
            .appendingPathComponent("Receipt_\(booking.receiptNumber).pdf")
        try? data.write(to: url)
        pdfURL = url
        showShareSheet = true
    }

    private func buildReceiptPDF() -> Data {
        let pageW: CGFloat = 595; let pageH: CGFloat = 842; let m: CGFloat = 36
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        return renderer.pdfData { ctx in
            ctx.beginPage()
            // Gold header strip
            let gold = UIColor(red: 0.898, green: 0.659, blue: 0.039, alpha: 1)
            gold.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageW, height: 80)).fill()
            draw("GLOWZA", at: CGPoint(x: m, y: 16), font: .boldSystemFont(ofSize: 26), color: .white)
            draw("Beauty & Aesthetics — Official Receipt", at: CGPoint(x: m, y: 48), font: .systemFont(ofSize: 11), color: .white.withAlphaComponent(0.9))

            var y: CGFloat = 106
            draw("PAYMENT RECEIPT", at: CGPoint(x: m, y: y), font: .boldSystemFont(ofSize: 16), color: .darkGray)
            y += 28
            draw(booking.receiptNumber, at: CGPoint(x: m, y: y), font: .systemFont(ofSize: 12), color: .lightGray)
            y += 32
            drawDivider(ctx, x: m, y: y, width: pageW - m * 2)
            y += 16

            let rows: [(String, String)] = [
                ("Salon", booking.salon.name),
                ("Location", booking.salon.location),
                ("Service", booking.service.name),
                ("Date", booking.date.formatted(date: .long, time: .omitted)),
                ("Time", booking.timeSlot),
                ("Duration", booking.service.duration),
                ("Payment Method", booking.paymentMethod.rawValue),
                ("Status", "PAID")
            ]
            for (lbl, val) in rows {
                draw(lbl, at: CGPoint(x: m, y: y), font: .systemFont(ofSize: 11), color: .gray)
                draw(val, at: CGPoint(x: pageW / 2, y: y), font: .systemFont(ofSize: 11, weight: .medium), color: .darkText)
                y += 26
            }

            y += 8; drawDivider(ctx, x: m, y: y, width: pageW - m * 2); y += 16
            draw("Total Paid", at: CGPoint(x: m, y: y), font: .boldSystemFont(ofSize: 14), color: .darkGray)
            draw("LKR \(Int(booking.amountPaid))", at: CGPoint(x: pageW / 2, y: y),
                 font: .boldSystemFont(ofSize: 14), color: UIColor(red: 0.785, green: 0.524, blue: 0.039, alpha: 1))
            y += 50
            if let sig = booking.signatureImage {
                draw("Digital Signature:", at: CGPoint(x: m, y: y), font: .systemFont(ofSize: 11), color: .gray)
                y += 18
                sig.draw(in: CGRect(x: m, y: y, width: 200, height: 70))
                y += 80
            }
            y += 10; drawDivider(ctx, x: m, y: y, width: pageW - m * 2); y += 14
            draw("This is an official receipt issued by Glowza Beauty & Aesthetics.",
                 at: CGPoint(x: m, y: y), font: .systemFont(ofSize: 9), color: .lightGray)
        }
    }

    private func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        text.draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private func drawDivider(_ ctx: UIGraphicsPDFRendererContext, x: CGFloat, y: CGFloat, width: CGFloat) {
        UIColor.lightGray.withAlphaComponent(0.35).setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))
        path.stroke()
    }
}

// MARK: - Share Sheet wrapper
struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
