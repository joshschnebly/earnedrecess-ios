import XCTest
@testable import EarnedRecess

/// KeychainService writes to the real Keychain, so each test cleans up after itself.
/// Tests are isolated by deleting all touched keys in tearDown.
final class KeychainServiceTests: XCTestCase {

    private let keychain = KeychainService.shared

    override func tearDown() {
        // Clean up PIN and auxiliary keys written during the test so tests
        // cannot leak state into each other via the real Keychain.
        keychain.deletePIN()
        keychain.setPINAttempts(0)
        keychain.setPINLockoutUntil(nil)
        super.tearDown()
    }

    // MARK: - PIN Save & Verify

    func testSaveAndVerifyPIN() throws {
        // Arrange & Act
        try keychain.savePIN("1234")

        // Assert: correct PIN verifies, wrong PIN does not.
        XCTAssertTrue(keychain.verifyPIN("1234"), "Correct PIN should verify")
        XCTAssertFalse(keychain.verifyPIN("9999"), "Wrong PIN must not verify")
    }

    func testWrongPINFails() throws {
        try keychain.savePIN("4321")

        XCTAssertFalse(keychain.verifyPIN("1234"))
        XCTAssertFalse(keychain.verifyPIN("0000"))
        XCTAssertFalse(keychain.verifyPIN(""))
    }

    func testPINExistsAfterSave() throws {
        XCTAssertFalse(keychain.pinExists(), "No PIN should exist before saving")
        try keychain.savePIN("5678")
        XCTAssertTrue(keychain.pinExists(), "PIN should exist after saving")
    }

    func testPINDoesNotExistAfterDelete() throws {
        try keychain.savePIN("1111")
        XCTAssertTrue(keychain.pinExists())

        keychain.deletePIN()
        XCTAssertFalse(keychain.pinExists(), "PIN should be gone after deletion")
    }

    // MARK: - Change PIN

    func testChangePIN() throws {
        // Arrange: save initial PIN.
        try keychain.savePIN("1234")

        // Act: change to new PIN using correct current.
        try keychain.changePIN(current: "1234", new: "5678")

        // Assert: new PIN works, old PIN does not.
        XCTAssertTrue(keychain.verifyPIN("5678"), "New PIN should verify after change")
        XCTAssertFalse(keychain.verifyPIN("1234"), "Old PIN must not verify after change")
    }

    func testChangePINFailsWithWrongCurrent() throws {
        try keychain.savePIN("1234")

        XCTAssertThrowsError(try keychain.changePIN(current: "9999", new: "5678")) { error in
            guard let keychainError = error as? KeychainError,
                  case .incorrectPIN = keychainError else {
                XCTFail("Expected KeychainError.incorrectPIN, got \(error)")
                return
            }
        }

        // Original PIN must still be intact.
        XCTAssertTrue(keychain.verifyPIN("1234"), "Original PIN must remain unchanged")
    }

    // MARK: - PIN Attempt Tracking

    func testPINAttemptsRoundTrip() {
        // Arrange & Act
        keychain.setPINAttempts(3)

        // Assert
        XCTAssertEqual(keychain.getPINAttempts(), 3)
    }

    func testPINAttemptsDefaultsToZero() {
        // After tearDown clears attempts, reading should return 0.
        XCTAssertEqual(keychain.getPINAttempts(), 0,
                       "PIN attempts should default to 0 when no value is stored")
    }

    func testPINAttemptsCanBeReset() {
        keychain.setPINAttempts(3)
        XCTAssertEqual(keychain.getPINAttempts(), 3)

        keychain.setPINAttempts(0)
        XCTAssertEqual(keychain.getPINAttempts(), 0)
    }

    // MARK: - Lockout Date

    func testLockoutDateRoundTrip() {
        // Arrange: a specific point in time (fractional seconds truncated for
        // round-trip safety through string serialization).
        let target = Date(timeIntervalSinceReferenceDate: 1_000_000)

        // Act
        keychain.setPINLockoutUntil(target)
        let retrieved = keychain.getPINLockoutUntil()

        // Assert: retrieved date must be within 1 second of what was stored.
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!.timeIntervalSinceReferenceDate,
                       target.timeIntervalSinceReferenceDate,
                       accuracy: 1.0,
                       "Lockout date should round-trip through Keychain with sub-second accuracy")
    }

    func testLockoutDateClearedWithNil() {
        keychain.setPINLockoutUntil(Date())
        XCTAssertNotNil(keychain.getPINLockoutUntil(), "Pre-condition: lockout date exists")

        keychain.setPINLockoutUntil(nil)
        XCTAssertNil(keychain.getPINLockoutUntil(), "Lockout date should be nil after clearing")
    }

    func testLockoutDateReturnsNilWhenNotSet() {
        // tearDown already cleared it; querying should return nil.
        XCTAssertNil(keychain.getPINLockoutUntil())
    }

    // MARK: - Device Salt

    func testDeviceSaltIsConsistent() {
        // The private deviceSalt() method is exercised indirectly: hashing the
        // same PIN twice must yield the same result (salt is stable).
        // We use savePIN / verifyPIN to confirm the salt is idempotent.
        try? keychain.savePIN("7777")

        // Verifying the same PIN twice confirms the salt did not regenerate.
        XCTAssertTrue(keychain.verifyPIN("7777"))
        XCTAssertTrue(keychain.verifyPIN("7777"),
                      "Device salt must be stable — verifying the same PIN twice must always succeed")
    }
}
