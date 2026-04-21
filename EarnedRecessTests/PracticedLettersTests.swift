import XCTest
import CoreData
@testable import EarnedRecess

// MARK: - Helpers replicating the fetch logic from ChildHomeView / TaskGateView

private func fetchPracticedLettersToday(child: ChildProfile, in context: NSManagedObjectContext) -> Set<String> {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let request: NSFetchRequest<LetterSession> = LetterSession.fetchRequest()
    request.predicate = NSPredicate(
        format: "child == %@ AND sessionDate >= %@",
        child, startOfDay as NSDate
    )
    let sessions = (try? context.fetch(request)) ?? []
    return Set(sessions.compactMap { $0.letter }.filter { !$0.isEmpty })
}

private func allLettersPracticed(activeLetters: [String], practiced: Set<String>) -> Bool {
    guard !activeLetters.isEmpty else { return true }
    return Set(activeLetters).isSubset(of: practiced)
}

private func nextLetterToPractice(activeLetters: [String], practicedToday: Set<String>) -> String? {
    let unpracticed = activeLetters.filter { !practicedToday.contains($0) }
    return unpracticed.first
}

// MARK: - Tests

final class PracticedLettersTests: XCTestCase {

    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var child: ChildProfile!

    override func setUp() {
        super.setUp()
        container = makeInMemoryContainer()
        context = container.viewContext
        child = makeChild(in: context)
        try? context.save()
    }

    override func tearDown() {
        child = nil
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Practiced set computation

    func test_practicedSet_equalsSessionLetters() {
        for letter in ["A", "B", "C"] {
            makeLetterSession(letter: letter, passed: true, averageScore: 0.8, child: child, in: context)
        }
        try? context.save()
        let practiced = fetchPracticedLettersToday(child: child, in: context)
        XCTAssertEqual(practiced, ["A", "B", "C"])
    }

    func test_practicedSet_excludesNilLetter() {
        let session = LetterSession(context: context)
        session.id = UUID()
        session.letter = nil
        session.sessionDate = Date()
        session.phase = 1
        session.attemptsRequired = 1
        session.attemptsCompleted = 1
        session.passed = true
        session.averageScore = 0.8
        session.child = child
        try? context.save()

        let practiced = fetchPracticedLettersToday(child: child, in: context)
        XCTAssertFalse(practiced.contains(""))
        XCTAssertTrue(practiced.isEmpty)
    }

    func test_practicedSet_excludesEmptyStringLetter() {
        // Regression: letter == "" should not be counted as practiced
        makeLetterSession(letter: "", passed: true, averageScore: 0.8, child: child, in: context)
        try? context.save()

        let practiced = fetchPracticedLettersToday(child: child, in: context)
        XCTAssertFalse(practiced.contains(""))
        XCTAssertTrue(practiced.isEmpty)
    }

    // MARK: - allLettersPracticed logic

    func test_allLettersPracticed_trueWhenAllPracticed() {
        let active = ["A", "B", "C"]
        let practiced: Set<String> = ["A", "B", "C"]
        XCTAssertTrue(allLettersPracticed(activeLetters: active, practiced: practiced))
    }

    func test_allLettersPracticed_falseWhenOneLetterMissing() {
        let active = ["A", "B", "C"]
        let practiced: Set<String> = ["A", "B"]
        XCTAssertFalse(allLettersPracticed(activeLetters: active, practiced: practiced))
    }

    func test_allLettersPracticed_trueWhenActiveLettersEmpty() {
        XCTAssertTrue(allLettersPracticed(activeLetters: [], practiced: []))
    }

    // MARK: - nextLetterToPractice logic

    func test_nextLetter_isFirstAlphabeticallyWhenNoSessions() {
        let active = ["A", "B"]
        // activeLetterArray is stored alphabetically via settings; we simulate that order here
        let practiced: Set<String> = []
        let next = nextLetterToPractice(activeLetters: active, practicedToday: practiced)
        XCTAssertEqual(next, "A")
    }

    func test_nextLetter_isBWhenOnlyAHasSession() {
        makeLetterSession(letter: "A", passed: true, averageScore: 0.8, child: child, in: context)
        try? context.save()

        let active = ["A", "B"]
        let practiced = fetchPracticedLettersToday(child: child, in: context)
        let next = nextLetterToPractice(activeLetters: active, practicedToday: practiced)
        XCTAssertEqual(next, "B")
    }

    func test_nextLetter_nilLetterSessionDoesNotCountAsPracticed() {
        // A session with letter == nil should not mark any letter as practiced
        let session = LetterSession(context: context)
        session.id = UUID()
        session.letter = nil
        session.sessionDate = Date()
        session.phase = 1
        session.attemptsRequired = 1
        session.attemptsCompleted = 1
        session.passed = true
        session.averageScore = 0.8
        session.child = child
        try? context.save()

        let active = ["A", "B"]
        let practiced = fetchPracticedLettersToday(child: child, in: context)
        let next = nextLetterToPractice(activeLetters: active, practicedToday: practiced)
        XCTAssertEqual(next, "A", "nil-letter session should not count as practicing A")
    }

    func test_nextLetter_emptyStringLetterDoesNotCountAsPracticed() {
        // Regression: letter == "" should not satisfy the "A" requirement
        makeLetterSession(letter: "", passed: true, averageScore: 0.8, child: child, in: context)
        try? context.save()

        let active = ["A", "B"]
        let practiced = fetchPracticedLettersToday(child: child, in: context)
        let next = nextLetterToPractice(activeLetters: active, practicedToday: practiced)
        XCTAssertEqual(next, "A", "empty-string letter session should not count as practicing A")
    }
}
