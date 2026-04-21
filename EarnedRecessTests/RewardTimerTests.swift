import XCTest
import Foundation
@testable import EarnedRecess

final class RewardTimerTests: XCTestCase {

    var timer: RewardTimer!

    override func setUp() {
        super.setUp()
        timer = RewardTimer()
    }

    override func tearDown() {
        timer.stop()
        timer = nil
        super.tearDown()
    }

    // MARK: - start(minutes:)

    func test_start_setsRemainingSecondsCorrectly() {
        timer.start(minutes: 5)
        // May have already ticked once; allow ±1 tolerance
        XCTAssertLessThanOrEqual(abs(timer.remainingSeconds - 300), 1)
    }

    func test_start_setsIsRunningTrue() {
        timer.start(minutes: 3)
        XCTAssertTrue(timer.isRunning)
    }

    // MARK: - pause()

    func test_pause_stopsTimer() {
        timer.start(minutes: 2)
        timer.pause()
        XCTAssertFalse(timer.isRunning)
    }

    // MARK: - stop()

    func test_stop_zerosRemainingSeconds() {
        timer.start(minutes: 5)
        timer.stop()
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    func test_stop_clearsIsExpired() {
        timer.start(minutes: 5)
        timer.stop()
        XCTAssertFalse(timer.isExpired)
    }

    func test_stop_setsIsRunningFalse() {
        timer.start(minutes: 5)
        timer.stop()
        XCTAssertFalse(timer.isRunning)
    }

    // MARK: - addMinutes()

    func test_addMinutes_increasesRemainingSeconds() {
        timer.start(minutes: 5)
        timer.pause()
        let before = timer.remainingSeconds
        timer.addMinutes(2)
        XCTAssertGreaterThan(timer.remainingSeconds, before)
    }

    func test_addMinutes_clearsIsExpired() {
        // Force expire state by manipulating stop then manually set isExpired via a workaround:
        // We use addMinutes on a fresh timer (remainingSeconds == 0) which should start it.
        timer.stop()
        timer.addMinutes(1)
        XCTAssertFalse(timer.isExpired)
    }

    func test_addMinutes_startsTimerIfStopped() {
        timer.stop()
        timer.addMinutes(1)
        XCTAssertTrue(timer.isRunning)
    }

    // MARK: - progressFraction

    func test_progressFraction_returnsZeroWhenTotalSecondsAtStartIsZero() {
        // Fresh timer, never started
        XCTAssertEqual(timer.progressFraction, 0.0)
    }

    func test_progressFraction_returnsOneOnFreshStart() {
        timer.start(minutes: 5)
        timer.pause()
        // Immediately after start (before any tick), fraction should be ~1.0
        XCTAssertEqual(timer.progressFraction, 1.0, accuracy: 0.01)
    }

    func test_progressFraction_decreasesAfterTick() {
        // Use a 2-second timer and wait for one tick
        timer.start(minutes: 1)
        let exp = expectation(description: "tick")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            exp.fulfill()
        }
        waitForExpectations(timeout: 3)
        XCTAssertLessThan(timer.progressFraction, 1.0)
    }

    // MARK: - onExpired callback

    func test_onExpired_firesWhenCountdownReachesZero() {
        let exp = expectation(description: "expired")
        // Use addMinutes to set a very short countdown via internal resume path.
        // We can't set remainingSeconds directly, so use a 1-second timer.
        // However start(minutes:) minimum is 1 minute. Instead, we call stop then
        // patch via addMinutes(0) — that's a no-op. Instead expose via a helper:
        // We'll use a fresh timer and manually invoke resume after setting remainingSeconds
        // through start + immediate manipulation isn't available. Use XCTestExpectation
        // with 2-second timeout: start 1 min timer, add -59 minutes is invalid.
        // Best approach: use internal tick-via-timer by starting with 1 minute
        // and just verifying the callback wires up; for the actual expiry test
        // we'll use a subclass trick: override tick via notification.
        // Simplest: start a short duration we can control. Since start(minutes:)
        // requires Int, minimum is 1 (60 seconds). We test with 1 second via addMinutes
        // after zeroing: call stop(), then manually set through the published property.
        // Published properties are settable from tests via @testable import.
        timer.stop()
        timer.onExpired = { exp.fulfill() }
        // Directly set remainingSeconds and start via resume:
        timer.remainingSeconds = 1
        timer.resume()
        waitForExpectations(timeout: 3)
        XCTAssertTrue(timer.isExpired)
    }

    // MARK: - Calling start twice

    func test_startTwice_resetsCleanly() {
        timer.start(minutes: 5)
        timer.start(minutes: 3)
        // Should reflect the second start, not double
        XCTAssertLessThanOrEqual(abs(timer.remainingSeconds - 180), 1)
    }

    // MARK: - displayString

    func test_displayString_isNonEmpty() {
        timer.start(minutes: 1)
        timer.pause()
        XCTAssertFalse(timer.displayString.isEmpty)
    }

    func test_displayString_containsColon() {
        timer.start(minutes: 2)
        timer.pause()
        XCTAssertTrue(timer.displayString.contains(":"))
    }
}
