import XCTest
@testable import EarnedRecess

final class AppEnumsTests: XCTestCase {

    // MARK: - AppMode Raw Values

    func testAppModeRawValues() {
        XCTAssertEqual(AppMode.standard.rawValue,      "standard")
        XCTAssertEqual(AppMode.writeToWatch.rawValue,  "writeToWatch")
        XCTAssertEqual(AppMode.both.rawValue,          "both")
    }

    func testAppModeFromRawString() {
        XCTAssertEqual(AppMode(rawValue: "standard"),     .standard)
        XCTAssertEqual(AppMode(rawValue: "writeToWatch"), .writeToWatch)
        XCTAssertEqual(AppMode(rawValue: "both"),         .both)
    }

    func testAppModeInvalidRawStringReturnsNil() {
        XCTAssertNil(AppMode(rawValue: "unknown"),   "Unrecognised raw value must return nil")
        XCTAssertNil(AppMode(rawValue: "Standard"),  "Raw values are case-sensitive")
        XCTAssertNil(AppMode(rawValue: ""),           "Empty string must return nil")
    }

    // MARK: - LetterCase Raw Values

    func testLetterCaseRawValues() {
        XCTAssertEqual(LetterCase.uppercase.rawValue, "uppercase")
        XCTAssertEqual(LetterCase.lowercase.rawValue, "lowercase")
        XCTAssertEqual(LetterCase.both.rawValue,      "both")
    }

    func testLetterCaseFromRawString() {
        XCTAssertEqual(LetterCase(rawValue: "uppercase"), .uppercase)
        XCTAssertEqual(LetterCase(rawValue: "lowercase"), .lowercase)
        XCTAssertEqual(LetterCase(rawValue: "both"),      .both)
    }

    func testLetterCaseInvalidRawStringReturnsNil() {
        XCTAssertNil(LetterCase(rawValue: "mixed"))
        XCTAssertNil(LetterCase(rawValue: "UPPERCASE"),
                     "LetterCase raw values must be lowercase — 'UPPERCASE' should not match")
    }

    // MARK: - TemplateStyle Raw Values

    func testTemplateStyleRawValues() {
        XCTAssertEqual(TemplateStyle.solid.rawValue,  "solid")
        XCTAssertEqual(TemplateStyle.dotted.rawValue, "dotted")
        XCTAssertEqual(TemplateStyle.none.rawValue,   "none")
    }

    func testTemplateStyleFromRawString() {
        XCTAssertEqual(TemplateStyle(rawValue: "solid"),  .solid)
        XCTAssertEqual(TemplateStyle(rawValue: "dotted"), .dotted)
        XCTAssertEqual(TemplateStyle(rawValue: "none"),   .none)
    }

    func testTemplateStyleInvalidRawStringReturnsNil() {
        XCTAssertNil(TemplateStyle(rawValue: "dashed"))
        XCTAssertNil(TemplateStyle(rawValue: "Solid"),
                     "TemplateStyle raw values are case-sensitive")
    }

    // MARK: - Cross-Enum Isolation

    func testInvalidRawStringReturnsNil() {
        // Shared catch-all for all three enums.
        XCTAssertNil(AppMode(rawValue: "dotted"),
                     "A TemplateStyle value should not match an AppMode")
        XCTAssertNil(LetterCase(rawValue: "standard"),
                     "An AppMode value should not match a LetterCase")
        XCTAssertNil(TemplateStyle(rawValue: "uppercase"),
                     "A LetterCase value should not match a TemplateStyle")
    }

    // MARK: - DrawingPhase Raw Values

    func testDrawingPhaseRawValues() {
        XCTAssertEqual(DrawingPhase.tracing.rawValue,  1)
        XCTAssertEqual(DrawingPhase.guided.rawValue,   2)
        XCTAssertEqual(DrawingPhase.freehand.rawValue, 3)
    }

    func testDrawingPhaseFromRawInt() {
        XCTAssertEqual(DrawingPhase(rawValue: 1), .tracing)
        XCTAssertEqual(DrawingPhase(rawValue: 2), .guided)
        XCTAssertEqual(DrawingPhase(rawValue: 3), .freehand)
        XCTAssertNil(DrawingPhase(rawValue: 0), "Phase 0 does not exist")
        XCTAssertNil(DrawingPhase(rawValue: 4), "Phase 4 is beyond freehand")
    }

    func testDrawingPhaseDisplayNames() {
        XCTAssertEqual(DrawingPhase.tracing.displayName,  "Tracing")
        XCTAssertEqual(DrawingPhase.guided.displayName,   "Guided")
        XCTAssertEqual(DrawingPhase.freehand.displayName, "Freehand")
    }
}
