import SwiftUI
import Charts

struct WatchTimeTab: View {
    let child: ChildProfile
    @Environment(\.managedObjectContext) var context

    private var sessionRepo: SessionRepository { SessionRepository(context: context) }

    private var rewardSessions: [RewardSession] {
        sessionRepo.recentRewardSessions(for: child, limit: 100)
    }

    private var todayWatched: Int {
        sessionRepo.todayMinutesWatched(for: child)
    }

    private var weekWatched: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return rewardSessions
            .filter { $0.startTime >= cutoff }
            .reduce(0) { $0 + Int($1.minutesWatched) }
    }

    private var allTimeWatched: Int {
        Int(child.totalStarMinutesSpent)
    }

    private var allTimeEarned: Int {
        Int(child.totalStarMinutesEarned)
    }

    private var weekChartData: [WatchDayData] { buildWeekData() }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                HStack(spacing: 12) {
                    StatCard(icon: "📺", label: "Today",
                             value: "\(todayWatched)m", color: .erBlue)
                    StatCard(icon: "📅", label: "This Week",
                             value: "\(weekWatched)m", color: .erPurple)
                    StatCard(icon: "🏆", label: "All Time",
                             value: "\(allTimeWatched)m", color: .erGreen)
                }
                .padding(.horizontal)

                // Earned vs spent chart
                earnedVsSpentChart
                    .padding(.horizontal)

                // Recent sessions list
                recentSessionsList
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.erBackground)
    }

    // MARK: - Charts

    private var earnedVsSpentChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earned vs Watched — This Week")
                .font(Theme.Fonts.parentHeadline())

            Chart(weekChartData) { day in
                BarMark(x: .value("Day", day.label),
                        y: .value("Earned", day.earned))
                    .foregroundStyle(Color.erYellow)
                    .position(by: .value("Type", "Earned"))

                BarMark(x: .value("Day", day.label),
                        y: .value("Watched", day.watched))
                    .foregroundStyle(Color.erBlue.opacity(0.7))
                    .position(by: .value("Type", "Watched"))
            }
            .frame(height: 160)
            .chartLegend(position: .bottom, alignment: .leading)

            HStack(spacing: 16) {
                Legend(color: .erYellow, label: "Earned")
                Legend(color: .erBlue.opacity(0.7), label: "Watched")
            }
            .font(.caption)
        }
        .padding()
        .background(Color.erCard)
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .cardShadow()
    }

    // MARK: - Recent sessions

    private var recentSessionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Watch Sessions")
                    .font(Theme.Fonts.parentHeadline())
                Spacer()
                Text("All time: \(allTimeEarned)m earned / \(allTimeWatched)m watched")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if rewardSessions.isEmpty {
                Text("No watch sessions yet.")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(rewardSessions.prefix(20), id: \.id) { session in
                    WatchSessionRow(session: session)
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.erCard)
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .cardShadow()
    }

    // MARK: - Helpers

    private func buildWeekData() -> [WatchDayData] {
        let calendar = Calendar.current
        let dayLabels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return (0..<7).reversed().map { offset -> WatchDayData in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let weekday = calendar.component(.weekday, from: date)
            let label = dayLabels[(weekday + 5) % 7]

            let watched = rewardSessions
                .filter { $0.startTime >= dayStart && $0.startTime < dayEnd }
                .reduce(0) { $0 + Int($1.minutesWatched) }

            let earned = rewardSessions
                .filter { $0.startTime >= dayStart && $0.startTime < dayEnd }
                .reduce(0) { $0 + Int($1.minutesEarned) }

            return WatchDayData(label: label, earned: earned, watched: watched)
        }
    }
}

// MARK: - Watch session row

struct WatchSessionRow: View {
    let session: RewardSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "play.tv.fill")
                .font(.system(size: 24))
                .foregroundColor(.erBlue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.videoTitle ?? "YouTube Kids")
                    .font(Theme.Fonts.parentBody())
                    .lineLimit(1)
                Text(session.startTime.shortDate + " · " + session.startTime.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(session.minutesWatched)m")
                .font(Theme.Fonts.parentBody())
                .foregroundColor(.erBlue)
        }
        .padding(.vertical, 4)
    }
}

struct WatchDayData: Identifiable {
    let id = UUID()
    let label: String
    let earned: Int
    let watched: Int
}
