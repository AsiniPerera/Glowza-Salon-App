import SwiftUI


struct FaceIDAuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.glowzaBackground, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 128, height: 128)
                            .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)

                        Image(systemName: viewModel.biometricIconName)
                            .font(.system(size: 52, weight: .light))
                            .foregroundColor(Color.glowzaGoldDark)
                    }

                    Text("Secure Sign In")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)

                    Text("Use Face ID for a faster, private sign in to your GLOWZA account.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 18)
                }

                VStack(spacing: 14) {
                    Button(action: viewModel.authenticate) {
                        HStack(spacing: 10) {
                            if viewModel.isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: viewModel.biometricIconName)
                            }

                            Text(viewModel.isAuthenticating ? "Checking Face ID..." : viewModel.biometricButtonTitle)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.glowzaGold)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.isAuthenticating)

                    Text("Your biometric data stays on this device and is never stored by GLOWZA.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Color.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.glowzaGold.opacity(0.22), lineWidth: 1)
                )

                if viewModel.isAuthenticated {
                    VStack(spacing: 8) {
                        Label("Face ID verified", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("You're signed in and ready to continue.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.65))
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .navigationTitle("Face ID")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Authentication Issue", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                viewModel.resetError()
            }
        } message: {
            Text(viewModel.authenticationError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.authenticationError != nil },
            set: { newValue in
                if !newValue {
                    viewModel.resetError()
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        FaceIDAuthView()
    }
}
