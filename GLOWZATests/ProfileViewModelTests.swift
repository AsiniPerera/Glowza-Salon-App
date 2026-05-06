// ProfileViewModelTests.swift
// GLOWZATests
//
// Tests for ProfileViewModel: computed properties (initials, avatarImage),
// validation logic, and in-memory state transitions (startEditing / cancelEditing).

import XCTest
@testable import GLOWZA

final class ProfileViewModelTests: XCTestCase {

    // Create a fresh instance for each test to avoid UserDefaults side-effects.
    private var sut: ProfileViewModel!

    override func setUp() {
        super.setUp()
        sut = ProfileViewModel()
        // Start from a predictable state
        sut.fullName    = "Asini Perera"
        sut.email       = "asini@example.com"
        sut.phone       = "+94 77 123 4567"
        sut.dateOfBirth = "1998-06-15"
        sut.skinType    = "Combination"
        sut.avatarData  = nil
        sut.isEditing   = false
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

    func test_initials_singleWordName() {
        sut.fullName = "Madonna"
        XCTAssertEqual(sut.initials, "M")
    }

    func test_initials_threeWordName_takesFirstTwo() {
        sut.fullName = "John Michael Doe"
        XCTAssertEqual(sut.initials, "JM")
    }

    func test_initials_emptyName() {
        sut.fullName = ""
        XCTAssertEqual(sut.initials, "")
    }

    func test_initials_uppercased() {
        sut.fullName = "alice bob"
        XCTAssertEqual(sut.initials, "AB")
    }

    // MARK: - avatarImage

    func test_avatarImage_nilWhenNoData() {
        sut.avatarData = nil
        XCTAssertNil(sut.avatarImage)
    }

    func test_avatarImage_nilForInvalidData() {
        sut.avatarData = Data([0xFF, 0xFE, 0x00])   // not a valid JPEG
        XCTAssertNil(sut.avatarImage)
    }

    // MARK: - startEditing / cancelEditing

    func test_startEditing_setsIsEditingTrue() {
        sut.startEditing()
        XCTAssertTrue(sut.isEditing)
    }

    func test_cancelEditing_setsIsEditingFalse() {
        sut.startEditing()
        sut.cancelEditing()
        XCTAssertFalse(sut.isEditing)
    }

    func test_cancelEditing_clearsValidationError() {
        sut.startEditing()
        sut.validationError = "Some error"
        sut.cancelEditing()
        XCTAssertNil(sut.validationError)
    }

    // MARK: - skinTypes

    func test_skinTypes_containsStandardOptions() {
        XCTAssertTrue(sut.skinTypes.contains("Normal"))
        XCTAssertTrue(sut.skinTypes.contains("Oily"))
        XCTAssertTrue(sut.skinTypes.contains("Dry"))
        XCTAssertTrue(sut.skinTypes.contains("Combination"))
        XCTAssertTrue(sut.skinTypes.contains("Sensitive"))
    }

    // MARK: - Validation (indirectly via saveProfile guard)
    // We test the validate() logic by calling saveProfile() and inspecting validationError.
    // saveProfile() calls validate() synchronously before dispatching any async work.

    func test_validate_emptyNameSetsError() {
        sut.isEditing = true
        sut.fullName = "   "   // whitespace only
        sut.email = "valid@example.com"
        sut.saveProfile()
        XCTAssertEqual(sut.validationError, "Name cannot be empty.")
    }

    func test_validate_invalidEmailSetsError() {
        sut.isEditing = true
        sut.fullName = "Alice"
        sut.email = "not-an-email"
        sut.saveProfile()
        XCTAssertEqual(sut.validationError, "Please enter a valid email address.")
    }

    func test_validate_validInputClearsError() {
        sut.isEditing = true
        sut.fullName = "Alice Smith"
        sut.email = "alice@example.com"
        sut.validationError = "Old error"
        sut.saveProfile()
        // validate passes → error cleared, isSaving becomes true
        XCTAssertNil(sut.validationError)
        XCTAssertTrue(sut.isSaving)
    }

    func test_validate_emailFormats() {
        let valid   = ["user@example.com", "name+tag@domain.org", "a@b.io"]
        let invalid = ["plainaddress", "@no-local.part", "missing@dot", "double@@domain.com"]

        for email in valid {
            sut.isEditing = true
            sut.fullName = "Test"
            sut.email = email
            sut.isSaving = false
            sut.saveProfile()
            XCTAssertNil(sut.validationError,         "Expected nil error for \(email)")
        }

        for email in invalid {
            sut.isEditing = true
            sut.fullName = "Test"
            sut.email = email
            sut.isSaving = false
            sut.saveProfile()
            XCTAssertNotNil(sut.validationError,      "Expected error for \(email)")
        }
    }
}
