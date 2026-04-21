import XCTest
import Foundation
@testable import EarnedRecess

final class PINLockoutTests: XCTestCase {

    private let keychain = KeychainService.shared

    override func setUp() {
        super.setUp()
        cleanupKeychain()
    }

    override func tearDown() {
        cleanupKeychain()
        super.tearDown()
    }

    private func cleanupKeychain() {
        keychain.setPINAttempts(0)
        keychain.setPINLockoutUntil(nil)
        keychain.deletePIN()
    }

    // MARK: - Attempt tracking

    func test_setPINAttempts_3_thenGetReturns3() {
        keychain.setPINAttempts(1)
        keychain.setPINAttempts(2)
        keychain.setPINAttempts(3)
        XCTAssertEqual(keychain.getPINAttempts(), 3)
    }

    func test_resetAttemptsTo0_works() {
        keychain.setPINAttempts(3)
        keychain.setPINAttempts(0)
        XCTAssertEqual(keychain.getPINAttempts(), 0)
    }

    // MARK: - Lockout date

    func test_getPINLockoutUntil_returnsNilInitially() {
        XCTAssertNil(keychain.getPINLockoutUntil())
    }

    func test_setPINLockoutUntil_futureDate_isInFuture() {
        let futureDate = Date().addingTimeInterval(60)
        keychain.setPINLockoutUntil(futureDate)
        let stored = keychain.getPINLockoutUntil()
        XCTAssertNotNil(stored)
        XCTAssertGreaterThan(stored!, Date())
    }

    func test_setPINLockoutUntil_nil_clearsTheLockout() {
        keychain.setPINLockoutUntil(Date().addingTimeInterval(60))
        keychain.setPINLockoutUntil(nil)
        XCTAssertNil(keychain.getPINLockoutUntil())
    }

    func test_lockoutDate_roundtrips_accurately() {
        let date = Date().addingTimeInterval(30)
        keychain.setPINLockoutUntil(date)
        let stored = keychain.getPINLockoutUntil()
        XCTAssertNotNil(stored)
        // TimeIntervalSince1970 is stored as a string; allow 1-second tolerance
        XCTAssertEqual(stored!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - Successful PIN flow

    func test_successfulPINVerification_resetsAttempts() throws {
        // Save a PIN
        try keychain.savePIN("1234")
        // Simulate 2 failed attempts persisted
        keychain.setPINAttempts(2)
        XCTAssertEqual(keychain.getPINAttempts(), 2)

        // Simulate successful verification (as PINEntryView.verify() does)
        let isCorrect = keychain.verifyPIN("1234")
        XCTAssertTrue(isCorrect)

        // After success, reset attempts and clear lockout
        keychain.setPINAttempts(0)
        keychain.setPINLockoutUntil(nil)

        XCTAssertEqual(keychain.getPINAttempts(), 0)
        XCTAssertNil(keychain.getPINLockoutUntil())
    }

    // MARK: - Lock state detection

    func test_futureLockoutDate_indicatesLockedOut() {
        let until = Date().addingTimeInterval(TimeInterval(Constants.App.pinLockoutSeconds))
        keychain.setPINLockoutUntil(until)
        let stored = keychain.getPINLockoutUntil()
        XCTAssertNotNil(stored)
        let remaining = Int(stored!.timeIntervalSinceNow)
        XCTAssertGreaterThan(remaining, 0)
    }

    func test_pastLockoutDate_doesNotIndicateLockedOut() {
        // A lockout date in the past means the lockout has expired
        let pastDate = Date().addingTimeInterval(-10)
        keychain.setPINLockoutUntil(pastDate)
        let stored = keychain.getPINLockoutUntil()
        XCTAssertNotNil(stored)
        XCTAssertLessThanOrEqual(stored!.timeIntervalSinceNow, 0)
    }
}
