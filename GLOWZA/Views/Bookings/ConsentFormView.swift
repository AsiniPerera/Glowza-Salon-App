import SwiftUI
import PencilKit

// MARK: - Signature Canvas (UIViewRepresentable - must keep)
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var onDrawingChanged: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool          = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.backgroundColor = .clear
        canvasView.delegate = context.coordinator
        return canvasView
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDrawingChanged: onDrawingChanged) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var onDrawingChanged: () -> Void
        init(onDrawingChanged: @escaping () -> Void) { self.onDrawingChanged = onDrawingChanged }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) { onDrawingChanged() }
    }
}

// MARK: - Consent Form View
struct ConsentFormView: View {

    @Binding var draft: BookingDraft
    let onConfirm: () -> Void
    let onBack: () -> Void

    @State private var canvasView = PKCanvasView()
    @State private var isAgreed = false
    @State private var hasSignature = false
    private var appSettings: AppSettings { AppSettings.shared }

    private var accent: Color { appSettings.themeBrand }
    private var dark: Color { appSettings.themeText }
    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var bottomBarBackground: Color { appSettings.themeSurface }

    var body: some View {
        ZStack(alignment: .bottom) {
            pageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Text("Final Consent Form")
                        .glowzaFont(size: 28, weight: .bold)
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
                    .glowzaFont(size: 20, weight: .semibold)
                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "5F6168"))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Treatment Consent Form")
                    .glowzaFont(size: 14, weight: .bold)
                    .foregroundColor(dark)
                    .tracking(3)
                Text("REF: GZ-2024-089")
                    .glowzaFont(size: 12, weight: .medium)
                    .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.55) : Color(hex: "666A72"))
                    .tracking(1.6)
                Text("I acknowledge that cosmetic treatments may involve risks such as redness, swelling, irritation, allergic reactions, or temporary discomfort. Results may vary and are not guaranteed. I confirm that I have disclosed relevant medical information and understand post-treatment care instructions. I accept these risks and consent to proceed voluntarily.")
                    .glowzaFont(size: 14)
                    .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.75) : Color(hex: "4A4C52"))
                    .lineSpacing(6)
            }
            .padding(.bottom, 4)

            // Checkbox agreement
            Button(action: { isAgreed.toggle() }) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(isAgreed ? accent : Color(hex: "CCCCCC"), lineWidth: 2)
                            .frame(width: 22, height: 22)
                        if isAgreed {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(accent)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .glowzaFont(size: 12, weight: .bold)
                                .foregroundColor(.white)
                        }
                    }
                    Text("I have read and agree to the treatment consent terms above, and confirm that this signature is my own.")
                        .glowzaFont(size: 13)
                        .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.8) : Color(hex: "4A4C52"))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Electronic Signature")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(dark)
                        .tracking(2.2)
                    Spacer()
                    Button(action: { canvasView.drawing = PKDrawing() }) {
                        Text("CLEAR")
                            .glowzaFont(size: 11)
                            .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.55) : Color(hex: "777A81"))
                            .tracking(2)
                    }
                }

                ZStack {
                    Rectangle()
                        .fill(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F7F7F7"))
                        .overlay(Rectangle().stroke(Color(hex: "C4C4C7"), lineWidth: 1))
                        .frame(height: 160)

                    if !hasSignature {
                        VStack(spacing: 12) {
                            Text("Sign here (optional)")
                                .glowzaFont(size: 20)
                                .foregroundColor(Color(hex: "D0D0D3"))
                                .italic()
                            Rectangle()
                                .fill(Color(hex: "D6D6D9"))
                                .frame(width: 220, height: 1)
                        }
                    }

                    SignatureCanvasView(canvasView: $canvasView) {
                        hasSignature = !canvasView.drawing.strokes.isEmpty
                    }
                    .frame(height: 160)
                }
            }
        }
        .padding(18)
        .background(surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            if isAgreed {
                Button(action: {
                    if hasSignature {
                        draft.signatureImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
                    }
                    onConfirm()
                }) {
                    Text("Next")
                        .glowzaFont(size: 15, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(bottomBarBackground)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isAgreed)
    }
}
