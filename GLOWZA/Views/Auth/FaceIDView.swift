import SwiftUI
import LocalAuthentication

private let brand = Color(hex: "AF1C47")

// MARK: - Face ID Auth View
struct FaceIDAuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            Circle().fill(brand.opacity(0.06)).frame(width: 360).offset(x: 160, y: -200)
            Circle().fill(brand.opacity(0.04)).frame(width: 280).offset(x: -130, y: 320)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle().fill(brand.opacity(0.08)).frame(width: 130, height: 130)
                        Circle().fill(brand.opacity(0.12)).frame(width: 100, height: 100)
                        Circle().fill(brand).frame(width: 76, height: 76)
                            .shadow(color: brand.opacity(0.30), radius: 16)
                        Image(systemName: viewModel.biometricIconName)
                            .font(.system(size: 34, weight: .light))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 10) {
                        Text("Secure Sign In")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Text("Use Face ID for a faster, private\nsign in to your GLOWZA account.")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "6B6B6B"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }

                Spacer().frame(height: 44)

                VStack(spacing: 16) {
                    Button(action: viewModel.authenticate) {
                        HStack(spacing: 10) {
                            if viewModel.isAuthenticating {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: viewModel.biometricIconName)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            Text(viewModel.isAuthenticating ? "Checking Face ID…" : viewModel.biometricButtonTitle)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.isAuthenticating ? Color(hex: "BEBEBE") : brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: viewModel.isAuthenticating ? .clear : brand.opacity(0.28), radius: 12, x: 0, y: 5)
                    }
                    .disabled(viewModel.isAuthenticating)

                    if viewModel.isAuthenticated {
                        Label("Face ID verified — you're signed in", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "00A878"))
                            .transition(.scale.combined(with: .opacity))
                    }

                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 11))
                            .foregroundColor(brand.opacity(0.6))
                        Text("Your biometric data stays on this device")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                }
                .padding(28)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(hex: "F0F0F0"), lineWidth: 1)
                )

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .navigationTitle("Face ID")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Authentication Issue", isPresented: errorBinding) {
            Button("OK", role: .cancel) { viewModel.resetError() }
        } message: {
            Text(viewModel.authenticationError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.authenticationError != nil },
            set: { if !$0 { viewModel.resetError() } }
        )
    }
}

#Preview {
    NavigationStack { FaceIDAuthView() }
}
