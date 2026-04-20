import Foundation
import Combine
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var authenticationError: String?

    private let contextProvider: () -> LAContext

    init(contextProvider: @escaping () -> LAContext = LAContext.init) {
        self.contextProvider = contextProvider
    }

    var biometricButtonTitle: String {
        supportsFaceID ? "Continue with Face ID" : "Continue with Biometrics"
    }

    var biometricIconName: String {
        supportsFaceID ? "faceid" : "touchid"
    }

    var supportsFaceID: Bool {
        let context = contextProvider()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .faceID
    }

    func authenticate() {
        let context = contextProvider()
        var error: NSError?

        authenticationError = nil

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authenticationError = errorMessage(for: error)
            return
        }

        isAuthenticating = true

        Task {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Use Face ID to securely access your GLOWZA account."
                )

                isAuthenticating = false
                isAuthenticated = success

                if !success {
                    authenticationError = "Authentication was cancelled."
                }
            } catch {
                isAuthenticating = false
                authenticationError = errorMessage(for: error as NSError)
            }
        }
    }

    func resetError() {
        authenticationError = nil
    }

    private func errorMessage(for error: NSError?) -> String {
        guard let error else {
            return "Biometric authentication is not available on this device."
        }

        switch error.code {
        case LAError.biometryNotAvailable.rawValue:
            return "Face ID is not available on this device."
        case LAError.biometryNotEnrolled.rawValue:
            return "Set up Face ID in Settings before using this option."
        case LAError.biometryLockout.rawValue:
            return "Face ID is locked. Unlock it in Settings and try again."
        case LAError.userCancel.rawValue, LAError.systemCancel.rawValue, LAError.appCancel.rawValue:
            return "Authentication was cancelled."
        default:
            return error.localizedDescription
        }
    }
}
