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
    let onBack: () -> Void

    @State private var canvasView = PKCanvasView()

    private let dark = Color(hex: "1F2126")
    private let accent = Color(hex: "FF006E")
    private var hasSignature: Bool { !canvasView.drawing.strokes.isEmpty }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "F1F1F1").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Text("Final Consent Form")
                        .font(.system(size: 52, weight: .medium, design: .serif))
                        .foregroundColor(dark)
                        .padding(.horizontal, 20)
                    signatureSection
                    Spacer().frame(height: 110)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            bottomBar
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "5F6168"))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("TREATMENT CONSENT FORM")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(dark)
                    .tracking(3)
                Text("REF: GZ-2024-089")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "666A72"))
                    .tracking(1.6)
                Text("I acknowledge that cosmetic treatments may involve risks such as redness, swelling, irritation, allergic reactions, or temporary discomfort. Results may vary and are not guaranteed. I confirm that I have disclosed relevant medical information and understand post-treatment care instructions. I accept these risks and consent to proceed voluntarily.")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "4A4C52"))
                    .lineSpacing(6)
            }
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ELECTRONIC SIGNATURE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(dark)
                        .tracking(2.2)
                    Spacer()
                    Button(action: { canvasView.drawing = PKDrawing() }) {
                        Text("Clear")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "777A81"))
                            .tracking(1)
                    }
                }

                ZStack {
                    Rectangle()
                        .fill(Color(hex: "F7F7F7"))
                        .overlay(Rectangle().stroke(Color(hex: "C4C4C7"), lineWidth: 1))
                        .frame(height: 160)

                    if !hasSignature {
                        VStack(spacing: 12) {
                            Text("Sign here")
                                .font(.system(size: 48, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "D0D0D3"))
                            .italic()
                            Rectangle()
                                .fill(Color(hex: "D6D6D9"))
                                .frame(width: 220, height: 1)
                        }
                    }

                    SignatureCanvasView(canvasView: $canvasView)
                        .frame(height: 160)
                }
            }
        }
        .padding(18)
        .background(Color(hex: "E5E2E2"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Button(action: {
                guard hasSignature else { return }
                draft.signatureImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                onConfirm()
            }) {
                Text("Next")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(hasSignature ? accent : Color(hex: "BFC2C8"))
                    .clipShape(Capsule())
            }
            .disabled(!hasSignature)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(hex: "F1F1F1"))
        }
    }
}
