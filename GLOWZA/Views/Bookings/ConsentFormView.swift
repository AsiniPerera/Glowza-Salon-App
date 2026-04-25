import SwiftUI
import PencilKit

// MARK: - Signature Canvas (UIViewRepresentable - must keep)
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool          = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.backgroundColor = .clear
        return canvasView
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// MARK: - Consent Form View
struct ConsentFormView: View {

    @Binding var draft: BookingDraft
    let onConfirm: () -> Void
    let onBack:    () -> Void

    @State private var canvasView          = PKCanvasView()
    @State private var iAcknowledge        = false
    @State private var isExpanded          = false

    private let dark   = Color(hex: "1A1A1A")
    private let accent = Color(hex: "AF1C47")
    private let bg     = Color.white

    private var subtotal: Double { draft.service?.price ?? 0 }
    private var taxes:    Double { subtotal * 0.10 }
    private var total:    Double { subtotal + taxes }
    private var hasSignature: Bool { !canvasView.drawing.strokes.isEmpty }

    var body: some View {
        ZStack(alignment: .bottom) {
            bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    consentPreviewSection
                    signatureSection
                    consentWarning
                    paymentSummarySection
                    Spacer().frame(height: 110)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            bottomBar
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(dark)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Digital Consent & Payment")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(dark)
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 11))
                        .foregroundColor(accent)
                    Text("Secure & Protected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accent)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Consent Preview Card
    private var consentPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONSENT FORM PREVIEW")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "8A8A8A"))
                .tracking(1)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F5EDE8"))
                            .frame(width: 44, height: 44)
                        Text("G+")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accent)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Treatment Consent Form")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(dark)
                        Text("Glowza Aesthetic Studio")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    Spacer()
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 11))
                            Text("PDF")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "F5EDE8"))
                        .cornerRadius(8)
                    }
                }

                // Sections
                consentSection(
                    title: "Purpose of Treatment",
                    body: "This treatment is designed to improve skin texture, tone, and overall radiance. Results may vary and multiple sessions may be recommended."
                )

                if isExpanded {
                    consentSection(
                        title: "Potential Risks & Side Effects",
                        body: "Minor redness, swelling, or sensitivity may occur post-treatment. These effects are temporary and typically subside within 24–48 hours."
                    )
                    consentSection(
                        title: "Aftercare & Recommendations",
                        body: "Avoid sun exposure for 48 hours. Apply SPF 50 daily. Do not use exfoliants or retinoids for 72 hours post-treatment."
                    )
                }

                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Collapse" : "View full document")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(accent)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accent)
                    }
                }
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    private func consentSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(dark)
            Text(body)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "5A4A42"))
                .lineSpacing(4)
        }
    }

    // MARK: - Signature Section
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SIGNATURE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "8A8A8A"))
                .tracking(1)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sign below to confirm")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Spacer()
                    Button(action: { canvasView.drawing = PKDrawing() }) {
                        Text("Clear")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "E05A4B"))
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "FAFAFA"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "E8E0DC"), lineWidth: 1)
                        )
                        .frame(height: 120)

                    if !hasSignature {
                        Text("Your Signature")
                            .font(.system(size: 20, design: .serif))
                            .foregroundColor(Color(hex: "D0C8C0"))
                            .italic()
                    }

                    SignatureCanvasView(canvasView: $canvasView)
                        .frame(height: 120)
                        .cornerRadius(12)
                }

                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(accent)
                    Text("I confirm that I have read and understood the consent form and agree to the treatment.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Consent Warning
    private var consentWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "AF1C47"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Consent must be signed before payment")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "7A5C00"))
                Text("Please sign the consent form above to proceed.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "9A7A30"))
            }
        }
        .padding(14)
        .background(Color(hex: "FFF8E7"))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    // MARK: - Payment Summary
    private var paymentSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PAYMENT SUMMARY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "8A8A8A"))
                .tracking(1)
                .padding(.horizontal, 20)

            VStack(spacing: 14) {
                if let service = draft.service {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "FFF0F4"))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: service.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(accent)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(dark)
                            Text("Duration: \(service.duration)")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8A8A8A"))
                        }
                        Spacer()
                        Text("LKR \(Int(service.price))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(dark)
                    }

                    Divider()
                }

                paymentRow("Subtotal",    amount: subtotal, bold: false)
                paymentRow("Taxes & Fees (10%)", amount: taxes,    bold: false)

                Divider()

                paymentRow("Total",       amount: total,    bold: true)
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    private func paymentRow(_ label: String, amount: Double, bold: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: bold ? 15 : 13, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? dark : Color(hex: "8A8A8A"))
            Spacer()
            Text("LKR \(String(format: "%.0f", amount))")
                .font(.system(size: bold ? 16 : 13, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? accent : dark)
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        let canProceed = hasSignature
        return VStack(spacing: 10) {
            Button(action: {
                if canProceed {
                    draft.signatureImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                    onConfirm()
                }
            }) {
                HStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                    Text("Pay LKR \(String(format: "%.0f", total)) Securely")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .background(canProceed ? Color(hex: "1A1A1A") : Color(hex: "A0A0A0"))
                .cornerRadius(14)
            }
            .disabled(!canProceed)

            HStack(spacing: 5) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "8A8A8A"))
                Text("100% Secure Payments")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }

            HStack(spacing: 12) {
                Button(action: {}) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12))
                        Text("Download Receipt")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(dark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "E8E0DC"), lineWidth: 1))
                }
                Button(action: {}) {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 12))
                        Text("View Booking Details")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(dark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "E8E0DC"), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
    }
}
