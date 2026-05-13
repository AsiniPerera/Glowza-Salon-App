import XCTest
@testable import GLOWZA

@MainActor
final class AuthViewModelTests: XCTestCase {

    func test_signUp_emptyEmail_setsError() async {
        let sut = AuthViewModel()
        sut.email = ""; sut.password = "secret"; sut.fullName = "Alice"; sut.phone = "+1 555 000"
        await sut.signUp()
        XCTAssertEqual(sut.authenticationError, "All fields are required")
    }

    func test_signIn_emptyEmail_setsError() async {
        let sut = AuthViewModel()
        sut.email = ""; sut.password = "secret"
        await sut.signIn()
        XCTAssertEqual(sut.authenticationError, "Please enter your email and password.")
    }
}
