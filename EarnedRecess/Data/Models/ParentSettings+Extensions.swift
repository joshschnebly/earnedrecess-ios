import CoreData
import Foundation

extension ParentSettings {
    static func fetchRequest() -> NSFetchRequest<ParentSettings> {
        NSFetchRequest<ParentSettings>(entityName: "ParentSettings")
    }

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
        settings.activeLetters = "A"
        settings.maxDailyMinutes = Int32(Constants.App.defaultMaxDailyMinutes)
        settings.bedtimeHour = Int32(Constants.App.defaultBedtimeHour)
        settings.allowSearch = false
        settings.youtubeChannelWhitelist = Constants.YouTube.featuredChannelIds.joined(separator: ",")
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
