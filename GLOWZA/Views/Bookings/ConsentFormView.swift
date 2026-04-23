import SwiftUI
import PencilKit
import PDFKit

// MARK: - PencilKit Canvas Wrapper
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.overrideUserInterfaceStyle = .light
        canvasView.tool = PKInkingTool(.pen, color: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1), width: 2)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// MARK: - Consent Form View
struct ConsentFormView: View {

    @Binding var draft: BookingDraft
    let onConfirm: () -> Void
    let onBack: () -> Void

    @State private var canvasView        = PKCanvasView()
    @State private var ack1              = false
    @State private var ack2              = false
    @State private var isSigned          = false
    @State private var showShareSheet    = false
    @State private var pdfURL: URL?      = nil
    @State private var showSignedBanner  = false
    @State private var showNotReadyAlert = false

    private var bothAcked: Bool  { ack1 && ack2 }
    private var canProceed: Bool { ack1 && ack2 && isSigned }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.glowzaTextPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Title block
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Treatment Consent Form")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.glowzaTextPrimary)
                        Text("Please review the clinical details of your upcoming aesthetic procedure to ensure informed consent.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.glowzaSubtext)
                            .lineSpacing(4)
                    }

                    // Procedure Disclosure card
                    disclosureCard

                    // Client Acknowledgement
                    acknowledgementSection

                    // Digital Signature
                    signatureSection

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }

            // Bottom actions bar — always visible, always tappable
            VStack(spacing: 12) {

                // Row: Download PDF + Confirm & Sign
                HStack(spacing: 12) {

                    // Download PDF — always clickable
                    Button(action: downloadConsentPDF) {
                        HStack(spacing: 7) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Download PDF")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color.glowzaGoldDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.glowzaGoldDark, lineWidth: 1.8)
                        )
                    }

                    // Confirm & Sign — always clickable, gold when ready
                    Button(action: confirmAndSign) {
                        HStack(spacing: 7) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Confirm & Sign")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: canProceed
                                    ? [Color.glowzaGold, Color.glowzaGoldDark]
                                    : [Color(hex: "CCCCCC"), Color(hex: "BBBBBB")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: canProceed ? Color.glowzaGoldDark.opacity(0.3) : .clear,
                                radius: 8, x: 0, y: 4)
                    }
                }

                // Clear Canvas — always clickable
                Button(action: clearCanvas) {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Clear Canvas")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.glowzaTextPrimary.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.glowzaCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // Status hint — shown until all steps complete
                if !canProceed {
                    HStack(spacing: 7) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.glowzaGoldDark.opacity(0.75))
                        Text(statusHintText)
                            .font(.system(size: 12))
                            .foregroundColor(Color.glowzaSubtext)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.glowzaCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: canProceed)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(Color.glowzaBackground)
        }
        .background(Color.glowzaBackground.ignoresSafeArea())
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheetView(items: [url])
                    .presentationDetents([.medium, .large])
            }
        }
        .overlay(alignment: .top) {
            if showSignedBanner {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(Color.glowzaGoldDark)
                    Text("Consent form signed successfully!")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Color.glowzaTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(Color.glowzaCardBg)
                .overlay(Rectangle().fill(Color.glowzaGoldDark).frame(height: 3), alignment: .bottom)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(.spring(duration: 0.35), value: showSignedBanner)
        .alert("Almost there!", isPresented: $showNotReadyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusHintText)
        }
    }

    // MARK: - Procedure Disclosure
    private var disclosureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Procedure Disclosure")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.glowzaGoldDark)

            Text("The proposed aesthetic treatment involves the administration of dermal enhancers and neuromodulators designed to refine facial contours and diminish the appearance of fine lines. While generally safe, this clinical procedure requires an understanding of localised physiological responses.")
                .font(.system(size: 13))
                .foregroundColor(Color.glowzaTextPrimary.opacity(0.8))
                .lineSpacing(5)

            disclosureList(
                title: "EXPECTED BENEFITS",
                items: ["Enhanced hydration and volume",
                        "Restoration of structural symmetry",
                        "Stimulation of natural collagen synthesis"]
            )

            disclosureList(
                title: "POTENTIAL RISKS",
                items: ["Temporary localised erythema",
                        "Minor swelling or ecchymosis",
                        "Sensitivity at injection sites"]
            )
        }
        .padding(18)
        .background(Color.glowzaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.glowzaGold.opacity(0.25), lineWidth: 1)
        )
    }

    private func disclosureList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.glowzaGoldDark)
                .kerning(1.2)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(Color.glowzaGoldDark).frame(width: 5, height: 5).padding(.top, 5)
                    Text(item).font(.system(size: 13)).foregroundColor(Color.glowzaTextPrimary.opacity(0.85)).lineSpacing(3)
                }
            }
        }
    }

    // MARK: - Acknowledgement
    private var acknowledgementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Client Acknowledgement")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.glowzaTextPrimary)

            ackRow(checked: $ack1,
                   text: "I understand that clinical results vary and that additional touch-up appointments may be necessary for optimal aesthetic outcomes.")
            ackRow(checked: $ack2,
                   text: "I confirm that I have disclosed all medical history, including allergies, medications, and previous treatments, to my practitioner.")
        }
    }

    private func ackRow(checked: Binding<Bool>, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: { checked.wrappedValue.toggle() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(checked.wrappedValue ? Color.glowzaGoldDark : Color(hex: "CCBFA8"), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if checked.wrappedValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.glowzaGoldDark)
                    }
                }
            }
            Text(text)
                .font(.system(size: 13)).foregroundColor(Color.glowzaTextPrimary.opacity(0.85)).lineSpacing(4)
        }
    }

    // MARK: - Signature
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Digital Signature")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.glowzaTextPrimary)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.glowzaGold.opacity(0.4), lineWidth: 1.5)
                    )

                // Placeholder hint
                if !isSigned {
                    Text("Sign within this area using your finger or stylus")
                        .font(.system(size: 13))
                        .foregroundColor(Color.glowzaSubtext.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                SignatureCanvasView(canvasView: $canvasView)
                    .onChange(of: canvasView.drawing.bounds) { _, bounds in
                        isSigned = !canvasView.drawing.strokes.isEmpty
                    }

                // Signature line
                VStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Rectangle().fill(Color.glowzaSubtext.opacity(0.25)).frame(height: 1)
                        Text("AUTHORIZED SIGNATURE LINE")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Color.glowzaSubtext.opacity(0.5))
                            .kerning(1.5)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 12)
                }
            }
            .frame(height: 160)
        }
    }

    // MARK: - Actions
    private func confirmAndSign() {
        guard canProceed else {
            showNotReadyAlert = true
            return
        }
        draft.signatureImage = canvasView.drawing.image(
            from: CGRect(origin: .zero, size: CGSize(width: 400, height: 160)),
            scale: UIScreen.main.scale
        )
        showSignedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            showSignedBanner = false
            onConfirm()
        }
    }

    private var statusHintText: String {
        if !ack1 || !ack2 { return "Please tick both acknowledgements above" }
        if !isSigned       { return "Draw your signature to continue" }
        return ""
    }

    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        isSigned = false
    }

    private func downloadConsentPDF() {
        let liveSignature = canvasView.drawing.strokes.isEmpty ? nil :
            canvasView.drawing.image(
                from: CGRect(origin: .zero, size: CGSize(width: 400, height: 160)),
                scale: UIScreen.main.scale
            )
        let pdfData = buildConsentPDF(signatureOverride: liveSignature)
        let fileName = "ConsentForm_\(draft.salon.name.replacingOccurrences(of: " ", with: "_")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: url)
        pdfURL = url
        showShareSheet = true
    }

    private func buildConsentPDF(signatureOverride: UIImage? = nil) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 40
            let gold = UIColor(red: 0.898, green: 0.659, blue: 0.039, alpha: 1)
            gold.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 595, height: 70)).fill()
            "GLOWZA — Treatment Consent Form".draw(at: CGPoint(x: 30, y: 24),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.white])
            y = 100
            "Procedure Disclosure".draw(at: CGPoint(x: 30, y: y),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.darkGray])
            y += 24
            "The proposed aesthetic treatment has been reviewed and consented to by the client.".draw(
                at: CGPoint(x: 30, y: y),
                withAttributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray])
            y += 60
            "Salon: \(draft.salon.name)".draw(at: CGPoint(x: 30, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
            y += 20
            "Service: \(draft.service?.name ?? "")".draw(at: CGPoint(x: 30, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
            y += 40
            // Acknowledgements
            "Client Acknowledgements:".draw(at: CGPoint(x: 30, y: y),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.darkGray])
            y += 20
            let ackText1 = "✓  I understand that clinical results vary and additional touch-up appointments may be needed."
            let ackText2 = "✓  I have disclosed all medical history including allergies, medications, and previous treatments."
            for ack in [ackText1, ackText2] {
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
                let nsStr = ack as NSString
                let bounds = nsStr.boundingRect(with: CGSize(width: 535, height: 60),
                                                options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
                nsStr.draw(in: CGRect(x: 30, y: y, width: 535, height: bounds.height + 4), withAttributes: attrs)
                y += bounds.height + 10
            }
            y += 10
            // Signature
            let resolvedSig = signatureOverride ?? draft.signatureImage
            if let sig = resolvedSig {
                "Digital Signature:".draw(at: CGPoint(x: 30, y: y),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.darkGray])
                y += 20
                sig.draw(in: CGRect(x: 30, y: y, width: 220, height: 88))
                y += 100
            }
            // Date signed
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            "Date Signed: \(formatter.string(from: Date()))".draw(at: CGPoint(x: 30, y: y),
                withAttributes: [.font: UIFont.italicSystemFont(ofSize: 10), .foregroundColor: UIColor.gray])
        }
    }
}
