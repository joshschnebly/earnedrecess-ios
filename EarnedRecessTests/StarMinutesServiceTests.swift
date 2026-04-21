import XCTest
import CoreData
@testable import EarnedRecess

final class StarMinutesServiceTests: XCTestCase {

    // Each test gets its own isolated container so there are no cross-test
    // CoreData interactions.
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

    // MARK: - Award

    func testAwardIncreasesBalance() {
        // Arrange
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.maxDailyMinutes = 120
        settings.bedtimeHour = 23   // not bedtime during any normal test run

        let initialBalance = child.starMinutesBalance

        // Act
        let awarded = StarMinutesService.shared.award(minutes: 15,
                                                      to: child,
                                                      settings: settings,
                                                      context: ctx)

        // Assert
        XCTAssertEqual(awarded, 15)
        XCTAssertEqual(child.starMinutesBalance, initialBalance + 15)
        XCTAssertEqual(child.totalStarMinutesEarned, Int32(15))
    }

    func testAwardAccumulatesTotalEarned() {
        // Award twice and verify totalStarMinutesEarned accumulates correctly.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.maxDailyMinutes = 120
        settings.bedtimeHour = 23

        StarMinutesService.shared.award(minutes: 10, to: child, settings: settings, context: ctx)
        StarMinutesService.shared.award(minutes: 5, to: child, settings: settings, context: ctx)

        XCTAssertEqual(child.totalStarMinutesEarned, 15)
    }

    // MARK: - Spend

    func testSpendDecreasesBalance() {
        // Arrange: give child a starting balance.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.maxDailyMinutes = 120
        settings.bedtimeHour = 23

        StarMinutesService.shared.award(minutes: 30, to: child, settings: settings, context: ctx)
        XCTAssertEqual(child.starMinutesBalance, 30, "Pre-condition: balance should be 30")

        // Act
        StarMinutesService.shared.spend(minutes: 10, from: child, context: ctx)

        // Assert
        XCTAssertEqual(child.starMinutesBalance, 20)
        XCTAssertEqual(child.totalStarMinutesSpent, 10)
    }

    func testSpendCannotGoBelowZero() {
        // Spending more than the available balance should clamp at 0.
        let child = makeChild(in: ctx)
        child.starMinutesBalance = 5

        StarMinutesService.shared.spend(minutes: 100, from: child, context: ctx)

        XCTAssertEqual(child.starMinutesBalance, 0,
                       "Balance must not go negative when spending more than available")
        XCTAssertEqual(child.totalStarMinutesSpent, 5,
                       "Only the available amount should have been recorded as spent")
    }

    func testSpendOneMinuteDecreasesBalanceByOne() {
        let child = makeChild(in: ctx)
        child.starMinutesBalance = 10

        let success = StarMinutesService.shared.spendOneMinute(from: child, context: ctx)

        XCTAssertTrue(success)
        XCTAssertEqual(child.starMinutesBalance, 9)
        XCTAssertEqual(child.totalStarMinutesSpent, 1)
    }

    func testSpendOneMinuteReturnsFalseWhenEmpty() {
        let child = makeChild(in: ctx)
        child.starMinutesBalance = 0

        let success = StarMinutesService.shared.spendOneMinute(from: child, context: ctx)

        XCTAssertFalse(success, "spendOneMinute should return false when balance is 0")
        XCTAssertEqual(child.starMinutesBalance, 0)
    }

    // MARK: - Daily Cap

    func testDailyCapEnforced() {
        // If today's earned total already meets maxDailyMinutes, award returns 0.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.maxDailyMinutes = 30
        settings.bedtimeHour = 23

        // First award fills the cap.
        let first = StarMinutesService.shared.award(minutes: 30, to: child,
                                                    settings: settings, context: ctx)
        XCTAssertEqual(first, 30, "First award should succeed fully")

        // Seed a LetterSession so SessionRepository.todayStarMinutesEarned returns 30.
        makeLetterSession(letter: "A", passed: true, averageScore: 0.80,
                          starMinutesEarned: 30, child: child, in: ctx)
        try? ctx.save()

        // Second award attempt should be blocked by the cap.
        let second = StarMinutesService.shared.award(minutes: 10, to: child,
                                                     settings: settings, context: ctx)
        XCTAssertEqual(second, 0,
                       "No additional minutes should be awarded once the daily cap is reached")
    }

    func testDailyCapAllowsPartialAward() {
        // If 25 out of 30 are already used, only 5 more should be awarded.
        let child = makeChild(in: ctx)
        let settings = makeSettings(in: ctx)
        settings.maxDailyMinutes = 30
        settings.bedtimeHour = 23

        // Seed 25 minutes already earned today.
        makeLetterSession(letter: "A", passed: true, averageScore: 0.80,
                          starMinutesEarned: 25, child: child, in: ctx)
        try? ctx.save()

        let awarded = StarMinutesService.shared.award(minutes: 20, to: child,
                                                      settings: settings, context: ctx)
        XCTAssertEqual(awarded, 5, "Should award only the remaining cap headroom")
    }

    // MARK: - Current Balance Query

    func testCurrentBalanceReflectsChildProperty() {
        let child = makeChild(in: ctx)
        child.starMinutesBalance = 42

        let balance = StarMinutesService.shared.currentBalance(for: child)

        XCTAssertEqual(balance, 42)
    }
}
