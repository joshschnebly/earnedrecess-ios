import Foundation

struct ProgressionEngine {

    // MARK: - Phase advancement

    /// Returns true if the child's rolling average qualifies them to advance to the next phase.
    func shouldAdvancePhase(letter: String,
                            recentScores: [Double],
                            threshold: Double) -> Bool {
        guard recentScores.count >= 5 else { return false }
        let window = Array(recentScores.suffix(10))
        let avg = window.reduce(0, +) / Double(window.count)
        return avg >= threshold
    }

    /// Returns the next phase (capped at freehand = 3).
    func nextPhase(current: Int) -> Int {
        min(current + 1, DrawingPhase.freehand.rawValue)
    }

    // MARK: - Star minutes award calculation

    func starMinutesAwarded(averageScore: Double,
                             baseDuration: Int,
                             qualityMultiplierEnabled: Bool) -> Int {
        guard qualityMultiplierEnabled else { return baseDuration }
        let multiplier = qualityMultiplier(for: averageScore)
        return Int(Double(baseDuration) * multiplier)
    }

    private func qualityMultiplier(for score: Double) -> Double {
        switch score {
        case 0.90...: return 1.5
        case 0.75...: return 1.25
        default:      return 1.0
        }
    }
}

// MARK: - Drawing Phase

enum DrawingPhase: Int, CaseIterable {
    case tracing  = 1   // Semi-transparent letter shown — POC uses this only
    case guided   = 2   // Dotted outline only (V2)
    case freehand = 3   // No visual aid (V2)

    var displayName: String {
        switch self {
        case .tracing:  return "Tracing"
        case .guided:   return "Guided"
        case .freehand: return "Freehand"
        }
    }

    var badgeColor: String {
        switch self {
        case .tracing:  return "erBlue"
        case .guided:   return "erGreen"
        case .freehand: return "erPurple"
        }
    }
}
