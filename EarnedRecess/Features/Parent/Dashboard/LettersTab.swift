import SwiftUI
import Charts

struct LettersTab: View {
    let child: ChildProfile
    let settings: ParentSettings
    @Environment(\.managedObjectContext) var context
    @Environment(\.horizontalSizeClass) var sizeClass

    @State private var selectedLetter: String? = nil

    private var activeLetters: [String] { settings.activeLetterArray }
    private var letterRepo: LetterRepository { LetterRepository(context: context) }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: sizeClass == .regular ? 6 : 4)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Letter grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(activeLetters, id: \.self) { letter in
                        LetterGridCard(
                            letter: letter,
                            scores: letterRepo.recentScores(for: letter, child: child),
                            phase: child.phase(for: letter),
                            isSelected: selectedLetter == letter,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedLetter = selectedLetter == letter ? nil : letter
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                // Detail panel for selected letter
                if let letter = selectedLetter {
                    LetterDetailPanel(
                        letter: letter,
                        child: child,
                        letterRepo: letterRepo
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical)
        }
        .background(Color.erBackground)
        .animation(.spring(response: 0.35), value: selectedLetter)
    }
}

// MARK: - Letter grid card

struct LetterGridCard: View {
    let letter: String
    let scores: [Double]
    let phase: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var avgScore: Double {
        scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    private var trend: String {
        guard scores.count >= 2, let newest = scores.first, let oldest = scores.last else { return "→" }
        return newest > oldest ? "↑" : newest < oldest ? "↓" : "→"
    }
    private var trendColor: Color {
        trend == "↑" ? .erGreen : trend == "↓" ? .erRed : .secondary
    }
    private var phaseColor: Color {
        switch phase {
        case 1: return .erBlue
        case 2: return .erGreen
        default: return .erPurple
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Text(letter)
                        .font(Theme.Fonts.childTitle(36))
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)

                    // Phase badge
                    Text("P\(phase)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(phaseColor)
                        .cornerRadius(4)
                }

                // Score bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.15))
                        Capsule()
                            .fill(scoreColor(avgScore))
                            .frame(width: geo.size.width * CGFloat(avgScore))
                    }
                }
                .frame(height: 5)

                HStack {
                    Text("\(Int(avgScore * 100))%")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    Spacer()
                    Text(trend)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : trendColor)
                }
            }
            .padding(10)
            .background(isSelected ? Color.erBlue : Color.erCard)
            .cornerRadius(Theme.Sizing.cardCornerRadius)
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private func scoreColor(_ score: Double) -> Color {
        score >= 0.80 ? .erGreen : score >= 0.60 ? .erBlue : .erOrange
    }
}

// MARK: - Letter detail panel

struct LetterDetailPanel: View {
    let letter: String
    let child: ChildProfile
    let letterRepo: LetterRepository

    private var sessions: [LetterSession] { letterRepo.sessions(for: letter, child: child) }

    private var chartData: [DayScorePoint] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return (0..<7).map { offset -> DayScorePoint in
            let dayStart = calendar.date(byAdding: .day, value: offset, to: cutoff)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let label = dayStart.shortWeekday
            let daySessions = sessions.filter {
                guard let d = $0.sessionDate else { return false }
                return d >= dayStart && d < dayEnd
            }
            let avg: Double? = daySessions.isEmpty ? nil
                : daySessions.map(\.averageScore).reduce(0, +) / Double(daySessions.count)
            return DayScorePoint(label: label, score: avg)
        }
    }

    private var hasData: Bool { chartData.contains { $0.score != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Letter \(letter) — Last 7 Days")
                .font(Theme.Fonts.parentHeadline())

            if hasData {
                Chart(chartData) { point in
                    if let score = point.score {
                        LineMark(x: .value("Day", point.label),
                                 y: .value("Score", score))
                            .foregroundStyle(Color.erBlue)
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Day", point.label),
                                 y: .value("Score", score))
                            .foregroundStyle(Color.erBlue.opacity(0.1))
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Day", point.label),
                                  y: .value("Score", score))
                            .foregroundStyle(Color.erBlue)
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.50, 0.75, 1.0]) { val in
                        AxisValueLabel { Text("\(Int((val.as(Double.self) ?? 0) * 100))%") }
                        AxisGridLine()
                    }
                }
                .frame(height: 140)
            } else {
                Text("No sessions in the last 7 days.")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)
            }

            // Recent sessions list
            ForEach(sessions.prefix(5), id: \.id) { session in
                HStack {
                    Image(systemName: session.passed ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(session.passed ? .erGreen : .erRed)
                    Text(session.sessionDate?.shortDate ?? "")
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(session.averageScore * 100))%")
                        .font(Theme.Fonts.parentBody())
                    if session.passed {
                        Text("+\(session.starMinutesEarned)⭐")
                            .font(.caption)
                            .foregroundColor(.erGreen)
                    }
                }
                Divider()
            }
        }
        .padding()
        .background(Color.erCard)
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .cardShadow()
    }
}

struct DayScorePoint: Identifiable {
    let id = UUID()
    let label: String
    let score: Double?
}
