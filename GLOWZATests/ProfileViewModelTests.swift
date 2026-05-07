// ProfileViewModelTests.swift
// GLOWZATests

import XCTest
@testable import GLOWZA

final class ProfileViewModelTests: XCTestCase {

    private var sut: ProfileViewModel!

    override func setUp() {
        super.setUp()
        sut = ProfileViewModel()
        sut.fullName        = "Asini Perera"
        sut.email           = "asini@example.com"
        sut.isEditing       = false
        sut.validationError = nil
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - initials

    func test_initials_twoWordName() {
        sut.fullName = "Asini Perera"
        XCTAssertEqual(sut.initials, "AP")
    }

    func test_initials_emptyName() {
        sut.fullName = ""
        XCTAssertEqual(sut.initials, "")
    }

    func test_initials_uppercased() {
        sut.fullName = "alice bob"
        XCTAssertEqual(sut.initials, "AB")
    }

    // MARK: - Editing state

    func test_startEditing_setsIsEditingTrue() {
        sut.startEditing()
        XCTAssertTrue(sut.isEditing)
    }

    func test_cancelEditing_setsIsEditingFalse() {
        sut.startEditing()
        sut.cancelEditing()
        XCTAssertFalse(sut.isEditing)
    }

    // MARK: - Validation

    func test_validate_emptyNameSetsError() {
        sut.isEditing = true
        sut.fullName  = "   "
        sut.email     = "valid@example.com"
        sut.saveProfile()
        XCTAssertEqual(sut.validationError, "Name cannot be empty.")
    }

    func test_validate_invalidEmailSetsError() {
        sut.isEditing = true
        sut.fullName  = "Alice"
        sut.email     = "not-an-email"
        sut.saveProfile()
        XCTAssertEqual(sut.validationError, "Please enter a valid email address.")
    }
}
