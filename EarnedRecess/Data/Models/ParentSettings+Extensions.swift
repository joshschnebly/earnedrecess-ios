import CoreData
import Foundation

@objc(ParentSettings)
public class ParentSettings: NSManagedObject {}

extension ParentSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ParentSettings> {
        NSFetchRequest<ParentSettings>(entityName: "ParentSettings")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var timerDurationMinutes: Int32
    @NSManaged public var attemptsPerSession: Int16
    @NSManaged public var passingThreshold: Double
    @NSManaged public var progressionThreshold: Double
    @NSManaged public var autoProgressionEnabled: Bool
    @NSManaged public var qualityMultiplierEnabled: Bool
    @NSManaged public var requireAllLetters: Bool
    @NSManaged public var letterCase: String
    @NSManaged public var templateStyle: String
    @NSManaged public var showAlignmentLines: Bool
    @NSManaged public var activeLetters: String
    @NSManaged public var maxDailyMinutes: Int32
    @NSManaged public var bedtimeHour: Int32
    @NSManaged public var allowSearch: Bool
    @NSManaged public var writeToWatchThreshold: Double
    @NSManaged public var youtubeChannelWhitelist: String?
    @NSManaged public var appMode: String
    @NSManaged public var tracingArrowsEnabled: Bool
    @NSManaged public var tracingArrowsContinuous: Bool
    @NSManaged public var tracingArrowsSequential: Bool
    @NSManaged public var letterSoundsEnabled: Bool
    @NSManaged public var wordAssociationEnabled: Bool
    @NSManaged public var autoCalibrationEnabled: Bool
    @NSManaged public var calibrationWindow: Int32
}

extension ParentSettings {
    static func createDefaults(context: NSManagedObjectContext) -> ParentSettings {
        let settings = ParentSettings(context: context)
        settings.id = UUID()
        settings.timerDurationMinutes = Int32(Constants.App.defaultStarMinutesPerSession)
        settings.attemptsPerSession = 10
        settings.passingThreshold = Constants.App.defaultPassingThreshold
        settings.progressionThreshold = Constants.App.defaultProgressionThreshold
        settings.autoProgressionEnabled = true
        settings.qualityMultiplierEnabled = false
        settings.requireAllLetters = false
        settings.letterCase = "uppercase"
        settings.templateStyle = "solid"
        settings.showAlignmentLines = false
        settings.activeLetters = "A"
        settings.maxDailyMinutes = Int32(Constants.App.defaultMaxDailyMinutes)
        settings.bedtimeHour = Int32(Constants.App.defaultBedtimeHour)
        settings.allowSearch = false
        settings.writeToWatchThreshold = 0.50
        settings.youtubeChannelWhitelist = Constants.YouTube.featuredChannelIds.joined(separator: ",")
        settings.appMode = "standard"
        settings.tracingArrowsEnabled = false
        settings.tracingArrowsContinuous = true
        settings.tracingArrowsSequential = false
        settings.letterSoundsEnabled = true
        settings.wordAssociationEnabled = true
        settings.autoCalibrationEnabled = true
        settings.calibrationWindow = 10
        try? context.save()
        return settings
    }

    var activeLetterArray: [String] {
        get { activeLetters.components(separatedBy: ",").filter { !$0.isEmpty } }
        set { activeLetters = newValue.joined(separator: ",") }
    }

    var channelWhitelistArray: [String] {
        get { (youtubeChannelWhitelist ?? "").components(separatedBy: ",").filter { !$0.isEmpty } }
        set { youtubeChannelWhitelist = newValue.joined(separator: ",") }
    }

    var isBedtime: Bool {
        Date().hour >= Int(bedtimeHour)
    }
}

extension ParentSettings: Identifiable {}
