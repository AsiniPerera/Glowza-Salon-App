// AuthViewModelTests.swift
// GLOWZATests

import XCTest
import LocalAuthentication
@testable import GLOWZA

// MARK: - Stub LAContext

private final class StubLAContext: LAContext {
    private let stubbedType: LABiometryType
    init(biometryType: LABiometryType) {
        self.stubbedType = biometryType
        super.init()
    }
    override var biometryType: LABiometryType { stubbedType }
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool { true }
}

// MARK: - Tests

@MainActor
final class AuthViewModelTests: XCTestCase {


    func test_supportsFaceID_true_whenFaceID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .faceID) }
        XCTAssertTrue(sut.supportsFaceID)
    }

    func test_supportsFaceID_false_whenTouchID() {
        let sut = AuthViewModel { StubLAContext(biometryType: .touchID) }
        XCTAssertFalse(sut.supportsFaceID)
    }

    // MARK: - signUp validation

    func test_signUp_emptyEmail_setsError() async {
        let sut = AuthViewModel()
        sut.email = ""; sut.password = "secret"; sut.fullName = "Alice"; sut.phone = "+1 555 000"
        await sut.signUp()
        XCTAssertEqual(sut.authenticationError, "All fields are required")
    }

    func test_signUp_emptyPassword_setsError() async {
        let sut = AuthViewModel()
        sut.email = "a@b.com"; sut.password = ""; sut.fullName = "Alice"; sut.phone = "+1 555 000"
        await sut.signUp()
        XCTAssertEqual(sut.authenticationError, "All fields are required")
    }

    // MARK: - signIn validation

    func test_signIn_emptyEmail_setsError() async {
        let sut = AuthViewModel()
        sut.email = ""; sut.password = "secret"
        await sut.signIn()
        XCTAssertEqual(sut.authenticationError, "Email and password are required")
    }

    func test_signIn_bothEmpty_setsError() async {
        let sut = AuthViewModel()
        await sut.signIn()
        XCTAssertEqual(sut.authenticationError, "Email and password are required")
    }

    // MARK: - Initial state

    func test_initialState_notAuthenticated() {
        let sut = AuthViewModel()
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertNil(sut.authenticationError)
    }
}
