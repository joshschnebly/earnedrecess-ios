import XCTest
import CoreData
@testable import EarnedRecess

final class CalibrationServiceTests: XCTestCase {

    private var container: NSPersistentContainer!
    private var ctx: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        container = makeInMemoryContainer()
        ctx = container.viewContext
    }

    override func tearDown() {
        ctx = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Seeds `count` LetterSessions for the given child and saves.
    private func seedSessions(
        count: Int,
        passed: Bool,
        averageScore: Double,
        child: ChildProfile
    ) {
        for _ in 0..<count {
            makeLetterSession(letter: "A", passed: passed,
                              averageScore: averageScore,
                              child: child, in: ctx)
        }
        try? ctx.save()
    }

    // MARK: - Minimum Session Requirement

    func testReturnsNilWhenFewerThan5Sessions() {
        // Arrange: only 4 sessions — below the minimum threshold.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10

        seedSessions(count: 4, passed: true, averageScore: 0.90, child: child)

        // Act
        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        // Assert
        XCTAssertNil(suggestion,
                     "CalibrationService should return nil when fewer than 5 sessions exist")
    }

    func testReturnsNonNilWhenExactly5Sessions() {
        // Edge case: exactly 5 sessions should trigger analysis.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10

        seedSessions(count: 5, passed: true, averageScore: 0.90, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)
        XCTAssertNotNil(suggestion)
    }

    // MARK: - Too Easy

    func testSuggestsTooEasyWhenPassRateHigh() {
        // passRate > 0.90 and avgScore > 0.85 → .tooEasy
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10
        settings.passingThreshold = 0.60   // current threshold

        // 10/10 sessions passing, all with high scores.
        seedSessions(count: 10, passed: true, averageScore: 0.92, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.type, .tooEasy)
        // Suggested threshold should be current + 0.05.
        XCTAssertEqual(suggestion?.suggestedPassingThreshold, 0.65, accuracy: 0.001)
    }

    func testTooEasySuggestedThresholdCapsAt100Percent() {
        // If already at 1.0, suggest should not exceed 1.0.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10
        settings.passingThreshold = 1.0

        seedSessions(count: 10, passed: true, averageScore: 0.92, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        XCTAssertEqual(suggestion?.type, .tooEasy)
        XCTAssertEqual(suggestion?.suggestedPassingThreshold ?? 0, 1.0, accuracy: 0.001)
    }

    // MARK: - Too Hard

    func testSuggestsTooHardWhenPassRateLow() {
        // passRate < 0.40 → .tooHard regardless of avgScore.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10
        settings.passingThreshold = 0.75

        // 3 passing, 7 failing → passRate 0.30, avgScore 0.50
        seedSessions(count: 3, passed: true, averageScore: 0.70, child: child)
        seedSessions(count: 7, passed: false, averageScore: 0.35, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.type, .tooHard)
    }

    func testSuggestsTooHardWhenAvgScoreLow() {
        // avgScore < 0.45 also triggers tooHard even if pass rate is slightly above 0.40.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10
        settings.passingThreshold = 0.70

        // 5 passing (barely), 5 failing — passRate 0.50 (above 0.40 cutoff),
        // but avgScore of 0.40 is below 0.45.
        seedSessions(count: 5, passed: true, averageScore: 0.40, child: child)
        seedSessions(count: 5, passed: false, averageScore: 0.40, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.type, .tooHard)
    }

    // MARK: - On Track

    func testReturnsNilWhenOnTrack() {
        // Mixed results in the normal range: passRate ~0.60, avgScore ~0.65.
        // Neither too easy nor too hard.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10
        settings.passingThreshold = 0.60

        seedSessions(count: 6, passed: true, averageScore: 0.70, child: child)
        seedSessions(count: 4, passed: false, averageScore: 0.55, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        // On-track returns a non-nil suggestion with type .onTrack.
        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.type, .onTrack)
        // On-track suggestions carry no threshold recommendations.
        XCTAssertNil(suggestion?.suggestedPassingThreshold)
        XCTAssertNil(suggestion?.suggestedProgressionThreshold)
    }

    // MARK: - Threshold Clamp

    func testSuggestedThresholdClampedTo40Percent() {
        // Even when a decrease is warranted, the suggested threshold must never
        // go below 0.40 (the floor defined in CalibrationService).
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10
        // Current threshold is already at the floor.
        settings.passingThreshold = 0.40

        // All failing, low average → should trigger tooHard.
        seedSessions(count: 10, passed: false, averageScore: 0.20, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.type, .tooHard)
        XCTAssertEqual(suggestion?.suggestedPassingThreshold ?? 0, 0.40, accuracy: 0.001,
                       "Suggested threshold must never drop below 0.40")
    }

    func testSuggestedThresholdDropsByFivePercent() {
        // When not at the floor, the suggestion should drop by exactly 0.05.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.calibrationWindow = 10
        settings.passingThreshold = 0.70

        seedSessions(count: 10, passed: false, averageScore: 0.20, child: child)

        let suggestion = CalibrationService.shared.analyze(child: child,
                                                            settings: settings,
                                                            context: ctx)

        XCTAssertEqual(suggestion?.suggestedPassingThreshold ?? 0, 0.65, accuracy: 0.001)
    }
}
