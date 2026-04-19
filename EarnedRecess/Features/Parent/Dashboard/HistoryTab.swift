import SwiftUI

struct HistoryTab: View {
    let child: ChildProfile
    @Environment(\.managedObjectContext) var context

    @State private var selectedSession: LetterSession? = nil
    @State private var filterStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var filterEndDate: Date = Date()
    @State private var showDateFilter = false

    private var letterRepo: LetterRepository { LetterRepository(context: context) }

    private var allSessions: [LetterSession] {
        letterRepo.allSessions(for: child).filter { session in
            guard let date = session.sessionDate else { return false }
            return date >= filterStartDate && date <= Calendar.current.date(byAdding: .day, value: 1, to: filterEndDate)!
        }
    }

    private var grouped: [(String, [LetterSession])] {
        let grouped = Dictionary(grouping: allSessions) { session -> String in
            session.sessionDate?.mediumDate ?? "Unknown"
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        List {
            // Date filter
            Section {
                DisclosureGroup(
                    isExpanded: $showDateFilter,
                    content: {
                        DatePicker("From", selection: $filterStartDate, displayedComponents: .date)
                        DatePicker("To",   selection: $filterEndDate,   displayedComponents: .date)
                    },
                    label: {
                        Label("Filter: \(filterStartDate.shortDate) – \(filterEndDate.shortDate)",
                              systemImage: "calendar")
                            .font(Theme.Fonts.parentBody())
                    }
                )
            }

            if allSessions.isEmpty {
                Section {
                    Text("No sessions in this date range.")
                        .foregroundColor(.secondary)
                }
            }

            // Grouped by date
            ForEach(grouped, id: \.0) { date, sessions in
                Section(date) {
                    ForEach(sessions, id: \.id) { session in
                        SessionRow(session: session)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedSession = session }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $selectedSession) { session in
            SessionDetailSheet(session: session)
        }
    }
}

// MARK: - Session row

struct SessionRow: View {
    let session: LetterSession

    var body: some View {
        HStack(spacing: 12) {
            // Letter badge
            Text(session.letter ?? "?")
                .font(Theme.Fonts.childBody(22))
                .frame(width: 44, height: 44)
                .background(session.passed ? Color.erGreen.opacity(0.15) : Color.erRed.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(session.passed ? "Passed" : "Not passed")
                        .font(Theme.Fonts.parentBody())
                    Spacer()
                    Text(session.sessionDate?.timeString ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Text("Avg: \(Int(session.averageScore * 100))%")
                    Text("·")
                    Text("\(session.attemptsCompleted)/\(session.attemptsRequired) attempts")
                    if session.passed && session.starMinutesEarned > 0 {
                        Text("·")
                        Text("+\(session.starMinutesEarned)⭐")
                            .foregroundColor(.erGreen)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Session detail sheet

struct SessionDetailSheet: View {
    let session: LetterSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Letter", value: session.letter ?? "?")
                    LabeledContent("Date", value: session.sessionDate?.mediumDate ?? "")
                    LabeledContent("Result", value: session.passed ? "Passed ✓" : "Not Passed")
                    LabeledContent("Average Score", value: "\(Int(session.averageScore * 100))%")
                    LabeledContent("Attempts", value: "\(session.attemptsCompleted)/\(session.attemptsRequired)")
                    if session.passed {
                        LabeledContent("Stars Earned", value: "+\(session.starMinutesEarned) ⭐")
                    }
                    LabeledContent("Duration", value: String(format: "%.0fs", session.duration))
                }

                Section("Attempts") {
                    ForEach(session.attemptsArray, id: \.id) { attempt in
                        HStack {
                            Text("#\(attempt.attemptNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 24)

                            Image(systemName: attempt.passed ? "star.fill" : "star")
                                .foregroundColor(.erYellow)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(Int(attempt.compositeScore * 100))% overall")
                                    .font(Theme.Fonts.parentBody())
                                Text("Acc: \(Int(attempt.overlapScore*100))% · Shape: \(Int(attempt.proportionScore*100))% · Smooth: \(Int(attempt.smoothnessScore*100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                            starRatingView(attempt.starRating)
                        }
                    }
                }
            }
            .navigationTitle("Session Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func starRatingView(_ rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundColor(.erYellow)
            }
        }
    }
}
