import Foundation

extension Date {
    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .short; return f
    }()

    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; return f
    }()

    private static let shortWeekdayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()

    var shortDate: String {
        Date.shortDateFormatter.string(from: self)
    }

    var mediumDate: String {
        Date.mediumDateFormatter.string(from: self)
    }

    var timeString: String {
        Date.timeFormatter.string(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    var shortWeekday: String {
        Date.shortWeekdayFormatter.string(from: self)
    }
}

extension Int {
    // Converts seconds to "mm:ss" display string
    var asTimerString: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Converts minutes to friendly string e.g. "20 Star Minutes"
    var asStarMinutesLabel: String {
        self == 1 ? "1 Star Minute" : "\(self) Star Minutes"
    }
}
