import Foundation
import Combine
import LocalAuthentication
import FirebaseAuth

// MARK: - Auth View Model
// This class manages the authentication state and flows for the app!
// It connects the UI to the AuthService and handle biometrics.
// @MainActor ensures that all updates to @Published properties happen on the main thread!
@MainActor
final class AuthViewModel: ObservableObject {
    // @Published properties automatically notify SwiftUI views when they change!
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var authenticationError: String?
    
    // Form fields!
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var phone = ""

    // Provider closure for LAContext (allows mocking in tests!).
    private let contextProvider: () -> LAContext
    private let authService = AuthService.shared

    init(contextProvider: @escaping () -> LAContext = LAContext.init) {
        self.contextProvider = contextProvider
    }

    // Dynamic titles and icons based on Face ID vs Touch ID!
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
    
    // MARK: - Sign Up
    func signUp() async {
        // Validate fields!
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty, !phone.isEmpty else {
            authenticationError = "All fields are required"
            return
        }
        
        isAuthenticating = true
        authenticationError = nil
        
        do {
            try await authService.signUp(
                fullName: fullName,
                email: email,
                phone: phone,
                password: password
            )
            
            isAuthenticated = true
            isAuthenticating = false
            clearFields()
            
            // NEW: Ensure all services reload data for the NEW user!
            NotificationManager.shared.loadNotificationHistory()
            Task { await BookingStore.shared.fetchUserBookings() }
            
            AppSettings.shared.shouldShowLoginReminder = true
        } catch {
            // Convert technical Firebase errors to friendly student/user messages!
            authenticationError = friendlyMessage(for: error)
            isAuthenticating = false
        }
    }
    
    // MARK: - Sign In
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            authenticationError = "Please enter your email and password."
            return
        }
        
        isAuthenticating = true
        authenticationError = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            isAuthenticated = true
            isAuthenticating = false
            clearFields()
            
            // NEW: Ensure all services reload data for the NEW user!
            NotificationManager.shared.loadNotificationHistory()
            Task { await BookingStore.shared.fetchUserBookings() }
            
            AppSettings.shared.shouldShowLoginReminder = true
        } catch {
            authenticationError = friendlyMessage(for: error)
            isAuthenticating = false
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try authService.signOut()
            isAuthenticated = false
            clearFields()
            
            // CRITICAL: Clear all user-specific data from memory on logout!
            BookingStore.shared.clearMemory()
            NotificationManager.shared.clearMemory()
        } catch {
            authenticationError = error.localizedDescription
        }
    }
    
    private func clearFields() {
        email = ""
        password = ""
        fullName = ""
        phone = ""
    }

    // MARK: - Friendly Firebase error messages
    // This helper maps complex Firebase error codes to nice, human-readable strings!
    private func friendlyMessage(for error: Error) -> String {
        let code = AuthErrorCode(_bridgedNSError: error as NSError)?.code
        switch code {
        case .invalidEmail:
            return "That doesn't look like a valid email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with that email. Try signing up first."
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Sign in instead."
        case .weakPassword:
            return "Your password is too weak — use at least 6 characters."
        case .networkError:
            return "No internet connection. Check your network and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .invalidCredential, .credentialAlreadyInUse:
            return "Incorrect email or password. Please check and try again."
        default:
            return "Something went wrong. Please try again."
        }
    }

    // MARK: - Biometric Authentication
    // Triggers Face ID or Touch ID!
    func authenticate() {
        let context = contextProvider()
        var error: NSError?

        authenticationError = nil

        // Check if biometrics are available!
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authenticationError = errorMessage(for: error)
            return
        }

        isAuthenticating = true

        // Run the async evaluation in a Task!
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

    // Maps LocalAuthentication errors to friendly strings!
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
