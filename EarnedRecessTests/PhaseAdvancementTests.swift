import XCTest
import CoreData
@testable import EarnedRecess

final class PhaseAdvancementTests: XCTestCase {

    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    let engine = ProgressionEngine()

    override func setUp() {
        super.setUp()
        container = makeInMemoryContainer()
        context = container.viewContext
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - shouldAdvancePhase

    func test_shouldAdvancePhase_returnsTrueWhenAvgMeetsThreshold() {
        let scores = Array(repeating: 0.90, count: 10)
        XCTAssertTrue(engine.shouldAdvancePhase(letter: "A", recentScores: scores, threshold: 0.85))
    }

    func test_shouldAdvancePhase_returnsFalseWithFewerThan5Scores() {
        let scores = Array(repeating: 0.95, count: 4)
        XCTAssertFalse(engine.shouldAdvancePhase(letter: "A", recentScores: scores, threshold: 0.85))
    }

    func test_shouldAdvancePhase_returnsFalseWhenAvgBelowThreshold() {
        let scores = Array(repeating: 0.50, count: 10)
        XCTAssertFalse(engine.shouldAdvancePhase(letter: "A", recentScores: scores, threshold: 0.85))
    }

    func test_shouldAdvancePhase_returnsFalseWhenJustBelowThreshold() {
        // All scores at exactly threshold - 0.001
        let scores = Array(repeating: 0.84999, count: 10)
        XCTAssertFalse(engine.shouldAdvancePhase(letter: "A", recentScores: scores, threshold: 0.85))
    }

    // MARK: - nextPhase

    func test_nextPhase_advancesFrom1To2() {
        XCTAssertEqual(engine.nextPhase(current: 1), 2)
    }

    func test_nextPhase_advancesFrom2To3() {
        XCTAssertEqual(engine.nextPhase(current: 2), 3)
    }

    func test_nextPhase_capsAt3() {
        XCTAssertEqual(engine.nextPhase(current: 3), 3)
    }

    // MARK: - Integration: finaliseSession advances phase after 10 passing sessions

    func test_finaliseSession_advancesPhaseAfter10PassingSessions() {
        let child = makeChild(in: context)
        let settings = makeSettings(in: context)
        settings.autoProgressionEnabled = true
        settings.progressionThreshold = 0.85
        settings.passingThreshold = 0.60
        settings.activeLetters = "A"
        try? context.save()

        XCTAssertEqual(child.phase(for: "A"), 1, "should start at phase 1")

        // Add 10 high-scoring sessions directly so recentScores returns them
        for _ in 0..<10 {
            makeLetterSession(
                letter: "A",
                passed: true,
                averageScore: 0.92,
                child: child,
                in: context
            )
        }
        try? context.save()

        // finaliseSession also calls recentScores; provide one more score via it
        let highScore = DrawingScore(
            overlapScore: 0.92, proportionScore: 0.92,
            strokeCountScore: 0.92, smoothnessScore: 0.92,
            keyPointsScore: 0.92, compositeScore: 0.92
        )
        _ = ScoringService.shared.finaliseSession(
            letter: "A",
            phase: 1,
            scores: [highScore],
            inkDataItems: [nil],
            child: child,
            settings: settings,
            context: context
        )

        XCTAssertEqual(child.phase(for: "A"), 2, "phase should advance to 2 after 10 passing high-score sessions")
    }

    func test_finaliseSession_advancesPhaseForAIndependentlyFromB() {
        let child = makeChild(in: context)
        let settings = makeSettings(in: context)
        settings.autoProgressionEnabled = true
        settings.progressionThreshold = 0.85
        settings.passingThreshold = 0.60
        settings.activeLetters = "A,B"
        try? context.save()

        // 10 high-scoring sessions for "A" only
        for _ in 0..<10 {
            makeLetterSession(letter: "A", passed: true, averageScore: 0.92, child: child, in: context)
        }
        // 0 sessions for "B"
        try? context.save()

        let highScore = DrawingScore(
            overlapScore: 0.92, proportionScore: 0.92,
            strokeCountScore: 0.92, smoothnessScore: 0.92,
            keyPointsScore: 0.92, compositeScore: 0.92
        )
        _ = ScoringService.shared.finaliseSession(
            letter: "A", phase: 1, scores: [highScore], inkDataItems: [nil],
            child: child, settings: settings, context: context
        )

        XCTAssertEqual(child.phase(for: "A"), 2, "A should advance")
        XCTAssertEqual(child.phase(for: "B"), 1, "B should stay at phase 1")
    }
}
