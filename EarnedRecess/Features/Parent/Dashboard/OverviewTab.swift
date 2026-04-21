import SwiftUI
import Charts

struct OverviewTab: View {
    let child: ChildProfile
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    private var sessionRepo: SessionRepository { SessionRepository(context: context) }
    private var letterRepo: LetterRepository { LetterRepository(context: context) }

    private var todayEarned: Int { sessionRepo.todayStarMinutesEarned(for: child) }
    private var todayWatched: Int { sessionRepo.todayMinutesWatched(for: child) }
    private var currentBalance: Int { Int(child.starMinutesBalance) }

    private var allSessions: [LetterSession] { letterRepo.allSessions(for: child) }
    private var todaySessions: [LetterSession] {
        allSessions.filter { $0.sessionDate?.isToday ?? false }
    }
    private var streak: Int { calculateStreak() }

    private var weekData: [DayData] { buildWeekData() }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stat cards row
                HStack(spacing: 12) {
                    StatCard(icon: "⭐", label: "Earned Today",
                             value: todayEarned.asStarMinutesLabel, color: .erYellow)
                    StatCard(icon: "📺", label: "Watched Today",
                             value: "\(todayWatched) min", color: .erBlue)
                    StatCard(icon: "🔥", label: "Day Streak",
                             value: "\(streak)", color: .erOrange)
                }
                .padding(.horizontal)

                // Balance card
                VStack(spacing: 8) {
                    HStack {
                        Text("Current Balance")
                            .font(Theme.Fonts.parentHeadline())
                        Spacer()
                        Text(currentBalance.asStarMinutesLabel)
                            .font(Theme.Fonts.parentHeadline())
                            .foregroundColor(.erGreen)
                    }
                    ProgressView(value: Double(min(currentBalance, Int(appState.parentSettings?.maxDailyMinutes ?? 120))), total: Double(appState.parentSettings?.maxDailyMinutes ?? 120))
                        .tint(.erGreen)
                }
                .padding()
                .background(Color.erCard)
                .cornerRadius(Theme.Sizing.cardCornerRadius)
                .cardShadow()
                .padding(.horizontal)

                // Weekly chart
                if !weekData.isEmpty {
                    weeklyChart
                        .padding(.horizontal)
                }

                // Today's sessions
                if !todaySessions.isEmpty {
                    todaySessionsList
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.erBackground)
    }

    // MARK: - Weekly chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(Theme.Fonts.parentHeadline())

            Chart(weekData) { day in
                BarMark(x: .value("Day", day.label),
                        y: .value("Earned", day.earned))
                    .foregroundStyle(Color.erYellow)
                    .annotation(position: .top) {
                        if day.earned > 0 {
                            Text("\(day.earned)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                BarMark(x: .value("Day", day.label),
                        y: .value("Watched", -day.watched))
                    .foregroundStyle(Color.erBlue.opacity(0.6))
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }

            HStack(spacing: 16) {
                Legend(color: .erYellow, label: "Earned")
                Legend(color: .erBlue.opacity(0.6), label: "Watched")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.erCard)
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .cardShadow()
    }

    // MARK: - Today sessions list

    private var todaySessionsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Sessions")
                .font(Theme.Fonts.parentHeadline())

            ForEach(todaySessions, id: \.id) { session in
                HStack {
                    Text(session.letter ?? "?")
                        .font(Theme.Fonts.childBody(22))
                        .frame(width: 36, height: 36)
                        .background(session.passed ? Color.erGreen.opacity(0.15) : Color.erRed.opacity(0.1))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.passed ? "Passed" : "Not passed")
                            .font(Theme.Fonts.parentBody())
                        Text("Avg: \(Int((session.averageScore) * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if session.passed {
                        Text("+\(session.starMinutesEarned) ⭐")
                            .font(Theme.Fonts.parentBody())
                            .foregroundColor(.erGreen)
                    }
                }
                .padding(10)
                .background(Color.erCard)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.erCard)
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .cardShadow()
    }

    // MARK: - Helpers

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        while true {
            let dayStart = calendar.startOfDay(for: checkDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let hasPractice = allSessions.contains {
                guard let date = $0.sessionDate else { return false }
                return date >= dayStart && date < dayEnd && $0.passed
            }
            if hasPractice {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private func buildWeekData() -> [DayData] {
        let calendar = Calendar.current
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return (0..<7).reversed().map { offset -> DayData in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let weekday = calendar.component(.weekday, from: date)
            let label = days[((weekday + 5) % 7)]

            let earned = allSessions
                .filter { s in
                    guard let d = s.sessionDate else { return false }
                    return d >= dayStart && d < dayEnd && s.passed
                }
                .reduce(0) { $0 + Int($1.starMinutesEarned) }

            let watched = sessionRepo.recentRewardSessions(for: child, limit: 100)
                .filter { s in s.startTime >= dayStart && s.startTime < dayEnd }
                .reduce(0) { $0 + Int($1.minutesWatched) }

            return DayData(label: label, earned: earned, watched: watched)
        }
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let label: String
    let earned: Int
    let watched: Int
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(icon).font(.system(size: 28))
            Text(value)
                .font(Theme.Fonts.parentHeadline(15))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.erCard)
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .cardShadow()
    }
}

struct Legend: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label).foregroundColor(.secondary)
        }
    }
}
