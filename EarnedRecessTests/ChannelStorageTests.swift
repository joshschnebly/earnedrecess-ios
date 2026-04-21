import XCTest
import CoreData
@testable import EarnedRecess

// MARK: - ChannelStorageTests
//
// Tests for ParentSettings.channelArray JSON round-trip behaviour using an
// in-memory CoreData store. Each test gets its own container + settings object
// so there is no shared state between tests.

final class ChannelStorageTests: XCTestCase {

    // Fresh container + context + settings for every test.
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    var settings: ParentSettings!

    override func setUp() {
        super.setUp()
        container = makeInMemoryContainer()
        context = container.viewContext
        settings = makeSettings(in: context)
    }

    override func tearDown() {
        settings = nil
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeChannel(
        id: String = "UCXIvAXVdbUDzIFhVwB9RR-g",
        name: String = "Sheriff Labrador",
        icon: String = "🚔",
        thumbnailURL: String? = nil
    ) -> StoredChannel {
        StoredChannel(id: id, name: name, icon: icon, thumbnailURL: thumbnailURL)
    }

    // MARK: - 1. Default channels when whitelist is nil

    func testDefaultChannelsReturnedWhenFieldIsNil() {
        // createDefaults sets channelArray = defaultChannels, so clear it manually.
        settings.youtubeChannelWhitelist = nil

        XCTAssertEqual(
            settings.channelArray,
            Constants.YouTube.defaultChannels,
            "Should fall back to defaultChannels when youtubeChannelWhitelist is nil"
        )
    }

    // MARK: - 2. Basic encode → decode round-trip

    func testRoundTripEncodeDecodePreservesChannels() {
        let channels = [
            makeChannel(id: "UCXIvAXVdbUDzIFhVwB9RR-g", name: "Sheriff Labrador", icon: "🚔"),
            makeChannel(id: "UCAOtE1V7Ots4DjM8JLlrYgg", name: "Peppa Pig",        icon: "🐷"),
        ]
        settings.channelArray = channels

        XCTAssertEqual(settings.channelArray, channels, "Round-trip should preserve all channels")
    }

    // MARK: - 3. All fields preserved

    func testRoundTripPreservesAllFields() {
        let channel = StoredChannel(
            id: "UCXIvAXVdbUDzIFhVwB9RR-g",
            name: "Sheriff Labrador",
            icon: "🚔",
            thumbnailURL: "https://example.com/thumb.jpg"
        )
        settings.channelArray = [channel]

        let decoded = settings.channelArray.first
        XCTAssertEqual(decoded?.id,           channel.id)
        XCTAssertEqual(decoded?.name,         channel.name)
        XCTAssertEqual(decoded?.icon,         channel.icon)
        XCTAssertEqual(decoded?.thumbnailURL, channel.thumbnailURL)
    }

    // MARK: - 4. nil thumbnailURL survives round-trip

    func testRoundTripWithNilThumbnail() {
        let channel = makeChannel(thumbnailURL: nil)
        settings.channelArray = [channel]

        let decoded = settings.channelArray.first
        XCTAssertNotNil(decoded, "Channel should decode successfully with nil thumbnailURL")
        XCTAssertNil(decoded?.thumbnailURL, "thumbnailURL should still be nil after round-trip")
    }

    // MARK: - 5. Corrupt JSON falls back to defaults

    func testCorruptJSONFallsBackToDefaults() {
        settings.youtubeChannelWhitelist = "not valid json }{{"

        XCTAssertEqual(
            settings.channelArray,
            Constants.YouTube.defaultChannels,
            "Should fall back to defaultChannels when stored JSON is corrupt"
        )
    }

    // MARK: - 6. Empty array round-trips

    func testEmptyArrayRoundTrips() {
        settings.channelArray = []

        XCTAssertEqual(settings.channelArray, [], "Empty channel array should round-trip to empty array")
    }

    // MARK: - 7. Appending a channel persists

    func testAppendChannelPersists() {
        let newChannel = makeChannel(
            id: "UCNewTestChannelId1234567",
            name: "Test Channel",
            icon: "🎬"
        )
        var channels = settings.channelArray
        channels.append(newChannel)
        settings.channelArray = channels

        XCTAssertEqual(
            settings.channelArray.count,
            Constants.YouTube.defaultChannels.count + 1,
            "Channel count should be defaultChannels.count + 1 after append"
        )
        XCTAssertTrue(
            settings.channelArray.contains(newChannel),
            "Appended channel should be present after round-trip"
        )
    }

    // MARK: - 8. Removing a channel persists

    func testRemoveChannelPersists() {
        // Start from known state: two explicit channels.
        let ch1 = makeChannel(id: "UCXIvAXVdbUDzIFhVwB9RR-g", name: "Sheriff Labrador", icon: "🚔")
        let ch2 = makeChannel(id: "UCAOtE1V7Ots4DjM8JLlrYgg", name: "Peppa Pig",        icon: "🐷")
        settings.channelArray = [ch1, ch2]

        // Remove ch1 by ID.
        var channels = settings.channelArray
        channels.removeAll { $0.id == ch1.id }
        settings.channelArray = channels

        let result = settings.channelArray
        XCTAssertEqual(result.count, 1, "Count should be 1 after removing one channel")
        XCTAssertFalse(result.contains(ch1), "Removed channel should not be present")
        XCTAssertTrue(result.contains(ch2),  "Remaining channel should still be present")
    }

    // MARK: - 9. channelWhitelistArray extracts only IDs in order

    func testChannelWhitelistArrayExtractsIds() {
        let channels = [
            makeChannel(id: "UCAAAAAAAAAAAAAAAAAAAAA1", name: "Alpha", icon: "A"),
            makeChannel(id: "UCAAAAAAAAAAAAAAAAAAAAA2", name: "Beta",  icon: "B"),
            makeChannel(id: "UCAAAAAAAAAAAAAAAAAAAAA3", name: "Gamma", icon: "G"),
        ]
        settings.channelArray = channels

        let ids = settings.channelWhitelistArray
        XCTAssertEqual(ids, ["UCAAAAAAAAAAAAAAAAAAAAA1",
                              "UCAAAAAAAAAAAAAAAAAAAAA2",
                              "UCAAAAAAAAAAAAAAAAAAAAA3"],
                       "channelWhitelistArray should return IDs in the same order as channelArray")
    }

    // MARK: - 10. Valid data is preserved on a normal set (encode-path sanity)

    func testValidDataIsPreservedAfterNormalSet() {
        let channel = makeChannel(id: "UCXIvAXVdbUDzIFhVwB9RR-g", name: "Sheriff Labrador", icon: "🚔")
        settings.channelArray = [channel]

        // A second set should not lose the first write.
        let currentChannels = settings.channelArray
        settings.channelArray = currentChannels

        XCTAssertEqual(settings.channelArray, [channel],
                       "Re-encoding a valid channel array should not lose data")
    }

    // MARK: - 11. Duplicate prevention logic

    func testDuplicateNotAddedByContainsWhere() {
        let existing = makeChannel(id: "UCXIvAXVdbUDzIFhVwB9RR-g", name: "Sheriff Labrador", icon: "🚔")
        settings.channelArray = [existing]

        // Simulate the guard that YouTubeSettingsSection uses before appending.
        var channels = settings.channelArray
        let duplicate = makeChannel(id: "UCXIvAXVdbUDzIFhVwB9RR-g", name: "Sheriff Labrador Duplicate", icon: "🚔")
        if !channels.contains(where: { $0.id == duplicate.id }) {
            channels.append(duplicate)
        }
        settings.channelArray = channels

        XCTAssertEqual(settings.channelArray.count, 1,
                       "Duplicate channel (same ID) should not be added when guard is applied")
        XCTAssertEqual(settings.channelArray.first?.name, existing.name,
                       "Original channel name should be unchanged")
    }
}
