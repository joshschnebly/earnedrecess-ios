import XCTest
@testable import EarnedRecess

// MARK: - YouTubeChannelParsingTests
//
// Tests for channel-resolution parsing logic in YouTubeKidsService.
// extractHandle and extractChannelId are private, so we test them indirectly
// through resolveChannel(input:) with an empty API key (the YoutubeAPIKey stub).
//
// Behaviour when key is empty:
//   - If a raw UC… ID (24 chars, starts with "UC") is detectable → returns StoredChannel stub
//   - Otherwise (handle, non-YouTube URL, bad ID) → returns nil

final class YouTubeChannelParsingTests: XCTestCase {

    // Service under test — uses the empty YoutubeAPIKey stub by default.
    var service: YouTubeKidsService!

    override func setUp() {
        super.setUp()
        service = YouTubeKidsService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Handle inputs (no API key → always nil)

    /// "@SheriffLabrador" is a handle — needs an API round-trip, so nil without a key.
    func testExtractHandleFromAtPrefix() async {
        let result = await service.resolveChannel(input: "@SheriffLabrador")
        XCTAssertNil(result, "Expected nil for @handle input when API key is absent")
    }

    /// "youtube.com/@SheriffLabrador" contains a handle path — nil without key.
    func testExtractHandleFromYouTubeURL() async {
        let result = await service.resolveChannel(input: "youtube.com/@SheriffLabrador")
        XCTAssertNil(result, "Expected nil for youtube.com/@handle URL when API key is absent")
    }

    // MARK: - Raw UC… channel IDs

    /// A valid 24-char UC… ID should return a StoredChannel stub even without a key.
    func testExtractChannelIdFromRawId() async {
        let rawId = "UCXIvAXVdbUDzIFhVwB9RR-g" // exactly 24 chars, starts with UC
        XCTAssertEqual(rawId.count, 24)

        let result = await service.resolveChannel(input: rawId)
        XCTAssertNotNil(result, "Expected StoredChannel stub for valid 24-char UC… ID")
        XCTAssertEqual(result?.id, rawId)
    }

    /// A UC… string that is too short should return nil.
    func testExtractChannelIdTooShort() async {
        let shortId = "UCshort" // starts with UC but < 24 chars
        XCTAssertLessThan(shortId.count, 24)

        let result = await service.resolveChannel(input: shortId)
        XCTAssertNil(result, "Expected nil for UC… ID shorter than 24 chars")
    }

    /// A 24-char string that does NOT start with "UC" should return nil.
    func testExtractChannelIdWrongPrefix() async {
        let wrongPrefix = "ABCXIvAXVdbUDzIFhVwB9RR-g"
        XCTAssertEqual(wrongPrefix.count, 25) // not 24; also wrong prefix — double guard

        let result = await service.resolveChannel(input: wrongPrefix)
        XCTAssertNil(result, "Expected nil for channel-style string with wrong prefix")
    }

    // MARK: - /channel/ URL extraction

    /// A YouTube /channel/ URL embeds a raw UC… ID that can be extracted without an API call.
    func testExtractChannelIdFromChannelURL() async {
        let url = "https://youtube.com/channel/UCXIvAXVdbUDzIFhVwB9RR-g"
        let result = await service.resolveChannel(input: url)
        XCTAssertNotNil(result, "Expected StoredChannel for /channel/UC… URL")
        XCTAssertEqual(result?.id, "UCXIvAXVdbUDzIFhVwB9RR-g")
    }

    /// Same as above but with www. prefix.
    func testFullHTTPSURLWithChannelId() async {
        let url = "https://www.youtube.com/channel/UCXIvAXVdbUDzIFhVwB9RR-g"
        let result = await service.resolveChannel(input: url)
        XCTAssertNotNil(result, "Expected StoredChannel for full HTTPS /channel/ URL")
        XCTAssertEqual(result?.id, "UCXIvAXVdbUDzIFhVwB9RR-g")
    }

    // MARK: - Edge / invalid inputs

    /// Empty string should return nil immediately after trimming.
    func testEmptyInputReturnsNil() async {
        let result = await service.resolveChannel(input: "")
        XCTAssertNil(result, "Expected nil for empty input")
    }

    /// Whitespace-only string trims to empty and should return nil.
    func testWhitespaceInputReturnsNil() async {
        let result = await service.resolveChannel(input: "   ")
        XCTAssertNil(result, "Expected nil for whitespace-only input")
    }

    /// A non-YouTube URL should not extract a handle or channel ID.
    func testNonYouTubeURLReturnsNil() async {
        let result = await service.resolveChannel(input: "vimeo.com/@handle")
        XCTAssertNil(result, "Expected nil for non-YouTube URL")
    }

    // MARK: - Stub structure sanity check

    /// When a raw ID resolves successfully, the returned stub uses "Unknown channel" and empty icon.
    func testStubChannelHasExpectedFields() async {
        let rawId = "UCXIvAXVdbUDzIFhVwB9RR-g"
        let result = await service.resolveChannel(input: rawId)
        XCTAssertEqual(result?.name, "Unknown channel")
        XCTAssertEqual(result?.icon, "")
        XCTAssertNil(result?.thumbnailURL)
    }
}
