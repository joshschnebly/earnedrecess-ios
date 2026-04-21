import XCTest
import CoreData
@testable import EarnedRecess

final class ChildProfileTests: XCTestCase {

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

    // MARK: - Default Values

    func testCreateProfile() {
        // Arrange & Act
        let profile = makeChild(in: ctx, name: "Alice")

        // Assert: all defaults set by ChildProfile.create(_:context:)
        XCTAssertNotNil(profile.id, "Profile should be assigned a UUID")
        XCTAssertEqual(profile.name, "Alice")
        XCTAssertNotNil(profile.createdAt, "createdAt should be set on creation")
        XCTAssertEqual(profile.starMinutesBalance, 0)
        XCTAssertEqual(profile.totalStarMinutesEarned, 0)
        XCTAssertEqual(profile.totalStarMinutesSpent, 0)
    }

    func testPhaseDefaultsTo1() {
        // A letter never explicitly set should return phase 1.
        let profile = makeChild(in: ctx)

        XCTAssertEqual(profile.phase(for: "A"), 1,
                       "Unset letter phase must default to 1 (tracing)")
        XCTAssertEqual(profile.phase(for: "Z"), 1,
                       "Any unset letter must default to phase 1")
    }

    // MARK: - Phase Get / Set

    func testSetAndGetPhase() {
        let profile = makeChild(in: ctx)

        profile.setPhase(2, for: "A")

        XCTAssertEqual(profile.phase(for: "A"), 2)
    }

    func testSetPhaseForMultipleLettersIndependently() {
        let profile = makeChild(in: ctx)

        profile.setPhase(1, for: "A")
        profile.setPhase(2, for: "B")
        profile.setPhase(3, for: "C")

        XCTAssertEqual(profile.phase(for: "A"), 1)
        XCTAssertEqual(profile.phase(for: "B"), 2)
        XCTAssertEqual(profile.phase(for: "C"), 3)
    }

    func testSetPhaseOverwritesPreviousValue() {
        let profile = makeChild(in: ctx)

        profile.setPhase(1, for: "A")
        profile.setPhase(3, for: "A")

        XCTAssertEqual(profile.phase(for: "A"), 3,
                       "Setting a phase twice should overwrite the first value")
    }

    // MARK: - Persistence via JSON Encode/Decode

    func testPhasePerLetterPersists() throws {
        // Arrange: set phases, save, re-fetch from CoreData context.
        let profile = makeChild(in: ctx, name: "Bob")
        profile.setPhase(2, for: "A")
        profile.setPhase(3, for: "M")
        try ctx.save()

        // Act: simulate a fresh read by re-fetching the object.
        ctx.refresh(profile, mergeChanges: false)

        // Assert: data survived the encode/save/refresh cycle.
        XCTAssertEqual(profile.phase(for: "A"), 2,
                       "Phase for 'A' must survive CoreData save and re-fetch")
        XCTAssertEqual(profile.phase(for: "M"), 3,
                       "Phase for 'M' must survive CoreData save and re-fetch")
    }

    func testPhasePerLetterEmptyWhenNoDataSet() {
        let profile = makeChild(in: ctx)

        // phasePerLetterData is nil by default.
        XCTAssertNil(profile.phasePerLetterData)
        XCTAssertEqual(profile.phasePerLetter, [:],
                       "phasePerLetter should return empty dict when data is nil")
    }

    func testPhaseJSONRoundTrip() throws {
        // Directly exercise the encode/decode path without CoreData.
        let profile = makeChild(in: ctx)
        profile.setPhase(2, for: "X")

        // Read the raw JSON back and decode it independently.
        let data = try XCTUnwrap(profile.phasePerLetterData,
                                 "phasePerLetterData should be non-nil after setPhase")
        let decoded = try JSONDecoder().decode([String: Int].self, from: data)

        XCTAssertEqual(decoded["X"], 2)
    }

    // MARK: - Balance Arithmetic

    func testBalanceIncrements() {
        let profile = makeChild(in: ctx)
        profile.starMinutesBalance += 10
        profile.starMinutesBalance += 5

        XCTAssertEqual(profile.starMinutesBalance, 15)
    }

    func testTotalEarnedAccumulates() {
        let profile = makeChild(in: ctx)
        profile.totalStarMinutesEarned += 20
        profile.totalStarMinutesEarned += 15

        XCTAssertEqual(profile.totalStarMinutesEarned, 35)
    }

    // MARK: - Multiple Profiles Isolation

    func testMultipleProfilesHaveIndependentPhases() {
        let alice = makeChild(in: ctx, name: "Alice")
        let bob   = makeChild(in: ctx, name: "Bob")

        alice.setPhase(3, for: "A")
        bob.setPhase(1, for: "A")

        XCTAssertEqual(alice.phase(for: "A"), 3,
                       "Alice's phase should be unaffected by Bob's phase")
        XCTAssertEqual(bob.phase(for: "A"), 1,
                       "Bob's phase should be unaffected by Alice's phase")
    }
}
