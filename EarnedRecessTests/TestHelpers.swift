import XCTest
import CoreData
@testable import EarnedRecess

// MARK: - In-Memory CoreData Container

func makeInMemoryContainer() -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "EarnedRecess")
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { _, error in
        XCTAssertNil(error, "In-memory store failed to load: \(error?.localizedDescription ?? "")")
    }
    return container
}

// MARK: - Entity Factories

func makeChild(in context: NSManagedObjectContext, name: String = "Test") -> ChildProfile {
    ChildProfile.create(name: name, context: context)
}

func makeSettings(in context: NSManagedObjectContext) -> ParentSettings {
    ParentSettings.createDefaults(context: context)
}

// MARK: - Session Factory

/// Creates and saves a LetterSession directly in the context (bypasses ScoringService).
@discardableResult
func makeLetterSession(
    letter: String = "A",
    passed: Bool,
    averageScore: Double,
    starMinutesEarned: Int32 = 0,
    child: ChildProfile,
    in context: NSManagedObjectContext
) -> LetterSession {
    let session = LetterSession(context: context)
    session.id = UUID()
    session.letter = letter
    session.phase = 1
    session.attemptsRequired = 1
    session.attemptsCompleted = 1
    session.sessionDate = Date()
    session.passed = passed
    session.averageScore = averageScore
    session.starMinutesEarned = starMinutesEarned
    session.duration = 0
    session.child = child
    return session
}
