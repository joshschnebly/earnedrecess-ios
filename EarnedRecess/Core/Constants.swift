import Foundation

enum Constants {
    enum App {
        static let bundleId = "com.earnedrecess.app"
        static let defaultAttemptsPerSession = 10
        static let defaultStarMinutesPerSession = 20
        static let defaultPassingThreshold: Double = 0.60
        static let defaultProgressionThreshold: Double = 0.85
        static let defaultMaxDailyMinutes = 120
        static let defaultBedtimeHour = 20  // 8 PM
        static let pinLockoutSeconds = 30
        static let maxPinAttempts = 3
    }

    enum YouTube {
        static let safeSearchLevel = "strict"
        static let defaultVideoCategoryId = "1"
        static let defaultMaxResults = 20

        static let defaultChannels: [StoredChannel] = [
            StoredChannel(id: "UCAOtE1V7Ots4DjM8JLlrYgg", name: "Peppa Pig",        icon: "🐷"),
            StoredChannel(id: "UCF2M_-q5oKF8cHk1KWo9gkA", name: "Paw Patrol",        icon: "🐾"),
            StoredChannel(id: "UCKeKanAZfSYH0nzP3UGd_hQ", name: "JunyTony",          icon: "🎨"),
            StoredChannel(id: "UCVNm0g-f5xH7Nym_KpD_9BA", name: "Pit & Penny",       icon: "🐶"),
            StoredChannel(id: "UCXIvAXVdbUDzIFhVwB9RR-g", name: "Sheriff Labrador",  icon: "🚔"),
            StoredChannel(id: "UCDeGOkuOcGFsT3qcKdm4a9A", name: "Disney Junior",      icon: "🏰"),
        ]
    }

    enum Keychain {
        static let pinKey = "com.earnedrecess.parentpin"
        static let pinHashKey = "com.earnedrecess.parentpinhash"
    }

    enum UserDefaultsKeys {
        static let hasCompletedSetup = "hasCompletedSetup"
        static let pinAttempts = "pinAttempts"
        static let pinLockoutUntil = "pinLockoutUntil"
    }

    enum Scoring {
        static let overlapWeight: Double = 0.35
        static let proportionWeight: Double = 0.18
        static let strokeCountWeight: Double = 0.18
        static let smoothnessWeight: Double = 0.14
        static let keyPointsWeight: Double = 0.15
        static let strokePenaltyPerExtra: Double = 0.33
        static let keyPointToleranceRadius: Double = 15
    }
}
