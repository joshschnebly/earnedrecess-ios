import XCTest
import CoreData
@testable import EarnedRecess

final class ScoringServiceTests: XCTestCase {

    // MARK: - Composite Score Weights

    func testCompositeScoreWeightsSum() {
        // The five component weights must sum to exactly 1.0 so that a
        // perfect drawing cannot exceed a composite of 1.0.
        let sum = Constants.Scoring.overlapWeight
            + Constants.Scoring.proportionWeight
            + Constants.Scoring.strokeCountWeight
            + Constants.Scoring.smoothnessWeight
            + Constants.Scoring.keyPointsWeight

        XCTAssertEqual(sum, 1.0, accuracy: 0.0001,
                       "Scoring weights must sum to 1.0 — got \(sum)")
    }

    // MARK: - Passing Threshold Default

    func testPassingThresholdDefault() {
        // The canonical default passed threshold used throughout the app is 0.60.
        XCTAssertEqual(Constants.App.defaultPassingThreshold, 0.60, accuracy: 0.001)
    }

    // MARK: - DrawingScore passed flag

    func testDrawingScorePassedAtExactThreshold() {
        // A composite of exactly 0.60 should count as passing.
        let score = DrawingScore(overlapScore: 0.60, proportionScore: 0.60,
                                 strokeCountScore: 0.60, smoothnessScore: 0.60,
                                 keyPointsScore: 0.60, compositeScore: 0.60)
        XCTAssertTrue(score.passed)
    }

    func testDrawingScoreFailsBelowThreshold() {
        let score = DrawingScore(overlapScore: 0, proportionScore: 0,
                                 strokeCountScore: 0, smoothnessScore: 0,
                                 keyPointsScore: 0, compositeScore: 0.59)
        XCTAssertFalse(score.passed)
    }

    // MARK: - Daily Cap (via ScoringService.finaliseSession)

    func testStarMinutesCapAtMaxDaily() {
        // Arrange: child has already earned the full daily allowance today.
        let container = makeInMemoryContainer()
        let ctx = container.viewContext

        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.maxDailyMinutes = 120
        settings.passingThreshold = 0.60
        settings.qualityMultiplierEnabled = false
        settings.timerDurationMinutes = 20
        settings.autoProgressionEnabled = false

        // Seed existing session that has already used up the entire daily cap.
        let existing = makeLetterSession(letter: "A", passed: true,
                                         averageScore: 0.80,
                                         starMinutesEarned: 120,
                                         child: child, in: ctx)
        try? ctx.save()

        // Verify the seeded session registers via SessionRepository.
        let repo = SessionRepository(context: ctx)
        let todayBefore = repo.todayStarMinutesEarned(for: child)
        XCTAssertEqual(todayBefore, 120, "Pre-condition: 120 minutes already earned today")

        // Act: finalise another passing session.
        let passingScores = (0..<1).map { _ in
            DrawingScore(overlapScore: 0.80, proportionScore: 0.80,
                         strokeCountScore: 0.80, smoothnessScore: 0.80,
                         keyPointsScore: 0.80, compositeScore: 0.80)
        }
        let result = ScoringService.shared.finaliseSession(
            letter: "B", phase: 1,
            scores: passingScores,
            inkDataItems: [nil],
            child: child,
            settings: settings,
            context: ctx
        )

        // Assert: cap kicks in, no additional minutes awarded.
        XCTAssertEqual(result.starMinutesEarned, 0,
                       "Cap exceeded — session should earn 0 additional star minutes")
        _ = existing // suppress unused warning
    }

    func testBedtimeBlocksAward() {
        // StarMinutesService.award returns 0 when isBedtime is true.
        // We test this by configuring bedtimeHour to 0 (always bedtime).
        let container = makeInMemoryContainer()
        let ctx = container.viewContext

        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.bedtimeHour = 0   // hour 0 means midnight — always >= current hour during normal tests

        // The isBedtime property uses Date().hour >= bedtimeHour, so setting 0
        // means any hour of the day (0–23) qualifies as bedtime.
        let awarded = StarMinutesService.shared.award(
            minutes: 30,
            to: child,
            settings: settings,
            context: ctx
        )

        XCTAssertEqual(awarded, 0, "Award should be blocked during bedtime")
        XCTAssertEqual(child.starMinutesBalance, 0)
    }

    // MARK: - ProgressionEngine

    func testPhaseAdvancesWhenThresholdMet() {
        // 10 recent scores all at 0.90 — well above the 0.85 default threshold.
        let engine = ProgressionEngine()
        let scores = Array(repeating: 0.90, count: 10)
        XCTAssertTrue(engine.shouldAdvancePhase(letter: "A",
                                                recentScores: scores,
                                                threshold: 0.85))
    }

    func testPhaseDoesNotAdvanceWhenBelowThreshold() {
        let engine = ProgressionEngine()
        let scores = Array(repeating: 0.70, count: 10)
        XCTAssertFalse(engine.shouldAdvancePhase(letter: "A",
                                                  recentScores: scores,
                                                  threshold: 0.85))
    }

    func testPhaseDoesNotAdvanceWithFewerThan5Sessions() {
        // Guard: need at least 5 scores before any advancement is evaluated.
        let engine = ProgressionEngine()
        let scores = Array(repeating: 1.0, count: 4)
        XCTAssertFalse(engine.shouldAdvancePhase(letter: "A",
                                                  recentScores: scores,
                                                  threshold: 0.85))
    }

    func testPhaseCapAt3() {
        // nextPhase must never exceed DrawingPhase.freehand.rawValue (3).
        let engine = ProgressionEngine()
        XCTAssertEqual(engine.nextPhase(current: 3), 3)
        XCTAssertEqual(engine.nextPhase(current: 2), 3)
        XCTAssertEqual(engine.nextPhase(current: 1), 2)
    }

    // MARK: - Star Minutes Award Calculation

    func testStarMinutesBaseWithoutMultiplier() {
        let engine = ProgressionEngine()
        let result = engine.starMinutesAwarded(averageScore: 0.95,
                                               baseDuration: 20,
                                               qualityMultiplierEnabled: false)
        XCTAssertEqual(result, 20, "Without quality multiplier, award equals base duration")
    }

    func testStarMinutesHighScoreMultiplier() {
        let engine = ProgressionEngine()
        // Score >= 0.90 → 1.5x multiplier
        let result = engine.starMinutesAwarded(averageScore: 0.90,
                                               baseDuration: 20,
                                               qualityMultiplierEnabled: true)
        XCTAssertEqual(result, 30, "Score 0.90 should grant 1.5x = 30 minutes")
    }

    func testStarMinutesMidScoreMultiplier() {
        let engine = ProgressionEngine()
        // Score 0.75–0.89 → 1.25x
        let result = engine.starMinutesAwarded(averageScore: 0.80,
                                               baseDuration: 20,
                                               qualityMultiplierEnabled: true)
        XCTAssertEqual(result, 25, "Score 0.80 should grant 1.25x = 25 minutes")
    }

    func testStarMinutesBaseScoreMultiplier() {
        let engine = ProgressionEngine()
        // Score < 0.75 → 1.0x
        let result = engine.starMinutesAwarded(averageScore: 0.65,
                                               baseDuration: 20,
                                               qualityMultiplierEnabled: true)
        XCTAssertEqual(result, 20, "Score 0.65 should grant 1.0x = 20 minutes")
    }
}
