// AuthViewModelTests.swift
// GLOWZATests
//
// Tests for AuthViewModel: computed properties (biometricButtonTitle, supportsFaceID,
// biometricIconName) and validation guards on signUp / signIn.
//
// Firebase network calls are never triggered because the validation guard returns
// early before reaching AuthService when fields are empty.

import XCTest
import LocalAuthentication
@testable import GLOWZA

// MARK: - Stub LAContext

/// An LAContext that always reports a specific biometry type without hitting the real
/// hardware, allowing deterministic tests.
private final class StubLAContext: LAContext {
    private let stubbedType: LABiometryType

    init(biometryType: LABiometryType) {
        self.stubbedType = biometryType
        super.init()
    }

    override var biometryType: LABiometryType { stubbedType }

    override func canEvaluatePolicy(
        _ policy: LAPolicy,
        error: NSErrorPointer
    ) -> Bool { true }
}

// MARK: - Tests

@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: - biometricButtonTitle / biometricIconName / supportsFaceID

    func test_biometricTitle_faceID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .faceID) }
        XCTAssertEqual(sut.biometricButtonTitle, "Continue with Face ID")
    }

    func test_biometricIcon_faceID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .faceID) }
        XCTAssertEqual(sut.biometricIconName, "faceid")
    }

    func test_supportsFaceID_true_whenFaceID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .faceID) }
        XCTAssertTrue(sut.supportsFaceID)
    }

    func test_biometricTitle_touchID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .touchID) }
        XCTAssertEqual(sut.biometricButtonTitle, "Continue with Biometrics")
    }

    func test_biometricIcon_touchID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .touchID) }
        XCTAssertEqual(sut.biometricIconName, "touchid")
    }

    func test_supportsFaceID_false_whenTouchID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .touchID) }
        XCTAssertFalse(sut.supportsFaceID)
    }

    func test_supportsFaceID_false_whenNone() {
        let sut = AuthViewModel { StubLAContext(biometryType: .none) }
        XCTAssertFalse(sut.supportsFaceID)
    }

    // MARK: - signUp validation

    func test_signUp_emptyEmail_setsError() async {
        let sut = AuthViewModel()
        sut.email    = ""
        sut.password = "secret"
        sut.fullName = "Alice"
        sut.phone    = "+1 555 000"
        await sut.signUp()
        XCTAssertEqual(sut.authenticationError, "All fields are required")
    }

    func test_signUp_emptyPassword_setsError() async {
        let sut = AuthViewModel()
        sut.email    = "a@b.com"
        sut.password = ""
        sut.fullName = "Alice"
        sut.phone    = "+1 555 000"
        await sut.signUp()
        XCTAssertEqual(sut.authenticationError, "All fields are required")
    }

    func test_signUp_emptyFullName_setsError() async {
        let sut = AuthViewModel()
        sut.email    = "a@b.com"
        sut.password = "secret"
        sut.fullName = ""
        sut.phone    = "+1 555 000"
        await sut.signUp()
        XCTAssertEqual(sut.authenticationError, "All fields are required")
    }

    func test_signUp_emptyPhone_setsError() async {
        let sut = AuthViewModel()
        sut.email    = "a@b.com"
        sut.password = "secret"
        sut.fullName = "Alice"
        sut.phone    = ""
        await sut.signUp()
        XCTAssertEqual(sut.authenticationError, "All fields are required")
    }

    func test_signUp_allEmpty_isNotAuthenticating() async {
        let sut = AuthViewModel()
        await sut.signUp()
        // Should not have started authenticating (guard exits before setting isAuthenticating)
        XCTAssertFalse(sut.isAuthenticating)
    }

    // MARK: - signIn validation

    func test_signIn_emptyEmail_setsError() async {
        let sut = AuthViewModel()
        sut.email    = ""
        sut.password = "secret"
        await sut.signIn()
        XCTAssertEqual(sut.authenticationError, "Email and password are required")
    }

    func test_signIn_emptyPassword_setsError() async {
        let sut = AuthViewModel()
        sut.email    = "a@b.com"
        sut.password = ""
        await sut.signIn()
        XCTAssertEqual(sut.authenticationError, "Email and password are required")
    }

    func test_signIn_bothEmpty_setsError() async {
        let sut = AuthViewModel()
        await sut.signIn()
        XCTAssertEqual(sut.authenticationError, "Email and password are required")
    }

    func test_signIn_allEmpty_isNotAuthenticating() async {
        let sut = AuthViewModel()
        await sut.signIn()
        XCTAssertFalse(sut.isAuthenticating)
    }

    // MARK: - Initial state

    func test_initialState_notAuthenticated() {
        let sut = AuthViewModel()
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertNil(sut.authenticationError)
    }

    func test_initialState_fieldsEmpty() {
        let sut = AuthViewModel()
        XCTAssertTrue(sut.email.isEmpty)
        XCTAssertTrue(sut.password.isEmpty)
        XCTAssertTrue(sut.fullName.isEmpty)
        XCTAssertTrue(sut.phone.isEmpty)
    }
}
